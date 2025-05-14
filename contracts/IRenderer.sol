// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";

interface IRenderer {
    function render(Ship memory ship) external view returns (string memory);
}
