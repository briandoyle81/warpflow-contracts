// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Types.sol";

interface IGenerateNewShip {
    function generateShip(
        uint id,
        uint serialNumber,
        uint64 randomBase,
        uint16 numberOfVariants
    ) external view returns (Ship memory);

    function generateSpecificShip(
        uint id,
        uint serialNumber,
        Ship memory ship
    ) external pure returns (Ship memory);

    function getTierOfTrait(uint _trait) external pure returns (uint8);
}
