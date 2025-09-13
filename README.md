# Warpflow

I own this game, repo, contents, code, etc. and reserve all rights. I'm sharing it so that others can learn from my methods.

You may not copy my contracts and use them in your own projects.

Please see other repos for composable and forkable contracts, apps, etc.!

Thanks!

npx hardhat ignition deploy ignition/modules/DeployAndConfig.ts --network flow-testnet --verify

TODO:

CRITICAL BUG: Ships become orphaned if a lobby creator leaves the lobby after selecting their fleet
CRITICAL: Creating preset maps need to create scoring and blocking at the same time
Allow third party map creation for 50+ flow and allow payments to map creators (probably as voluntary tips). DONT GENERATE UTC HERE - EXPLOITABLE
Pay UTC to winner of games
Add property of unsellable to NFTs as a trait and add that to image.
Ships that are destroyed should be recycled for 1/2 or 1/4 utc
Winner of a game should get 1/2 or 1/4 UTC of recycle amount for enemy ships destroyed in game
Limit fleet max cost
Enforce minimum fleet size
Decide if players should be able to cancel fleet before other submits
