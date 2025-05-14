// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderArmor3 is IReturnSVG {
    // SVG snippet for Heavy Armor
    string private constant ARMOR_ART =
        '<g id="heavy-armor" transform="translate(128 128)"><rect x="-30" y="-40" width="60" height="80" fill="#666666" /><path d="M-30,-40 L-30,40 M-15,-40 L-15,40 M0,-40 L0,40 M15,-40 L15,40 M30,-40 L30,40" stroke="#444444" stroke-width="1" /><rect x="-45" y="-55" width="90" height="110" fill="none" stroke="#ff0000" stroke-width="4" opacity="0.8" /><rect x="-40" y="-50" width="80" height="100" fill="none" stroke="#ff0000" stroke-width="3" opacity="0.6" /><rect x="-35" y="-45" width="70" height="90" fill="none" stroke="#ff0000" stroke-width="2" opacity="0.4" /></g>';

    function render() external pure override returns (string memory) {
        return ARMOR_ART;
    }
}
