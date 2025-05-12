// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../IOnchainRandomShipNames.sol";

contract MockOnchainRandomShipNames is IOnchainRandomShipNames {
    function getRandomShipName(bytes32) external pure returns (string memory) {
        return "Mock Ship";
    }

    function requestRandomness() external pure returns (uint256) {
        return 1;
    }

    function getRandomness(uint256) external pure returns (uint256) {
        return 1;
    }
}
