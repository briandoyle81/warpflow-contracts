// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "../IRendererNoShip.sol";

contract RenderSpecial is IRenderer {
    IRendererNoShip public immutable renderSpecial1;
    IRendererNoShip public immutable renderSpecial2;
    IRendererNoShip public immutable renderSpecial3;

    constructor(address[] memory renderers) {
        require(renderers.length == 3, "Invalid renderers array");
        renderSpecial1 = IRendererNoShip(renderers[0]);
        renderSpecial2 = IRendererNoShip(renderers[1]);
        renderSpecial3 = IRendererNoShip(renderers[2]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        if (ship.equipment.special == Special.None) {
            return "";
        } else if (ship.equipment.special == Special.EMP) {
            return renderSpecial1.render();
        } else if (ship.equipment.special == Special.RepairDrones) {
            return renderSpecial2.render();
        } else if (ship.equipment.special == Special.FlakArray) {
            return renderSpecial3.render();
        }
        return "";
    }
}
