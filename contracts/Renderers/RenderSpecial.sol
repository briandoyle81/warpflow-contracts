// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderSpecial1.sol";
import "./RenderSpecial2.sol";
import "./RenderSpecial3.sol";

contract RenderSpecial is IRenderer {
    RenderSpecial1 private immutable renderSpecial1;
    RenderSpecial2 private immutable renderSpecial2;
    RenderSpecial3 private immutable renderSpecial3;

    constructor() {
        renderSpecial1 = new RenderSpecial1();
        renderSpecial2 = new RenderSpecial2();
        renderSpecial3 = new RenderSpecial3();
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
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
