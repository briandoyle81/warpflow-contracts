# Warpflow

I own this game, repo, contents, code, etc. and reserve all rights. I'm sharing it so that others can learn from my methods.

You may not copy my contracts and use them in your own projects. All rights reserved.

Please see other repos for composable and forkable contracts, apps, etc.!

Thanks!

npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts --network flow-testnet --verify

DON'T FORGET TO SET SHIPNAMES APPROPRIATELY!

TODO:

Add battle scaring to ships each time they get disabled
CRITICAL: Don't allow lobbies to be created for map ids that don't exist
CRITICAL: Handle fleets that have more than 10 ships running out of space for deployment
CRITICAL: Put rank in json metadata and on image
CRITICAL: Find a way to show hull trait
Allow third party map creation for 50+ flow and allow payments to map creators (probably as voluntary tips). DONT GENERATE UTC HERE - EXPLOITABLE
Pay UTC to winner of games
Add property of unsellable to NFTs as a trait and add that to image.
Ships that are destroyed should be recycled for 1/2 or 1/4 utc
Winner of a game should get 1/2 or 1/4 UTC of recycle amount for enemy ships destroyed in game
Limit fleet max cost
Enforce minimum fleet size
Decide if players should be able to cancel fleet before other submits
The creator should probably be allowed to set their fleet without a joiner
