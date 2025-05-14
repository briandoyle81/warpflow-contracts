// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderWeapon4 is IReturnSVG {
    // SVG snippet for Plasma Cannon - plasma chamber shape
    string private constant WEAPON_ART =
        '<g id="plasma-cannon" transform="translate(128 128)"><rect x="-40" y="-15" width="25" height="30" fill="#444444" /><circle cx="-27.5" cy="0" r="10" fill="#0000ff" opacity="0.7" /><path d="M-40,-15 L-40,15 M-30,-15 L-30,15 M-20,-15 L-20,15" stroke="#888888" stroke-width="2" /></g>';

    function render() external pure override returns (string memory) {
        return WEAPON_ART;
    }
}
