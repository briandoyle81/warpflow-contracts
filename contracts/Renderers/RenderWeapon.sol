// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "../IRendererNoShip.sol";

contract RenderWeapon is IRenderer {
    IRendererNoShip public immutable renderWeapon1; // Laser
    IRendererNoShip public immutable renderWeapon2; // Railgun
    IRendererNoShip public immutable renderWeapon3; // Missile Launcher
    IRendererNoShip public immutable renderWeapon4; // Plasma Cannon

    constructor(address[] memory renderers) {
        require(renderers.length == 4, "Invalid renderers array");
        renderWeapon1 = IRendererNoShip(renderers[0]);
        renderWeapon2 = IRendererNoShip(renderers[1]);
        renderWeapon3 = IRendererNoShip(renderers[2]);
        renderWeapon4 = IRendererNoShip(renderers[3]);
    }

    function render(
        Ship memory ship
    ) external view override returns (string memory) {
        if (ship.equipment.mainWeapon == MainWeapon.Laser) {
            return renderWeapon1.render();
        } else if (ship.equipment.mainWeapon == MainWeapon.Railgun) {
            return renderWeapon2.render();
        } else if (ship.equipment.mainWeapon == MainWeapon.MissileLauncher) {
            return renderWeapon3.render();
        } else if (ship.equipment.mainWeapon == MainWeapon.PlasmaCannon) {
            return renderWeapon4.render();
        }
        return "";
    }
}
