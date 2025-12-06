// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Types.sol";

interface IShips {
    function createShips(address _to, uint _amount, uint16 _variant) external;

    function getShip(uint _id) external view returns (Ship memory);

    function isShipDestroyed(uint _id) external view returns (bool);

    function setTimestampDestroyed(uint _id, uint _destroyerId) external;

    function setInFleet(uint _id, bool _inFleet) external;

    function customizeShip(
        uint _id,
        Ship memory _ship,
        bool _rerollName
    ) external;
}
