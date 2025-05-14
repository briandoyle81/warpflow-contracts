// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderAft1 is IRendererNoShip {
    // SVG snippet for Class 1 Aft - twin engines
    string private constant AFT_ART =
        '<g id="aft-1" transform="translate(128 128)"><rect x="-25" y="20" width="20" height="40" fill="#888888" /><rect x="5" y="20" width="20" height="40" fill="#888888" /><circle cx="-15" cy="40" r="8" fill="#444444" /><circle cx="15" cy="40" r="8" fill="#444444" /></g>';

    function render() external pure override returns (string memory) {
        return AFT_ART;
    }
}
