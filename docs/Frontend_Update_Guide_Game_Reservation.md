# Frontend Update Guide - Game Reservation Feature

## Overview

This document outlines the new game reservation feature added to the Lobbies contract since the last frontend update guide (December 7, 2025).

**Last Document:** December 7, 2025 (Commit: 49ddb8f - "Add guaranteed high rank ships for tiers")
**Current State:** Latest (Game Reservation Feature)

---

## New Feature: Game Reservation

Players can now reserve games for specific other players by paying 1 UTC token. This allows players to invite friends to play without the lobby being open to anyone.

### Key Changes

#### 1. New Struct Field

**`LobbyPlayers` struct in Types.sol:**

```solidity
struct LobbyPlayers {
    address joiner;
    address reservedJoiner; // NEW: Address of player this lobby is reserved for (if any)
    uint creatorFleetId;
    uint joinerFleetId;
    uint joinedAt;
    uint joinerFleetSetAt;
}
```

**Frontend Impact:**

- When reading lobby data, check `lobby.players.reservedJoiner`
- If `reservedJoiner != address(0)`, the lobby is reserved for that player
- If `reservedJoiner == address(0)`, the lobby is open to anyone

---

#### 2. Modified Function: `createLobby`

**Previous Signature:**

```solidity
function createLobby(
    uint _costLimit,
    uint _turnTime,
    bool _creatorGoesFirst,
    uint _selectedMapId,
    uint _maxScore
) public payable
```

**New Signature:**

```solidity
function createLobby(
    uint _costLimit,
    uint _turnTime,
    bool _creatorGoesFirst,
    uint _selectedMapId,
    uint _maxScore,
    address _reservedJoiner  // NEW: Address to reserve for (use address(0) for open lobby)
) public payable
```

**Changes:**

- Added `_reservedJoiner` parameter (address)
  - Use `address(0)` or `zeroAddress` for open lobbies (no reservation)
  - Use a specific address to reserve for that player
- **Payment Behavior:**
  - If `_reservedJoiner != address(0)`: Requires 1 UTC token (via `transferFrom`)
  - If `_reservedJoiner == address(0)`: Uses existing FLOW payment logic (for additional lobbies)

**Frontend Implementation:**

```typescript
// Open lobby (no reservation)
await lobbies.write.createLobby([
  costLimit,
  turnTime,
  creatorGoesFirst,
  selectedMapId,
  maxScore,
  zeroAddress, // No reservation
]);

// Reserved lobby
// First, approve UTC transfer
await universalCredits.write.approve([
  lobbies.address,
  parseEther("1"), // 1 UTC
]);

// Then create reserved lobby
await lobbies.write.createLobby([
  costLimit,
  turnTime,
  creatorGoesFirst,
  selectedMapId,
  maxScore,
  friendAddress, // Reserve for friend
]);
```

---

#### 3. Modified Function: `joinLobby`

**Behavior Changes:**

- Now checks if lobby is reserved before allowing join
- If `lobby.players.reservedJoiner != address(0)`:
  - Only the reserved player can join
  - Other players will receive `NotReservedJoiner` error
- Reserved lobbies skip FLOW fee requirement (UTC already paid by creator)

**Frontend Impact:**

- Check `lobby.players.reservedJoiner` before calling `joinLobby`
- If reserved for someone else, show appropriate UI message
- If reserved for current user, show "Accept Game" button instead of "Join Lobby"

---

#### 4. New Function: `acceptGame`

**Signature:**

```solidity
function acceptGame(uint _lobbyId) public nonReentrant
```

**Purpose:**

- Allows the reserved player to accept a game invitation
- Equivalent to joining, but specifically for reserved games
- Clears the `reservedJoiner` field after acceptance

**Frontend Implementation:**

```typescript
// For reserved player to accept
await lobbies.write.acceptGame([lobbyId]);
```

**Events Emitted:**

- `GameAccepted(uint indexed lobbyId, address indexed joiner)`
- `PlayerJoinedLobby(uint indexed lobbyId, address indexed joiner)`

---

#### 5. New Function: `rejectGame`

**Signature:**

