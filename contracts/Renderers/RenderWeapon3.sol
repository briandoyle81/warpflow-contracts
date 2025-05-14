// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderWeapon3 is IRendererNoShip {
    // SVG snippet for Missile Launcher - missile tube shape
    string private constant WEAPON_ART =
        '<g id="missile-launcher" transform="translate(128 128)"><rect x="-40" y="-20" width="20" height="40" fill="#444444" /><circle cx="-30" cy="0" r="8" fill="#888888" /><path d="M-40,-20 L-40,20 M-30,-20 L-30,20 M-20,-20 L-20,20" stroke="#666666" stroke-width="1" /></g>';

    function render() external pure override returns (string memory) {
        return WEAPON_ART;
    }
}
