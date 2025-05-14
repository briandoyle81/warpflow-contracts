// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderSpecial2 is IRendererNoShip {
    // SVG snippet for Repair Drones - small drone shapes
    string private constant REPAIR_DRONES_ART =
        '<g id="repair-drones" transform="translate(128 128)"><circle cx="-20" cy="-20" r="10" fill="#00ff00" /><circle cx="20" cy="-20" r="10" fill="#00ff00" /><circle cx="0" cy="20" r="10" fill="#00ff00" /><path d="M-20,-20 L20,-20 L0,20 Z" fill="none" stroke="#00ff00" stroke-width="2" /></g>';

    function render() external pure override returns (string memory) {
        return REPAIR_DRONES_ART;
    }
}