```solidity
function rejectGame(uint _lobbyId) public nonReentrant
```

**Purpose:**

- Allows the reserved player to reject a game invitation
- Clears the `reservedJoiner` field, making the lobby open to anyone
- Does not join the lobby

**Frontend Implementation:**

```typescript
// For reserved player to reject
await lobbies.write.rejectGame([lobbyId]);
```

**Events Emitted:**

- `GameRejected(uint indexed lobbyId, address indexed joiner)`

---

#### 6. New Events

```solidity
event GameReserved(uint indexed lobbyId, address indexed reservedJoiner);
event GameAccepted(uint indexed lobbyId, address indexed joiner);
event GameRejected(uint indexed lobbyId, address indexed joiner);
```

**Frontend Impact:**

- Listen for `GameReserved` to notify the reserved player
- Listen for `GameAccepted` to update UI when reserved player accepts
- Listen for `GameRejected` to update UI when reserved player rejects

---

#### 7. New Errors

```solidity
error NotReservedJoiner();        // When non-reserved player tries to join reserved lobby
error LobbyNotReserved();         // When accept/reject called on non-reserved lobby
error InsufficientUTC();          // When creator doesn't have enough UTC for reservation
error UTCTransferFailed();        // When UTC transfer fails
```

**Frontend Error Handling:**

- `NotReservedJoiner`: Show "This game is reserved for another player"
- `LobbyNotReserved`: Should not occur in normal flow
- `InsufficientUTC`: Show "Insufficient UTC balance. Need 1 UTC to reserve game"
- `UTCTransferFailed`: Show "UTC transfer failed. Please try again"

---

#### 8. New Owner Function: `setUniversalCreditsAddress`

**Signature:**

```solidity
function setUniversalCreditsAddress(address _universalCredits) public onlyOwner
```

**Purpose:**

- Sets the UniversalCredits contract address for UTC token transfers
- Called during deployment

**Frontend Impact:**

- No direct frontend impact (owner-only function)

---

## Frontend Implementation Checklist

### UI/UX Changes

- [ ] **Lobby Creation Form:**

  - Add optional "Reserve for Player" field
  - Show UTC balance and requirement (1 UTC)
  - Add UTC approval step before creating reserved lobby
  - Show different payment options (FLOW for open, UTC for reserved)

- [ ] **Lobby List/Display:**

  - Show reservation status badge/indicator
  - Display reserved player address if reserved
  - Hide "Join" button if reserved for someone else
  - Show "Accept" / "Reject" buttons if reserved for current user

- [ ] **Reserved Player Notifications:**

  - Listen for `GameReserved` events
  - Show notification when game is reserved for user
  - Provide quick accept/reject actions

- [ ] **Error Handling:**
  - Handle `NotReservedJoiner` error gracefully
  - Show clear message when trying to join reserved lobby
  - Handle UTC balance/approval errors

### Code Changes

- [ ] **Update `createLobby` calls:**

  ```typescript
  // Add 6th parameter (reservedJoiner)
  await lobbies.write.createLobby([
    costLimit,
    turnTime,
    creatorGoesFirst,
    selectedMapId,
    maxScore,
    reservedJoiner || zeroAddress, // NEW
  ]);
  ```

- [ ] **Add UTC approval before reserved lobby creation:**

  ```typescript
  if (reservedJoiner) {
    // Check balance
    const balance = await universalCredits.read.balanceOf([userAddress]);
    if (balance < parseEther("1")) {
      // Show error or redirect to purchase UTC
    }

    // Approve transfer
    await universalCredits.write.approve([lobbies.address, parseEther("1")]);
  }
  ```

- [ ] **Update lobby reading logic:**

  ```typescript
  const lobby = await lobbies.read.getLobby([lobbyId]);
  const isReserved = lobby.players.reservedJoiner !== zeroAddress;
  const isReservedForMe =
    lobby.players.reservedJoiner.toLowerCase() === userAddress.toLowerCase();
  ```

