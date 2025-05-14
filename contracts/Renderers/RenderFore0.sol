// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderFore0 is IReturnSVG {
    // SVG snippet for Class 0 Fore - simple pointed shape
    string private constant FORE_ART =
        '<g id="fore-0" transform="translate(128 128)"><path d="M30,-20 L50,0 L30,20 Z" fill="#666666" /><rect x="0" y="-20" width="30" height="40" fill="#666666" /></g>';

    function render() external pure override returns (string memory) {
        return FORE_ART;
    }
}
