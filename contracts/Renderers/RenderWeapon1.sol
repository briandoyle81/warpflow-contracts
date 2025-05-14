// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderWeapon1 is IRendererNoShip {
    // SVG snippet for Laser - beam shape
    string private constant WEAPON_ART =
        '<g id="laser" transform="translate(128 128)"><path d="M-40,-20 L-20,-20 L-20,20 L-40,20 Z" fill="#ff0000" /><path d="M-40,-10 L-60,-10 L-60,10 L-40,10 Z" fill="#ff0000" opacity="0.5" /></g>';

    function render() external pure override returns (string memory) {
        return WEAPON_ART;
    }
}
