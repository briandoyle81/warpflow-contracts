// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";

interface ITutorialShips {
    function createSpecificShip(address _to, Ship calldata _ship) external returns (uint);
}
