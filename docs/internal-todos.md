# Internal TODOs (Maintainer Notes)

These notes are intentionally kept out of the main `README.md` so the public project overview stays concise.

## Critical reminders

- Don't update maps mid-lobby flow. In the future, consider setting the map and creating the game during lobby creation. Updating a map currently works, but can change unexpectedly for players between fleet selection and game start.
- Don't forget to set `shipNames` appropriately in `ignition/modules/DeployAndConfig.ts` before deployment.

## TODO

- CRITICAL: Add support for free ships for doing quests.
- CRITICAL: Evaluate whether it is acceptable that `firstPlayer` goes first every round, even if they moved last in the previous round.
- Consider charging UTC to start or join a game.
- Skipping a player's turn when they have no ships left to move should make it their turn (not the first player's turn) for the new round.
- Add wagers in UTC only.
- CRITICAL: Update maps creation to support horizontal or vertical deployment.
- Consider allowing additional custom deployments (for example diagonals).
- CRITICAL: Reserved lobbies.
- CRITICAL: Put rank in JSON metadata and on image.
- CRITICAL: Find a way to show hull trait.
- Allow third-party map creation for 50+ FLOW and allow payments to map creators (probably as voluntary tips). Do not generate UTC here; exploitable.
- Pay UTC to game winner if this can be done without enabling exploits.
- Map creator should get 1/4 of recycle fee for ships destroyed on their maps.
- Potential issue: map owner plus owner of two fleets could allow free training.
- Enforce minimum fleet size (not enforced now for testing).
- Decide if players should be able to cancel fleet before other player submits.
- Creator should probably be allowed to set their fleet without a joiner.

## Done

- Add buying UTC at the same price as recycling a ship to avoid buy + recycle loop.
- CRITICAL: Add guaranteed high-tier ships to higher tiers.
- Players should be able to pay to join a lobby if they are already in one.
- CRITICAL: Don't allow lobbies to be created for map IDs that don't exist.
- CRITICAL: Ensure there is a path to upgrade ships and add new collections.
- CRITICAL: Ensure ship collections can be expanded and new weapon specials can be added.
- CRITICAL: Ensure ship migration is possible.
- CRITICAL: Need ability to adjust bonus and leveling tier values.
- Not done but possible via replacing `Attributes` contract: CRITICAL add controls to change ship rank tiers.
- Costs should probably be in attributes arrays instead of separate structures.
- CRITICAL: Store last move in contract.
- Limit fleet max cost.

## Todo Later

### Via updated renderer

- Add battle scarring to ships each time they are disabled.
- Add a way to clean or repair ships.

## Not Doing

- Unsure there is value in fetching ship metadata without image.
- Not doing reroll colors or name (too easy to exploit, commit-reveal complexity).
- CRITICAL: Add reroll shiny colors.
- CRITICAL: Add guaranteed shiny ships to higher tiers.
