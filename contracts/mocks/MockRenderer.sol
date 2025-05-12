// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../IRenderer.sol";
import "../Types.sol";

contract MockRenderer is IRenderer {
    function renderShip(uint256) external pure returns (string memory) {
        return "mock-svg-data";
    }

    function tokenURI(Ship memory) external pure returns (string memory) {
        return "mock-uri";
    }
}
