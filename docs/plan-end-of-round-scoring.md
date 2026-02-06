# Plan: End-of-Round Scoring

## Current behavior

- **When**: Scoring runs inside `_performAction()` → `_checkAndCollectPoints()` every time a ship ends a move on a scoring tile.
- **Flow**: Move → place ship → `_performAction()` → **immediate** `maps.getScoreAndZeroOut()` → update `creatorScore`/`joinerScore` → possibly `_endGame()`.
- **Round**: A round completes when all (active, non–0-HP) ships have moved; then `_handleEndOfRound()` runs (reactor critical, clear `shipMovedThisRound`, next round, etc.). Scoring is **not** part of end-of-round today.

## Goal

- **When**: Scoring runs **only** when a round completes (in `_handleEndOfRound()`).
- **Who gets points**: The owner of each **non-disabled / non-destroyed** ship that is **on** a scoring position at round end (snapshot semantics). Points are awarded only for tiles that still have an active ship at end of round.

---

## Design: Snapshot at end of round (efficient)

Use a **snapshot** at end of round instead of recording claims per move:

1. **Maps**: Add a view `getScoringPositionsForGame(_gameId)` (or `getScoringPositionsAndAmount`) that returns all scoring positions and their point values for the game — e.g. `ScoringPosition[]` (row, col, points, onlyOnce). Maps already has this logic inside `getGameMapState()`; we add a dedicated function that returns only scoring data (no blocked tiles) for clarity and slightly better gas when Game only needs scoring.
2. **Game – end of round**: In `_handleEndOfRound()`, call that function to get scoring positions. For each (row, col): look up `game.grid[row][col]`. If there is a ship (shipId != 0), check that the ship is not destroyed (and not disabled, if applicable). If the ship is active, get its owner, call `maps.getScoreAndZeroOut(_gameId, row, col)`, add the returned points to that player's score, then check for max score and `_endGame()` if needed.
3. **Game – move**: Remove the call to `_checkAndCollectPoints()` from `_performAction()`. No per-move scoring and **no new storage** in Game (no `scoringClaimsThisRound` array).

**Why this is more efficient**

- No SSTORE on every move that lands on a scoring tile.
- No dynamic array in `GameData` for claims.
- One view call at end of round (bounded by number of scoring tiles, usually small), then one `getScoreAndZeroOut` per scoring tile that has an active ship.

**Semantics tradeoff**

- **Snapshot (this plan):** Only ships that are **still on** a scoring tile at round end get the points. If a ship lands on scoring then retreats or is destroyed later in the same round, it gets **no** points.
- **Alternative (record claims):** Whoever ended a move on a scoring tile during the round gets the points, even if they later retreated. That would require per-move claim storage (see appendix below).

Only-once tiles are unchanged: we call `getScoreAndZeroOut` only for positions that have a ship, so we still zero out when claimed. Tiles with no ship at round end are not called and stay as-is.

---

## Implementation steps

### 1. Maps: add `getScoringPositionsForGame` (or `getScoringPositionsAndAmount`)

- Add a **view** function that takes `_gameId` and returns `ScoringPosition[] memory` for that game (row, col, points, onlyOnce). Reuse the same scan logic as in `getGameMapState()` but only fill and return the scoring array (no blocked positions). This keeps a single source of truth for "what tiles are scoring" and avoids Game doing its own grid scan.
- Add the function to **IMaps** so Game can call it via the interface.

(Alternatively, Game could call existing `getGameMapState(_gameId)` and use only the second return value `scoringPositions`; that works but does one extra loop and allocation for blocked tiles. A dedicated scoring-only function is slightly more gas-efficient and clearer.)

### 2. Game: remove per-move scoring

- In `_performAction()`, **remove** the call to `_checkAndCollectPoints(_gameId, ship.owner, _newRow, _newCol)` entirely. No replacement — no recording of claims.

### 3. Game: score at end of round from snapshot

- In `_handleEndOfRound()`, **before** existing logic (reactor critical, clear moved set, etc.):
  1. Call `maps.getScoringPositionsForGame(_gameId)` (or the chosen name) to get `ScoringPosition[]` for the game.
  2. For each position in the array:
     - `shipId = game.grid[position.row][position.col]`.
     - If `shipId == 0`, skip (no ship on tile).
     - If ship is destroyed (or disabled, if you have that concept), skip.
     - Otherwise: `points = maps.getScoreAndZeroOut(_gameId, position.row, position.col)`. Add `points` to `game.creatorScore` or `game.joinerScore` according to the ship's owner. If either score >= `game.maxScore`, determine winner/loser and call `_endGame(_gameId, winner, loser)` (and optionally break; you still only call `getScoreAndZeroOut` for tiles that have a ship, so only-once state stays correct).
  3. Then run the **existing** end-of-round steps: destroy ships with reactor critical >= 3, increment round, clear `shipMovedThisRound`, increment reactor critical for 0-HP ships, reset turn to first player.

Order: Do scoring **before** destroying ships and clearing the moved set, so "who is on the tile" is the state at the moment the round ended.

### 4. Types

- **No new structs or fields** in `GameData`. Existing `ScoringPosition` in Types is sufficient for the Maps return value.

### 5. Auto-pass / timeout

- `_autoPassTurn()` already calls `_handleEndOfRound()` when the round completes. No change; scoring will run when the round ends after auto-pass.

### 6. Tests

- **Game tests**
  - Scoring happens only at round end: ship moves onto scoring tile → scores unchanged until round completes; when round completes, owner of ship on that tile gets the points.
  - If a ship lands on scoring then retreats in the same round → it gets **no** points (snapshot semantics).
  - Only-once tiles: after scoring, tile is zeroed; second round no points from that tile.
  - Max score win triggered by end-of-round scoring.
  - Timeout/auto-pass that completes the round still runs end-of-round scoring.
- **Maps tests**
  - Add or extend tests for `getScoringPositionsForGame` (returns correct positions and amounts for a game). Other Maps behavior unchanged.

### 7. Frontend / clients

- Scores update only when a round completes. UI should refresh scores on the move that completes the round (or on next fetch after `GameUpdate`).

---

## Summary

| Area              | Action |
|-------------------|--------|
| **Maps**          | Add view `getScoringPositionsForGame(_gameId)` returning `ScoringPosition[]`; add to IMaps. |
| **Game – move**   | Remove `_checkAndCollectPoints` from `_performAction()`. No new storage. |
| **Game – round**  | In `_handleEndOfRound`, get scoring positions from Maps, for each position with an active ship call `getScoreAndZeroOut`, award to ship owner, check win. |
| **Types**         | No change (use existing `ScoringPosition`). |
| **Tests**         | Add/update for end-of-round scoring and snapshot semantics. |
| **Clients**       | Treat score updates as occurring at round end. |

This yields **end-of-round-only** scoring with **snapshot semantics** (only ships on scoring tiles at round end get points) and is **more gas-efficient** than recording claims per move.

---

## Appendix: Alternative (record claims per move)

If you instead want semantics where "whoever ended a move on a scoring tile gets the points even if they later retreated," you would:

- Add `ScoringClaim` (player, row, col) and `scoringClaimsThisRound` array to `GameData`.
- In `_performAction()`, when a ship lands on a scoring tile, push a claim instead of calling `_checkAndCollectPoints`.
- In `_handleEndOfRound()`, process each claim with `getScoreAndZeroOut`, add to player, then clear the array.

That preserves current "who scored" semantics but costs extra storage and SSTOREs per scoring move.
