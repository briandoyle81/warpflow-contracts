// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderFore is IRenderComponent {
    IReturnSVG public immutable renderFore0; // Class 0
    IReturnSVG public immutable renderFore1; // Class 1
    IReturnSVG public immutable renderFore2; // Class 2
    IReturnSVG public immutable renderForePerfect; // Perfect ship

    constructor(address[] memory renderers) {
        require(renderers.length == 4, "Invalid renderers array in RenderFore");
        renderFore0 = IReturnSVG(renderers[0]);
        renderFore1 = IReturnSVG(renderers[1]);
        renderFore2 = IReturnSVG(renderers[2]);
        renderForePerfect = IReturnSVG(renderers[3]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        // If the ship is perfect, use the perfect renderer
        if (
            ship.traits.accuracy == 2 &&
            ship.traits.hull == 2 &&
            ship.traits.speed == 2 &&
            (ship.equipment.armor == Armor.Heavy ||
                ship.equipment.shields == Shields.Heavy)
        ) {
            return renderForePerfect.render(ship);
        }
        // Use the accuracy to determine which fore class to use
        if (ship.traits.accuracy == 0) {
            return renderFore0.render(ship);
        } else if (ship.traits.accuracy == 1) {
            return renderFore1.render(ship);
        } else {
            return renderFore2.render(ship);
        }
    }
}
