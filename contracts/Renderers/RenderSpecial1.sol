// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderSpecial1 is IReturnSVG {
    // SVG snippet for EMP - lightning bolt shape
    string private constant EMP_ART =
        '<g id="emp" transform="translate(128 128)"><path d="M-20,-40 L0,-20 L-10,-20 L0,0 L-20,0 L-10,-20 L-20,-20 Z" fill="#00ffff" /><circle cx="0" cy="0" r="30" fill="none" stroke="#00ffff" stroke-width="2" /></g>';

    function render() external pure override returns (string memory) {
        return EMP_ART;
    }
}
