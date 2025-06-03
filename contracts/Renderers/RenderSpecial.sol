// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderSpecial is IRenderComponent {
    IReturnSVG public immutable renderSpecial1;
    IReturnSVG public immutable renderSpecial2;
    IReturnSVG public immutable renderSpecial3;

    constructor(address[] memory renderers) {
        require(
            renderers.length == 3,
            "Invalid renderers array in RenderSpecial"
        );
        renderSpecial1 = IReturnSVG(renderers[0]);
        renderSpecial2 = IReturnSVG(renderers[1]);
        renderSpecial3 = IReturnSVG(renderers[2]);
    }

    function render(Ship memory ship) external view returns (string memory) {
        if (ship.equipment.special == Special.None) {
            return "";
        } else if (ship.equipment.special == Special.EMP) {
            return renderSpecial1.render(ship);
        } else if (ship.equipment.special == Special.RepairDrones) {
            return renderSpecial2.render(ship);
        } else if (ship.equipment.special == Special.FlakArray) {
            return renderSpecial3.render(ship);
        }
        return "";
    }
}
