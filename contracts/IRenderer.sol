// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ship} from "./Types.sol";

interface IRenderComponent {
    function render(Ship memory ship) external view returns (string memory);
}

interface IReturnSVG {
    function render(Ship memory ship) external view returns (string memory);
}

interface IRenderMetadata {
    function tokenURI(Ship memory ship) external view returns (string memory);
}
