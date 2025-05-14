// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "../IRendererNoShip.sol";

contract RenderAft is IRenderer {
    IRendererNoShip public immutable renderAft0;
    IRendererNoShip public immutable renderAft1;
    IRendererNoShip public immutable renderAft2;

    constructor(address[] memory renderers) {
        require(renderers.length == 3, "Invalid renderers array");
        renderAft0 = IRendererNoShip(renderers[0]);
        renderAft1 = IRendererNoShip(renderers[1]);
        renderAft2 = IRendererNoShip(renderers[2]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        // Use the variant to determine which aft class to use
        if (ship.traits.variant == 0) {
            return renderAft0.render();
        } else if (ship.traits.variant == 1) {
            return renderAft1.render();
        } else {
            return renderAft2.render();
        }
    }
}
