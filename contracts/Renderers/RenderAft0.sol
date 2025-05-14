// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderAft0 is IRendererNoShip {
    // SVG snippet for Class 0 Aft - basic engine
    string private constant AFT_ART =
        '<g id="aft-0" transform="translate(128 128)"><rect x="-15" y="20" width="30" height="40" fill="#888888" /><circle cx="0" cy="40" r="10" fill="#444444" /></g>';

    function render() external pure override returns (string memory) {
        return AFT_ART;
    }
}
