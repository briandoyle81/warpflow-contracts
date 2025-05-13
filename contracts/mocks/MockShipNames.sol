// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../IOnchainRandomShipNames.sol";

contract MockShipNames is IOnchainRandomShipNames {
    string[] public shipNames;

    constructor() {
        shipNames = [
            "Mock Ship 1",
            "Mock Ship 2",
            "Mock Ship 3",
            "Mock Ship 4",
            "Mock Ship 5",
            "Mock Ship 6",
            "Mock Ship 7",
            "Mock Ship 8",
            "Mock Ship 9",
            "Mock Ship 10",
            "Mock Ship 11",
            "Mock Ship 12",
            "Mock Ship 13",
            "Mock Ship 14",
            "Mock Ship 15",
            "Mock Ship 16",
            "Mock Ship 17",
            "Mock Ship 18",
            "Mock Ship 19",
            "Mock Ship 20",
            "Mock Ship 21",
            "Mock Ship 22",
            "Mock Ship 23",
            "Mock Ship 24",
            "Mock Ship 25",
            "Mock Ship 26",
            "Mock Ship 27",
            "Mock Ship 28",
            "Mock Ship 29",
            "Mock Ship 30"
        ];
    }

    function getRandomShipName(
        bytes32 _seed
    ) external view returns (string memory) {
        return shipNames[uint(_seed) % shipNames.length];
    }
}
