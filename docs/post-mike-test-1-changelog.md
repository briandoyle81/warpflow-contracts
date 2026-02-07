# post-mike-test-1 — Changelog & Frontend Notifications

**Phase:** post-mike-test-1
**Purpose:** Track contract/backend changes and what the frontend must do or know.

---

## Summary for frontend

| Change | Frontend impact |
|--------|-----------------|
| End-of-round-only scoring | Scores change only when a round completes, not on every move to a scoring tile. |
| Alternating starting player each round | Turn indicator / hints must respect that the first mover alternates by round. |
| Timeout = forfeit (no skip turn) | Use `endGameOnTimeout`; remove any use of force-move/skip-turn on timeout. |
| Retreat/flee as action in `moveShip` | Use `moveShip(..., ActionType.Retreat, 0)` to flee a ship; any ship can flee (even already moved or 0 HP). No separate `fleeShip`; Assist action removed. |
| Warp overload: instant destruction at 3 | Ships are destroyed as soon as reactor critical timer reaches 3 (shoot on 0 HP, EMP, or start-of-round 0 HP tick), not at end of round. |

*(Rows will be added as we implement. See sections below for details.)*

---

## Contract / backend changes

*(List each change with file, what changed, and why.)*

| Date | Area | Change | Status |
|------|------|--------|--------|
| — | Game | Timeout behavior: added `endGameOnTimeout`, removed force-move/skip-turn (e.g. `forceMoveOnTimeout`, auto-pass helpers). Timed-out player can be forced to forfeit by the other player. | Done |
| — | Game | Retreat/flee: use `moveShip(gameId, shipId, row, col, ActionType.Retreat, 0)`; skip “already moved” and “0 HP” checks for Retreat. Removed `fleeShip` and Assist action. | Done |
| — | Game | Warp overload (reactor critical): ships destroyed **instantly** when timer reaches 3 (on shoot vs 0 HP, EMP, or start-of-round 0 HP increment). Removed end-of-round batch `_destroyShipsWithCriticalReactor`. | Done |

---

## Frontend notifications (action required)

*(Items the frontend team must implement or adjust.)*

### Scoring: end-of-round only

- **Behavior change:** Score updates no longer happen when a ship lands on a scoring tile. Scores are updated **only when a round completes** (i.e. when all ships have moved for the round).
- **Frontend:**
  - Do **not** assume score changes on every move to a scoring tile. Refresh or derive scores from game state after the move that **completes the round** (or on next `GameUpdate` / poll).
  - If you show “pending” or “will score” for ships on scoring tiles, that’s still valid; the actual score delta will appear at round end.
- **API / view:** `creatorScore` and `joinerScore` still mean the same; only the **moment** they change moves to round completion.
- **Status:** In progress

### Turn order: alternate starting player each round

- **Behavior change:** The player who goes first **alternates** each round:
  - If `creatorGoesFirst` is true, creator starts odd-numbered rounds, joiner starts even-numbered rounds.
  - If `creatorGoesFirst` is false, joiner starts odd-numbered rounds, creator starts even-numbered rounds.
- **Frontend:**
  - Any UI that predicts or displays “who moves first this round” should use the round number and `creatorGoesFirst` (or rely on `currentTurn` after a round rolls over) instead of assuming a fixed first player.
  - Turn indicators / prompts should not assume creator always starts.
- **API / view:** `turnState.currentRound` and `turnState.currentTurn` already exist; the contract now derives the next round’s starting player from these plus `creatorGoesFirst`.
- **Status:** In progress

### Timeout: forfeit instead of skip turn

- **Behavior change:** When a player's turn has timed out, the **other** player can call **`endGameOnTimeout(uint _gameId)`** to end the game immediately. The timed-out player **forfeits** (loses); the caller wins. There is no longer any "force move" or "skip turn" — the only timeout action is to end the game.
- **New function:** `endGameOnTimeout(uint _gameId)` — callable by the non–current-turn player when `turnStartTime + turnTime` has passed; ends the game with caller as winner, current turn (timed-out) as loser.
- **Removed:** Previous timeout flow that skipped the turn (e.g. `forceMoveOnTimeout` and any auto-pass / skip-turn logic or debug helpers). Those entrypoints and internal helpers are no longer present.
- **Frontend:**
  - Replace any "Force move" / "Skip turn" timeout button with "Claim win (timeout)" or equivalent that calls `endGameOnTimeout(_gameId)`.
  - Do not assume the game continues after a timeout; the game ends and the timed-out player loses.
- **Status:** In progress

### Retreat/flee as action (no separate fleeShip; Assist removed)

- **Behavior change:** Fleeing is done via **`moveShip(gameId, shipId, newRow, newCol, ActionType.Retreat, 0)`**. Any of the current player’s ships can flee (even if that ship has already moved this round or has 0 HP). The ship is removed from the game and the turn passes to the other player. There is **no** separate `fleeShip` function. The **Assist** action (help a 0 HP ship retreat) has been removed.
- **Frontend:**
  - Use `moveShip(..., ActionType.Retreat, 0)` to flee; `newRow`/`newCol` are ignored (can pass current position or any value). Do not call or show UI for `fleeShip`. Remove or repurpose any Assist action UI.
  - For Retreat, `lastMove.newRow`/`newCol` (and event) are `-1` to mean “fled”.
- **Status:** In progress

### Warp overload (reactor critical): instant destruction at 3

- **Behavior change:** Ships are **destroyed as soon as** their warp overload (reactor critical timer) **reaches 3**, instead of at end of round. This can happen when: (1) a 0 HP ship is shot (timer +1), (2) a ship is hit by EMP (timer + strength), or (3) at start of a new round, each 0 HP ship’s timer +1. There is no longer an end-of-round “destroy all with timer ≥ 3” step.
- **Frontend:**
  - Assume ships can disappear **during** a move or at round start (when 0 HP timer ticks), not only at “end of round.” Update any UI that assumed destruction only at round end.
- **Status:** In progress

---

## Planned (not yet implemented)

- End-of-round scoring per [plan-end-of-round-scoring.md](./plan-end-of-round-scoring.md):
  - Maps: add `getScoringPositionsForGame(_gameId)` (or `getScoringPositionsAndAmount`).
  - Game: remove per-move scoring; run scoring in `_handleEndOfRound()` from snapshot of ships on scoring tiles.

---

## Notes

- Add new contract changes under **Contract / backend changes** and any required frontend action under **Frontend notifications**.
- When a change is done, set **Status** to Done and ensure the **Summary for frontend** table is updated.
