// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";

contract RenderBody is IRenderComponent {
    // Base ship body SVG (used when no shields or armor)
    string private constant BASE_BODY_ART =
        '<g id="base-body" transform="translate(128 128)"><rect x="-30" y="-40" width="60" height="80" fill="#666666" /><path d="M-30,-40 L-30,40 M-15,-40 L-15,40 M0,-40 L0,40 M15,-40 L15,40 M30,-40 L30,40" stroke="#444444" stroke-width="1" /></g>';

    IReturnSVG public immutable renderShield1; // Light Shield
    IReturnSVG public immutable renderShield2; // Medium Shield
    IReturnSVG public immutable renderShield3; // Heavy Shield
    IReturnSVG public immutable renderArmor1; // Light Armor
    IReturnSVG public immutable renderArmor2; // Medium Armor
    IReturnSVG public immutable renderArmor3; // Heavy Armor

    constructor(address[] memory renderers) {
        require(renderers.length == 6, "Invalid renderers array");
        renderShield1 = IReturnSVG(renderers[0]);
        renderShield2 = IReturnSVG(renderers[1]);
        renderShield3 = IReturnSVG(renderers[2]);
        renderArmor1 = IReturnSVG(renderers[3]);
        renderArmor2 = IReturnSVG(renderers[4]);
        renderArmor3 = IReturnSVG(renderers[5]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        // If both shields and armor are None, return base body
        if (
            ship.equipment.shields == Shields.None &&
            ship.equipment.armor == Armor.None
        ) {
            return BASE_BODY_ART;
        }

        // If shields are present, render shield
        if (ship.equipment.shields != Shields.None) {
            if (ship.equipment.shields == Shields.Light) {
                return renderShield1.render();
            } else if (ship.equipment.shields == Shields.Medium) {
                return renderShield2.render();
            } else if (ship.equipment.shields == Shields.Heavy) {
                return renderShield3.render();
            }
        }

        // If armor is present, render armor
        if (ship.equipment.armor != Armor.None) {
            if (ship.equipment.armor == Armor.Light) {
                return renderArmor1.render();
            } else if (ship.equipment.armor == Armor.Medium) {
                return renderArmor2.render();
            } else if (ship.equipment.armor == Armor.Heavy) {
                return renderArmor3.render();
            }
        }

        return BASE_BODY_ART;
    }
}
