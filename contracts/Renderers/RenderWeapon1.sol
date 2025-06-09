// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderWeapon1 {
    string private constant PART_1 =
        '<path d="M137 104v-1l2-2 1-2v-3h-5l-1-1-1-2-22 1v-9l7-1h8v-1l1-1h10l1-1v-1h9l1-1 1-1 3 2 4 1h7v2l4 1 3 1v7l-1 1-2 1-7 1-3 2-2 1-2 1h-2l1 3v3h-15v-1z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="M149 84v-1h-1v1l-1 1h1l1-1Zm-8 1v-1h-1v1h1Zm-27 1-1-1h-1l-1 1h3Zm49 1v-1h-1v1h1Zm-6-1h-5l-2 1h10l-3-1Zm-9 1v-1h-1v1h1Zm-23 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm23 0v-1h-1v1l-1 1h1l1-1Zm-9 17v-1l2-2 1-2v-3h-5l-1-1-1-2-22 1v-9l7-1h7l2-1 2-1h4l5-1h4l4-1 2-1 2-1 3 2 3 1h7v2l6 2v8l-5 2h-4l-4 2-5 2 1 3v3h-15v-1Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="M159 82h-1l-2 1h5l-2-1Zm-18 3v-1h-1v1h1Zm-13 0v-1h-1v1h1Zm11 1v-1h-1v1h1Zm-22-1h-2v1h2v-1Zm-3 1-1-1h-1l-1 1h3Zm54 0h-2v1h2v-1Zm-3 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-2-1v-1l-4 1h-4l-1 1h9v-1Zm-33 0h-2v1h2v-1Zm-3 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm27-1h-1l1-2 1-1h-1l-2 3-2 2 2-1h2v-1Zm13 5v-1h-1v1h1Zm-7 1v-1h-1v1h1Zm-12 11v-1h-1v1h1Zm-5 1v-1l2-2 1-2v-3h-5l-1-1-1-2-22 1v-9l7-1h7l2-1 2-1 9-1 6-1 6-1 3 1 3 1h7v2l6 2v8l-5 2h-4l-3 2-3 1v-1l-1 1-2 1 1 6h-15v-1Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M159 82h-1l-2 1h5l-2-1Zm-18 3v-1h-1v1h1Zm-13 0v-1h-1v1h1Zm11 1v-1h-1v1h1Zm-22-1h-2v1h2v-1Zm-3 1-1-1h-1l-1 1h3Zm54 0h-2v1h2v-1Zm-3 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-4-1v-1l-4 1h-4l-1 1h9v-1Zm-33 0h-2v1h2v-1Zm-3 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm27-1h-1l1-2 1-1h-1l-2 3-2 2 2-1h2v-1Zm-16 3h-5l-9 1h19l-5-1Zm29-2-1-1v6l1-2v-3Zm-7 5v-1h-1v1h1Zm-12 11v-1h-1v1h1Zm-5 1v-1l2-2 1-2v-3h-5l-1-1-1-2-22 1v-9l7-1h7l2-1 2-1 9-1 6-1 6-1 3 1 3 1h7v2l6 2v8l-5 2h-4l-3 2-3 1v-1l-1 1-2 1 1 6h-15v-1Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M154 82v-1h-1v1h1Zm7 0h-2l-3 1h7l-2-1Zm7 4v-1h-2v2h2v-1Zm-29-1v-1h-12v2h11v1h1v-2Zm-13 1v-1h-11v2h11v-1Zm-12 0v-1h-3l1 1 2 1v-1Zm51 0-1-1v3h1v-2Zm-2 0-1-1v5l1-3v-1Zm-31 3h-5l-9 1h19l-5-1Zm-15 1v-1h-1l-1-1v2h2Zm-3-1h-2v1h2v-1Zm47-3-1-1v7l1-4v-2Zm-13 7v-1h-1v1h1Zm-6-1v-1h-1v1l-1 1h1l1-1Zm11-7v-1h1v1h-1Zm-9 2v-1l2 1h1v1h-4l1-1Zm12 1h1l1 1h-2v-1Zm-10 1 2-1v-3h2v3l2 1 2 1-1 2v2h2l4-2v-7h-4v-2h-7l-1 1-1 1h-1l-1-1h-2l-2-1v7h2l1-1v6l1-5 2-1Zm-7 3h-1l-2 2 3-1v-1Zm6 3h-2v1h2v-1Zm2 6-1-1h-1l-1 1h3Zm-4 0v-1h-1v1h1Zm6 2v-1h-10l4 1 4 1 2-1Zm-12 1v-1l2-2 1-2v-3h-5l-1-1-1-2-22 1v-9l7-1h7l2-1 2-1 9-1 6-1 6-1 3 1 3 1h4l5 2 4 2v7l-2 1-2 2h-4l-4 1-3 1-2 2v6h-15v-1Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M155 81h-2v1h2v-1Zm-4 0h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm-14 7h-5l-9 1h19l-5-1Zm7-1v-6h6l-3-1h-2l-1 1-1 1h-11v1h-1l1 2 1 1 10-1v5h1v-3Zm29 1v-4h-2v7h2v-3Zm-3-3-1-2v9l1-5v-2Zm-33 6v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-4-1h-5l-2 1h10l-3-1Zm-12-2v-4h-3l1 4v3h2v-3Zm36 2v-1h-2l-1 3h4l-1-2Zm-13 1v-1h-4v2h3l1-1Zm26 1h-2v1h2v-1Zm-2-8v-1l1 1v1h-1v-1Zm-17 2v-1h1v1l-1 1h-1l1-1Zm13 2v-1h1v1h-1Zm-7 6 1-1-2 1h-2v-3l1-3v-3l1-1 1 1v3l1 2 1 2 2 1 2 1h3l1-1v-1l-1 1h-1v-1l1-2v-6l1 3 1 4v-5l1 3 1 3v-8l-1-1v-2h-6l1 1 2 1h-2l-2 1v-2h-7v1l-1 1h-2l1-1 2-1h-8v8l4-2-2 2-2 2-1-1h-2l-2 3h4l4-1v2h7v-1Zm-1 6v-1h-5l-4-1v2h9Zm2 2v-1h-12v1l-1 1h12l1-1Zm-14 1v-1l2-2 1-2v-3h-5l-1-1-1-2h-11l-11 1v-9l4-1h4l-4 1v6l1 1h1v-5h9v-1l-1-2 1-1 1-1h9l2-1 2-1h13l4 1h4l8 4v7l-2 1-2 2h-4l-4 1-3 1-2 2v6h-15v-1Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="M155 81h-2v1h2v-1Zm-4 0h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm-7 6v-6h6l-3-1h-2l-1 1-1 1h-11v1h-1l1 2 1 1 10-1v5h1v-3Zm29 1v-4h-2v7h2v-3Zm-3-3-1-2v9l1-5v-2Zm-33 6v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-4-1h-5l-2 1h10l-3-1Zm24 0v-1h-2l-1 3h4l-1-2Zm-13 1v-1h-4v2h3l1-1Zm24-7v-1l1 1v1h-1v-1Zm-17 2v-1h1v1l-1 1h-1l1-1Zm13 2v-1h1v1h-1Zm2-1v-3l1 3-1 4v-4Zm-1 5v-1h1v1h-1Zm-8 2 1-1-2 1h-2v-3l1-3v-3l1-1 1 1v3l1 2 1 2 2 1 2 1h3v-1l1-1h1l2 1-1-1h-1v-6l1 3 1 3v-8l-1-1v-2h-6l1 1 2 1h-2l-2 1v-2h-7v1l-1 1h-2l1-1 2-1h-8v8l4-2-2 2-2 2-1-1h-2l-2 3h4l4-1v2h7v-1Zm-1 6v-1h-5l-4-1v2h9Zm2 2v-1h-12v1l-1 1h12l1-1Zm-14 1v-1l2-2 1-2v-3h-5l-1-1-1-2h-11l-11 1v-3l1 1h2v-7h-3l1 1v1h-1l-1-1 1-1v-1h8l-4 1v6l1 1h1v-2h20v-2h-20l4-1h5l-1-3 1-1 1-1h9l2-1 2-1h13l4 1h4l8 4v7l-2 1-2 2h-4l-4 1-3 1-2 2v6h-15v-1Z" style="fill:';
    string private constant PART_8 = ';"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(222, 0%, 63%)";
    string private constant COLOR_3 = "hsl(6, 61%, 41%)";
    string private constant COLOR_4 = "hsl(220, 2%, 37%)";
    string private constant COLOR_5 = "hsl(223, 6%, 24%)";
    string private constant COLOR_6 = "hsl(10, 65%, 25%)";
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
