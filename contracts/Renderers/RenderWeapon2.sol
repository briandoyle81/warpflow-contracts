// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderWeapon2 {
    string private constant PART_1 =
        '<path d="m153 86-1-1-1 1v1h2v-1Zm-18 18v-2l2-1 1-2h-8l-35-1-34-1-2-1v-4h69l-1-2-1-1H59v-3l1-2h12l2-1 2-1 73-2 9 1h7l7 1 1 1v1h8l2 2v5l-1 1v2h-4l-1 2h-10l-5 1-5 1-2 1-1 1 1 2v3h-20v-1Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="M155 81h-6 9-3Zm-9 1h-9 12-3Zm20 1h-1l-2 1h5l-2-1Zm-7 1-1-1-1 1v1h2v-1Zm-5 0h-6 9-3Zm-8 0h-4l3 1h3l-2-1Zm-6 0h-1l-2 1h5l-2-1Zm-8 0h-1v1h1v-1Zm-2 1-1-1-1 1v1h2v-1Zm-6 0h-11 15-4Zm-15 0h-9 13-4Zm-16 0H74h26-7Zm-32 0h-1v1h1v-1Zm116 1h-6 8-2Zm-9 0h-8 11-3Zm13 1v-1h-2v2h1l1-1Zm-5 1h-1v1h1v-1Zm-13 0h-1v1h1v-1Zm-26 0h-1l-2 1h5l-2-1Zm29 1h-1v1h1v-1Zm-13 0-1-1-1 1v1h2v-1Zm2-2 3-1h-6l-2 1-2 2h-9l4 1h5l2-2 2-1h3Zm-17 3-1-1-1 1v1h2v-1Zm2 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-6 1h-1v1h1v-1Zm-4 1h-1v1h1v-1Zm-51 0h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm50 1h-1v1h1v-1Zm16 9v-2l2-1 1-2-21-1H74v-1l-1-1H59v-4h69l-1-2-1-1H59v-4l2-2h74l1-1 1-1-9 1h1l1-1h28l14 1 1 1v1h8l1 1 1 2v5l-6 3-9 1-8 1-3 1-4 2 1 2 1 2v1h-20v-1Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="M146 82h-9 12-3Zm21 1h-4l3 1h3l-2-1Zm-8 1-1-1-1 1v1h2v-1Zm-5 0h-6 9-3Zm-7 0h1-14l3-2h-8v1l-1 1 3-1h3-2l-1 1 1 1 2 1 13-1v-1Zm-17 1-1-1-1 1v1h2v-1Zm-6 0h-11 15-4Zm-15 0h-9 13-4Zm-16 0H74h26-7Zm-32 0h-1v1h1v-1Zm116 1h-6 8-2Zm-9 0h-9 12-3Zm13 1v-1h-2v2h1l1-1ZM61 87h-1v1h1v-1Zm116 1-1-1-1 1v1h2v-1Zm-40 0h-1l-2 1h5l-2-1Zm30 1v-1h-6l3 2h3v-1Zm-13 0-1-1-1 1-1 1h3v-1Zm1-2 3-1h-6l-2 1-2 2h-9l4 1h5l2-2 2-1h3Zm-17 3-1-1-1 1v1h2v-1Zm1 2h-5 7-2Zm-7 1v-1h-1l-1 2h1l1-1Zm-3 1-1-1-1 1-1 1h3v-1Zm-14 0-1-1-1 1v1h2v-1Zm-5 0h-9 12-3Zm-12 0h-1v1h1v-1Zm-2 0-1-1-1 1-1 1h3v-1Zm-4 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0-1-1-1 1-1 1h3v-1Zm-4 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0-1-1-1 1-1 1h3v-1Zm-5 0-1-1-1 1-1 1h3v-1Zm-4 0-1-1-1 1-1 1h3v-1Zm-5 0h-1v1h1v-1Zm61 0h-9l1 1h5l3-1Zm14 8h-1v1h1v-1Zm-4 2v-2l2-1 1-2-21-1H74v-1l-1-1-7-1h-6l-1-3h69l-1-2-1-1H59v-4l1-1h66l2-2 2-1 27-1 1 1h-5l-4-1v1l1 1h22l1 2h8l1 1 1 2v5l-3 2-3 1-10 1-5 1-5 1-4 3 2 2v2h-20v-1Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M87 84h1v1h-1v-1Zm-3 0 1-1 1 2h-2v-1Zm-4 0h1l3 1h-5l1-1Zm92-1-1-1-1 1v1h2v-1Zm-5 0h-4l3 1h3l-2-1Zm-23 0h1v1h-1v-1Zm-4 0h1l3 1h-5l1-1Zm16 1h-6v-2h7v3h2l-2-4h-8v3h-2l1-1v-1h-19l-1 1 2 1 3 2 23-2Zm-25 1-1-1-1 1-1 1h3v-1Zm-22 0h-9 13-4Zm-43 0-1-1-1 1v1h2v-1Zm-3 0h-1v1h1v-1Zm114 1h-6 8-2Zm4 1v-1h-2v2h1l1-1Zm-11 0v-1h-11l5 1h6v1-1ZM61 86l-1-2v4l1-1v-1Zm76 2h-1l-2 1h5l-2-1Zm40 1v-1h-2v2h1l1-1Zm-23 0-1-1-1 1-1 1h3v-1Zm12 1h2l-1-2h-6l2 1-2 2 3-1h2Zm-9 0h-1v1h1v-1Zm-2-3 3-1h-6l-2 1-2 2h-9l4 1h5l2-2 2-1h3Zm-17 3-1-1-1 1v1h2v-1Zm1 2h-5 7-2Zm-6 0-1-1-2 3 1-1 2-1Zm-18 2-1-1-1 1v1h2v-1Zm-6 0h-9 13-4Zm-12 0h-6 8-2Zm-11 0H74h17-5Zm-15 0h-8 11-3Zm-10 0h-1v1h1v-1Zm67 0h2-14l1 1h10l1-1Zm10 2h-1v1h1v-1Zm1 6h-1v1h1v-1Zm-4 2v-2l2-1 1-2-21-1H74v-1l-1-1-7-1h-6l-1-2v-1h69l-1-2-1-1H59v-3l1-2h7l8-1 2 1 2 1-5-1v2h13l13-1h-5l-5-1h35l-12 1h7l8 1-2-1h-1l5-4 13-1h14l1 1v1h14l1 2h8l2 2v5l-1 2-2 1-10 1-10 2-4 1-3 2v2l2 1v2h-20v-1Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M130 84h1v1h-1v-1Zm-18 0h1v1h-1v-1Zm34 2h1v1h-1v-1Zm5 5-1-1h4v2h-3v-1Zm4 1h1v1h-1v-1Zm-5 1h1v1h-1v-1Zm-11 1 1-1 1 2h-3l1-1Zm8 1h1v1h-1v-1Zm-14 0v-1h2v3h-2v-2Zm39-12-1-1-1 1v1h2v-1Zm-4 1v-1h-5l5 1v1-1ZM62 87v-1l12-1H60v3h2v-1Zm85 2h-8l6 1h1l1-1Zm-9 1-1-1-1 1v1h2v-1Zm36-1v-2l1 2v1l-1 1v-2Zm3 1v-2l2-1v5h2l1-5-1-1h-10v6l3-1h4l-1-1Zm-65 5v-1H74v2h38v-1Zm23 9v-2l2-1 1-2-21-1H74v-1l-1-1h-7l-6-1-1-4 1 2 1 1h12-9l-1-1-1-1h33l33 1v-2l-2-2H59v-4l1-1h2l6-1h7l-1 1v2h70l1 1v1h4l1-2 1-1h6-3l-2 1-3 3-4 3h-5l-5-1v-2h3v-3l-2 1-1 1h-1v4l-2-1h-2l1 2-18 1v1l8 1 8 1 1-2v1l1 2h4l1-3 1-2v3h7l7 1v-2l6-1v-7h3l3 3h-3v2l10-1v-5h-11l-1-3-1-3-7 1-8 1h-13l-1 1-1 2v-2l1-1 2-1 27-1 1 1v1h14l1 2h8l2 2v5l-1 2-2 1-10 1-10 2-4 1-3 2v2h-15 16l1 1v1l-20 1v-1Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M160 89v-1h2l1 1v1h-3v-1Zm-25 1h1v1h-1v-1Zm39 0v-2l1-1v4l3 1h-3l-1-2Zm-23 1v-1h2l1 1v1h-3v-1Zm-89 1h1v1h-1v-1Zm1-5 1-1 10-1H60v3h2l1-1Zm65 4-2-2H59v-4l1-1h2l6-1h7l-1 1v2h69l2 1 2 1 2-1 3-2-6 7-7-1h7v-1l1-1h-4l-2-3-1 2-1 1-1-1v-1h-6v2l2-1v4h-2v-1l1-1h-4v2h2l-1 1-2-2Zm11 3 1-1 1 2h-3l1-1Zm-80 0v-2h1v2l1 2h-1l-1-2Zm74 2h1v1h-1v-1Zm8 8 1-1 1 2h-3l1-1Zm31-20v-1h-2v2h1l1-1Zm-4 0v-1h-6l1 2h5v-1Zm3 10-1-1-1 1v1h2v-1Zm-4 0-1-1-1 1-1 1h3v-1Zm-14 3v-1h-1l-1 2h1l1-1Zm-3 2h-1v1h1v-1Zm-3 1 1-1h-8v1h4l3 1v-1Zm-12 4v-2l3-3h-4l-3-1h-29l-28-1-1-2v-2l2 3h11l12 1 1-2 3 2h10v-2l2 1 2 1h13l1-3v4h5l2-1 2-1 11 1 1-1 1-1h5l1-3h12v-3l1-3v6l4 1h3l-1-4 1-1 1-2v7h2l1-3v-3l-1-1h-22l-2-5h-13l-12 1-4 1 2-2 27-1 1 1v1h14l1 2h8l2 2v5l-3 3h-2l-3 1-9 1-9 1-1 1-1 2h-2l3-4-2 2-2 1 2 2 1 3v1l-2-3h-16v3h-2v-1Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="M127 86h1v1h-1v-1Zm-7 0h1v1h-1v-1Zm-12 0h6-8 2Zm-9 0 1-1 1 2h-2v-1Zm-4 0h1l3 1h-5l1-1Zm-3 0h1v1h-1v-1Zm-3 0 1-1 1 2h-2v-1Zm-2 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-5 0h1l3 1h-5l1-1Zm-4 0 1-1 1 2h-2v-1Zm-2 0h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm75 1v-2l1 2-1 1v-1Zm2 1 1-1 1 2h-2v-1Zm-6-1v-1h2l-1 1v2h-1v-2Zm-7 1 1-2h6l-5 1-1 1-1 1v-1Zm-2 0h1v1h-1v-1Zm-44 0 1-1 1 2h-2v-1Zm-18 0h1v1h-1v-1Zm-5 0v-1h2v2h-2v-1Zm-3-1v-2l1-1h2l6-1h7l-1 1v1H60l-1 4v-2Zm103 2h1v1h-1v-1Zm-2 0v-2l1 2-1 1v-1Zm-13 0h1v1h-1v-1Zm31 1v-2l1 2-1 1v-1Zm4 0v-3l-1-1v-1h-8l-1-2h-3l1 1v2h-2v-3h-6v2l3 1h-6v-1l1-1-2-1-1-2h-15l-14 1h1l1-1 27-1 1 1v1h14l1 2h8l2 4-1 4v-2Zm-41 1h6-7 1Zm-8-1v-3l1 3-1 2v-2Zm-6 0-1-1h2v1l1 2h-1l-1-2Zm3 2h1v1h-1v-1Zm9 2 1-1 1 2h-2v-1Zm28 1h3l2 1h-3l-3-1h1ZM59 94v-2h1v2l1 2h-1l-1-2Zm80 2 1-1 1 2h-2v-1Zm-40 2-25-1-1-3 1 1 1 2h37v-3l1 1 1 2h16v2l-3-1H99Zm63-4-1-1v3l1-1v-1Zm-2 0-1-1v3l1-1v-1Zm-7 3v-1h-1l-1 2h1l1-1Zm0 6-1-2h-7l-7 1-2 1-1 1v-2l3-3h-2v-2l7 1h6l2-2 2-1 1 1-3 3h-12v2l5-1h9l3-4 3-3h11v-3l1-3v6l9-1 1 1v1h-18l3 2h-2l-2 1-2-1h-2l-3 2-2 3 1 1 1 2-1 1-1-2Z" style="fill:';
    string private constant PART_8 = ';"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(40, 4%, 43%)";
    string private constant COLOR_3 = "hsl(215, 4%, 43%)";
    string private constant COLOR_4 = "hsl(220, 2%, 37%)";
    string private constant COLOR_5 = "hsl(223, 6%, 24%)";
    string private constant COLOR_6 = "hsl(213, 10%, 18%)";
    string private constant COLOR_7 = "hsl(225, 17%, 9%)";

    function render(Ship memory ship) external pure returns (string memory) {
        string memory chunk1 = string.concat(
            PART_1,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_1
                )
                : COLOR_1,
            PART_2,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_2
                )
                : COLOR_2,
            PART_3,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_3
                )
                : COLOR_3,
            PART_4,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_4
                )
                : COLOR_4
        );
        string memory chunk2 = string.concat(
            PART_5,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_5
                )
                : COLOR_5,
            PART_6,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_6
                )
                : COLOR_6,
            PART_7,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_7
                )
                : COLOR_7,
            PART_8
        );
        return string.concat(chunk1, chunk2);
    }
}
