// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";
import "./IRenderer.sol";
import "./Renderers/RenderSpecial.sol";
import "./Renderers/RenderAft.sol";
import "./Renderers/RenderWeapon.sol";
import "./Renderers/RenderBody.sol";
import "./Renderers/RenderFore.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ImageRenderer {
    using Strings for string;

    // Base SVG template with viewBox and dimensions
    string private constant BASE_SVG =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">';
    string private constant SVG_END = "</svg>";

    IRenderComponent public immutable renderSpecial;
    IRenderComponent public immutable renderAft;
    IRenderComponent public immutable renderWeapon;
    IRenderComponent public immutable renderBody;
    IRenderComponent public immutable renderFore;

    constructor(
        address _renderSpecial,
        address _renderAft,
        address _renderWeapon,
        address _renderBody,
        address _renderFore
    ) {
        renderSpecial = IRenderComponent(_renderSpecial);
        renderAft = IRenderComponent(_renderAft);
        renderWeapon = IRenderComponent(_renderWeapon);
        renderBody = IRenderComponent(_renderBody);
        renderFore = IRenderComponent(_renderFore);
    }

    function renderShip(Ship memory ship) public view returns (string memory) {
        // Start with the base SVG
        string memory svg = BASE_SVG;

        // Call each renderer in sequence from bottom to top
        svg = string.concat(svg, renderSpecial.render(ship)); // Special effects (bottom)
        svg = string.concat(svg, renderAft.render(ship)); // Aft section
        svg = string.concat(svg, renderWeapon.render(ship)); // Weapons
        svg = string.concat(svg, renderBody.render(ship)); // Body
        svg = string.concat(svg, renderFore.render(ship)); // Fore section (top)

        // Close the SVG
        svg = string.concat(svg, SVG_END);

        return svg;
    }
}
