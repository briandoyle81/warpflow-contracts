// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderWeapon2 is IRendererNoShip {
    // SVG snippet for Railgun - rail shape
    string private constant WEAPON_ART =
        '<g id="railgun" transform="translate(128 128)"><rect x="-40" y="-15" width="30" height="30" fill="#444444" /><path d="M-40,-15 L-40,15 M-30,-15 L-30,15 M-20,-15 L-20,15" stroke="#888888" stroke-width="2" /><circle cx="-25" cy="0" r="5" fill="#00ff00" /></g>';

    function render() external pure override returns (string memory) {
        return WEAPON_ART;
    }
}
