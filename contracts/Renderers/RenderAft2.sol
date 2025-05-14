// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderAft2 is IRendererNoShip {
    // SVG snippet for Class 2 Aft - triple engines with details
    string private constant AFT_ART =
        '<g id="aft-2" transform="translate(128 128)"><rect x="-35" y="20" width="15" height="40" fill="#888888" /><rect x="-10" y="20" width="15" height="40" fill="#888888" /><rect x="15" y="20" width="15" height="40" fill="#888888" /><circle cx="-27.5" cy="40" r="6" fill="#444444" /><circle cx="-2.5" cy="40" r="6" fill="#444444" /><circle cx="22.5" cy="40" r="6" fill="#444444" /><path d="M-35,30 L-20,30 M-10,30 L5,30 M15,30 L30,30" stroke="#444444" stroke-width="2" /></g>';

    function render() external pure override returns (string memory) {
        return AFT_ART;
    }
}
