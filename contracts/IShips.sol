// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Types.sol";

interface IShips {
    function createShips(address _to, uint _amount) external;

    function getCurrentCostsVersion() external view returns (uint16);

    function getShip(uint _id) external view returns (Ship memory);

    function isShipDestroyed(uint _id) external view returns (bool);

    function setTimestampDestroyed(uint _id) external;

    function setInFleet(uint _id, bool _inFleet) external;
}
