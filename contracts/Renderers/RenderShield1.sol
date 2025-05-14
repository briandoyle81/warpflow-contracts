// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderShield1 is IReturnSVG {
    // SVG snippet for Light Shield
    string private constant SHIELD_ART =
        '<g id="light-shield" transform="translate(128 128)"><rect x="-30" y="-40" width="60" height="80" fill="#666666" /><path d="M-30,-40 L-30,40 M-15,-40 L-15,40 M0,-40 L0,40 M15,-40 L15,40 M30,-40 L30,40" stroke="#444444" stroke-width="1" /><path d="M-35,-45 L35,-45 L40,0 L35,45 L-35,45 L-40,0 Z" fill="none" stroke="#00ffff" stroke-width="2" opacity="0.5" /></g>';

    function render() external pure override returns (string memory) {
        return SHIELD_ART;
    }
}
