// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";
import "./IRenderer.sol";
import "./Renderers/RenderSpecial.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ImageRenderer {
    using Strings for string;

    // Base SVG template with viewBox and dimensions
    string private constant BASE_SVG =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">';
    string private constant SVG_END = "</svg>";

    // Array of renderers to call in sequence
    // Renderers are called in order, with later renderers being drawn on top
    // [0] = bottom layer (e.g., base ship)
    // [1] = middle layer (e.g., equipment)
    // [2] = top layer (e.g., special effects)
    address[] private renderers;

    constructor() {
        // Initialize renderers in order from bottom to top
        // First renderer (index 0) will be drawn first (bottom)
        // Last renderer will be drawn last (top)
        renderers.push(address(new RenderSpecial()));
        // TODO: Add other renderers in the correct order
    }

    function renderShip(Ship memory ship) public view returns (string memory) {
        // Start with the base SVG
        string memory svg = BASE_SVG;

        // Call each renderer in sequence
        // First renderer (index 0) will be drawn first (bottom)
        // Last renderer will be drawn last (top)
        for (uint i = 0; i < renderers.length; i++) {
            // Call the renderer's render function and append its output
            svg = string.concat(svg, IRenderer(renderers[i]).render(ship));
        }

        // Close the SVG
        svg = string.concat(svg, SVG_END);

        return svg;
    }
}
