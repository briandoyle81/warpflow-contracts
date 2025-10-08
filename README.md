# Warpflow

I own this game, repo, contents, code, etc. and reserve all rights. I'm sharing it so that others can learn from my methods.

You may not copy my contracts and use them in your own projects. All rights reserved.

Please see other repos for composable and forkable contracts, apps, etc.!

Thanks!

## ⚠️ Testnet Alpha Warning

**In active development, ships and games will be lost**

npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts --network flow-testnet --verify

DON'T FORGET TO SET SHIPNAMES APPROPRIATELY!

TODO:

CRITICAL: Make sure I can expand ship collections
CRITICAL: Make sure I can migrate ships
CRITICAL: Reserved lobbies
Costs should probably be in the attributes arrays instead of separate
Add battle scarring to ships each time they get disabled
And a way to "clean" or repair them
CRITICAL: Don't allow lobbies to be created for map ids that don't exist
CRITICAL: Put rank in json metadata and on image
CRITICAL: Find a way to show hull trait
CRITICAL: Deployment zones and position selection
Allow third party map creation for 50+ flow and allow payments to map creators (probably as voluntary tips). DON'T GENERATE UTC HERE - EXPLOITABLE
Pay UTC to winner of games if I can game exploitsyou
Map creator should get 1/4 the recycle fee for ships destroyed on their maps.
Potential issue: Map owner plus owner of two fleets allows training for free.
Limit fleet max cost
Enforce minimum fleet size
Decide if players should be able to cancel fleet before other submits
The creator should probably be allowed to set their fleet without a joiner