- [ ] **Add accept/reject handlers:**

  ```typescript
  // Accept reserved game
  const acceptGame = async (lobbyId: bigint) => {
    await lobbies.write.acceptGame([lobbyId]);
  };

  // Reject reserved game
  const rejectGame = async (lobbyId: bigint) => {
    await lobbies.write.rejectGame([lobbyId]);
  };
  ```

- [ ] **Update event listeners:**

  ```typescript
  // Listen for reservation events
  lobbies.on("GameReserved", (lobbyId, reservedJoiner) => {
    if (reservedJoiner.toLowerCase() === userAddress.toLowerCase()) {
      // Show notification to user
    }
  });

  lobbies.on("GameAccepted", (lobbyId, joiner) => {
    // Update lobby UI
  });

  lobbies.on("GameRejected", (lobbyId, joiner) => {
    // Update lobby UI (lobby is now open)
  });
  ```

---

## Example User Flows

### Flow 1: Create Reserved Lobby

1. User selects "Create Game"
2. User fills in game settings
3. User enters friend's address in "Reserve for Player" field
4. Frontend checks UTC balance (needs 1 UTC)
5. If insufficient, show "Purchase UTC" option
6. Frontend requests UTC approval (1 UTC)
7. User approves UTC transfer
8. Frontend calls `createLobby` with friend's address
9. `GameReserved` event emitted
10. Friend receives notification

### Flow 2: Accept Reserved Game

1. Reserved player sees notification: "Game reserved for you"
2. Player views lobby details
3. Player clicks "Accept Game"
4. Frontend calls `acceptGame(lobbyId)`
5. `GameAccepted` and `PlayerJoinedLobby` events emitted
6. Lobby moves to FleetSelection status
7. Both players can now create fleets

### Flow 3: Reject Reserved Game

1. Reserved player sees notification: "Game reserved for you"
2. Player views lobby details
3. Player clicks "Reject Game"
4. Frontend calls `rejectGame(lobbyId)`
5. `GameRejected` event emitted
6. Lobby becomes open (anyone can join)
7. Reserved player can still join later if they want

### Flow 4: Join Reserved Lobby (Non-Reserved Player)

1. Player sees lobby in list
2. Lobby shows "Reserved" badge
3. Player tries to join
4. Frontend calls `joinLobby(lobbyId)`
5. Contract reverts with `NotReservedJoiner` error
6. Frontend shows: "This game is reserved for another player"

---

## Testing Checklist

- [ ] Create open lobby (reservedJoiner = address(0))
- [ ] Create reserved lobby with sufficient UTC
- [ ] Create reserved lobby with insufficient UTC (should fail)
- [ ] Reserved player can accept game
- [ ] Reserved player can reject game
- [ ] Non-reserved player cannot join reserved lobby
- [ ] After rejection, anyone can join
- [ ] After acceptance, lobby moves to FleetSelection
- [ ] Events are emitted correctly
- [ ] UTC is transferred correctly on reservation
- [ ] FLOW payment still works for open lobbies

---

## Migration Notes

### Breaking Changes

1. **`createLobby` signature change:**

   - All existing `createLobby` calls must be updated to include 6th parameter
   - Use `zeroAddress` for existing open lobby functionality

2. **`LobbyPlayers` struct change:**
   - Frontend code reading `lobby.players` must account for new `reservedJoiner` field
   - TypeScript types must be updated

### Non-Breaking Additions

- `acceptGame` and `rejectGame` are new functions (no existing code affected)
- New events are additive (existing event listeners unaffected)
- New errors are specific to reservation feature

---

## Contract Address Updates

**Note:** The Lobbies contract will need to be redeployed with the new code. The `universalCredits` address must be set via `setUniversalCreditsAddress()` during deployment.

---

## Summary

The game reservation feature adds the ability for players to invite specific friends to games by paying 1 UTC. This is a **breaking change** for `createLobby` (new parameter required) but adds valuable social features to the game.

**Key Takeaways:**

- Always pass 6th parameter to `createLobby` (use `zeroAddress` for open lobbies)
- Check `reservedJoiner` field when displaying/joining lobbies
- Implement UTC approval flow for reserved lobby creation
- Add accept/reject UI for reserved players
- Listen for new reservation events
