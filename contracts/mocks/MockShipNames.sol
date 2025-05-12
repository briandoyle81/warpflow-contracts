// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../IOnchainRandomShipNames.sol";

contract MockShipNames is IOnchainRandomShipNames {
    function getRandomShipName(bytes32) external pure returns (string memory) {
        return "Mock Ship";
    }
}
