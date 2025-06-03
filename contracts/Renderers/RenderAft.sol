// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderAft is IRenderComponent {
    IReturnSVG public immutable renderAft0;
    IReturnSVG public immutable renderAft1;
    IReturnSVG public immutable renderAft2;

    constructor(address[] memory renderers) {
        require(renderers.length == 3, "Invalid renderers array in RenderAft");
        renderAft0 = IReturnSVG(renderers[0]);
        renderAft1 = IReturnSVG(renderers[1]);
        renderAft2 = IReturnSVG(renderers[2]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        // Use the speed to determine which aft class to use
        if (ship.traits.speed == 0) {
            return renderAft0.render(ship);
        } else if (ship.traits.speed == 1) {
            return renderAft1.render(ship);
        } else {
            return renderAft2.render(ship);
        }
    }
}
