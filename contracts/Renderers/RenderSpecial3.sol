// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRendererNoShip.sol";

contract RenderSpecial3 is IRendererNoShip {
    // SVG snippet for Flak Array - gun array shape
    string private constant FLAK_ARRAY_ART =
        '<g id="flak-array" transform="translate(128 128)"><rect x="-30" y="-10" width="60" height="20" fill="#ff0000" /><rect x="-25" y="-15" width="10" height="50" fill="#ff0000" /><rect x="15" y="-15" width="10" height="50" fill="#ff0000" /></g>';

    function render() external pure override returns (string memory) {
        return FLAK_ARRAY_ART;
    }
}
