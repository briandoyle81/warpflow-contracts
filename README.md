# Warpflow

I own this game, repo, contents, code, etc. and reserve all rights. I'm sharing it so that others can learn from my methods.

You may not copy my contracts and use them in your own projects. All rights reserved.

Please see other repos for composable and forkable contracts, apps, etc.!

Thanks!

## ⚠️ Testnet Alpha Warning

**In active development, ships and games will be lost**

npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts --network flow-testnet --verify

DON'T FORGET TO SET SHIPNAMES APPROPRIATELY!

Things to remember:
CRITICAL: Don't update maps. In the future, consider setting the map and creating the game with lobby creation. If you update a map, it will work, but will change unexpectedly for anyone between selecting a fleet and the game starting.

TODO:

CRITICAL: Add guaranteed high tier and shiny ships to higher tiers

CRITICAL: Evaluate if I care that the firstPlayer goes first every round, even if they moved last in the previous round
Consider charging UTC to start or join a game

Skipping a player's turn when you have no ships left to move should make it your turn and not the first player's turn for the new round

Add buying UTC at the same price as recycling a ship to avoid people having to buy and recycle ships for it.
Add wagers in UTC only.
CRITICAL: Update maps creation to set horizontal or vertical deployment
Consider allowing more custom deployments like diagonals, etc.
CRITICAL: Reserved lobbies

CRITICAL: Put rank in json metadata and on image
CRITICAL: Find a way to show hull trait

Allow third party map creation for 50+ flow and allow payments to map creators (probably as voluntary tips). DON'T GENERATE UTC HERE - EXPLOITABLE
Pay UTC to winner of games if I can avoid game exploits
Map creator should get 1/4 the recycle fee for ships destroyed on their maps.
Potential issue: Map owner plus owner of two fleets allows training for free.

Enforce minimum fleet size. WE DON'T DO THIS NOW FOR TESTING
Decide if players should be able to cancel fleet before other submits
The creator should probably be allowed to set their fleet without a joiner

Done:

Players should be able to pay to join a lobby if they are in one already
CRITICAL: Don't allow lobbies to be created for map ids that don't exist
CRITICAL: Make sure I have a path to upgrade ships and add new collections
CRITICAL: Make sure I can expand ship collections, add new weapons specials etc.
CRITICAL: Make sure I can migrate ships
CRITICAL: I have to be able to adjust bonus and tiers for leveling up. Right now a tier 3 plasma does 96 damage!!! Though that's only +16, but still
Not done but can accomplish by replacing the Attributes contract. CRITICAL: Add controls to change ship rank tiers
Costs should probably be in the attributes arrays instead of separate
CRITICAL: Store last move in contract
Limit fleet max cost

Todo Later:

Via Updated Renderer:
Add battle scarring to ships each time they get disabled
And a way to "clean" or repair them

Not Doing:
Is there any value in getting a ship's metadata without the image? I could use a local renderer but I'm not sure what i gain.
Not doing reroll colors or name. Too easy to exploit and too hard to do another commit reveal
CRITICAL: Add reroll shiny colors
