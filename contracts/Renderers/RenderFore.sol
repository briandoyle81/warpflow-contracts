// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderFore is IRenderComponent {
    IReturnSVG public immutable renderFore0; // Class 0
    IReturnSVG public immutable renderFore1; // Class 1
    IReturnSVG public immutable renderFore2; // Class 2

    constructor(address[] memory renderers) {
        require(renderers.length == 3, "Invalid renderers array");
        renderFore0 = IReturnSVG(renderers[0]);
        renderFore1 = IReturnSVG(renderers[1]);
        renderFore2 = IReturnSVG(renderers[2]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        // Use the variant to determine which fore class to use
        if (ship.traits.variant == 0) {
            return renderFore0.render();
        } else if (ship.traits.variant == 1) {
            return renderFore1.render();
        } else {
            return renderFore2.render();
        }
    }
}
