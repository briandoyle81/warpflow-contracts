// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderArmor2 is IReturnSVG {
    // SVG snippet for Medium Armor
    string private constant ARMOR_ART =
        '<g id="medium-armor" transform="translate(128 128)"><rect x="-30" y="-40" width="60" height="80" fill="#666666" /><path d="M-30,-40 L-30,40 M-15,-40 L-15,40 M0,-40 L0,40 M15,-40 L15,40 M30,-40 L30,40" stroke="#444444" stroke-width="1" /><rect x="-40" y="-50" width="80" height="100" fill="none" stroke="#ff0000" stroke-width="3" opacity="0.7" /><rect x="-35" y="-45" width="70" height="90" fill="none" stroke="#ff0000" stroke-width="2" opacity="0.5" /></g>';

    function render() external pure override returns (string memory) {
        return ARMOR_ART;
    }
}
