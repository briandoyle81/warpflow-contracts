// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderFore1 is IReturnSVG {
    // SVG snippet for Class 1 Fore - complex pointed shape
    string private constant FORE_ART =
        '<g id="fore-1" transform="translate(128 128)"><path d="M30,-20 L50,0 L30,20 Z" fill="#666666" /><rect x="0" y="-20" width="30" height="40" fill="#666666" /><path d="M30,-15 L45,-5 L30,5 Z" fill="#444444" /><path d="M30,5 L45,15 L30,25 Z" fill="#444444" /></g>';

    function render() external pure override returns (string memory) {
        return FORE_ART;
    }
}
