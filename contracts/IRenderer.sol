// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";

interface IRenderer {
    function tokenURI(Ship memory ship) external pure returns (string memory);
}
