// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderWeapon4 {
    string private constant PART_1 =
        '<path d="M129 84h-1v1h1v-1Zm6 18 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-3v-1h-8l-1-2h-11l-1 2h-9l-1 2h-5v-1l-1-1 2-2 2-2v-6l-4-1v-3h6l1 2h9l1 2h11v-2h7l7-5-2-2-1-1h-6v-3l3-3h6l1 1v2h6v2h5v5l10 1 2 1 1 1v4h-1l-1 3-1 4-5 3h-4l-3 3-3 2 1 1 1 1h4v4h-24l1-1Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="M129 84h-11 15-4Zm6 18 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-3v-1h-8l-1-2h-11l-1 2h-9l-1 2-2-1h-3v-1h-1l2-2 3-2v-5l-5-4v-1h6l1 2h9l1 2h11v-2h7l7-5-2-2-1-1h-6v-3l2-1 1-1 6-1 1 3h6v2h5v5h5l4 1 4 2v4h-1l-1 3-1 4-5 3h-4l-3 3-3 2 1 1 1 1h4v4h-24l1-1Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="m131 85 2-1h-15l1 2h11l1-1Zm0 2h-6l4 1h4l-2-1Zm-7 0h-3l-1 1h5l-1-1Zm11 15 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-3v-1h-8l-1-2h-11l-1 2h-9l-1 2-2-1h-3v-1h-1l2-2 3-2v-5l-5-4v-1h6l1 2h9l1 2h11v-2h7l7-5-2-2-1-1h-6v-3l2-1 1-1 6-1 1 3h6v2h5v5h5l4 1 4 2v4h-1l-1 3-1 4-5 3h-4l-3 3-3 2 1 1 1 1h4v4h-24l1-1Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M144 77h-1v1h1v-1Zm14 1h-2l-3 1h6l-1-1Zm-2 2-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0h-1v1h1v-1Zm13 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-20 1h-1v1h1v-1Zm-2 0h-3l-1 1h5l-1-1Zm-6 3 2-1h-15l1 2h11l1-1Zm0 2h-6l4 1h4l-2-1Zm-7 0h-3l-1 1h5l-1-1Zm11 15 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l5-3v-5l-5-4v-1h7v1l-1 1h9l2 1 1 1h10l1-2h6l7-5-2-2-1-1h-6v-3l3-2h6l1 2h6v2l5 1v4h-6v1l9-1h3l3 1 1 1h2l-5 1h-5 11v4h-1l-1 3-1 4-5 3h-3l-4 3-3 3v1h6v4h-24l1-1Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M144 77h-1v1h1v-1Zm14 1h-2l-3 1h6l-1-1Zm-2 2-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0h-1v1h1v-1Zm13 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-20 1h-1v1h1v-1Zm-2 0h-3l-1 1h5l-1-1Zm-5 3-1-3h-12l-1 2 1 1v1h13v-1Zm-2 2h-10 13-3Zm5 15 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l5-3v-5l-5-4v-1h7v1l-1 1h9l2 1 1 1h10l1-2h6l7-5-2-2-1-1h-6v-3l3-2h6l1 2h6v2l5 1v4h-6v1l9-1h3l3 1 1 1h2l-5 1h-5 11v4h-1l-1 3-1 4-5 3h-3l-4 3-3 3v1h6v4h-24l1-1Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M144 77h-1v1h1v-1Zm14 1h-2l-3 1h6l-1-1Zm-2 2-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0h-1v1h1v-1Zm13 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-20 1h-1v1h1v-1Zm-2 0h-3l-1 1h5l-1-1Zm-5 2v-2h-6l-7 1h-3v2h2l1 1h13v-2Zm-2 3h-10 13-3Zm5 15 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l5-3v-5l-5-4v-1h7v1l-1 1h9l2 1 1 1h10l1-2h6l7-5-2-2-1-1h-6v-3l3-2h6l1 2h6v2l5 1v4h-6v1l9-1h3l3 1 1 1h2l-5 1h-5 11v4h-1l-1 3-1 4-5 3h-3l-4 3-3 3v1h6v4h-24l1-1Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="m147 77-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm25 3h-1v1h1v-1Zm-6 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-9 0h1v2l1-1 1-2 5 2-1-1-1-1h-8l-1 3 1-1v-1h2Zm-6 1h-1v1h1v-1Zm-7 0h-3l-1 1h5l-1-1Zm-22 0-1-1v1l-1 1h3l-1-1Zm50 1h-1v1h1v-1Zm-26 0-1-2v4l1-1v-1Zm15 2h-3l-1 1h5l-1-1Zm-22-1v-2h-6l-7 1h-3v2h2l1 1h13v-2Zm-2 3h-10 13-3Zm-18 1v-1h-1l-1 2h1l1-1Zm23 14 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l5-3v-5l-5-4v-1h7v3h1l1 1-2-2h9l1 2h11l1-2h6l7-5-2-2-1-1h-6v-3l3-2h6l1 2h6v2l5 1v4h-6v1l-1 1 2-1h16l1 1-16 1h17v4h-1l-1 3-1 4-5 3h-4l-6 5v2h6v4h-24l1-1Z" style="fill:';
    string private constant PART_8 =
        ';"/><path d="m147 77-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm25 3h-1v1h1v-1Zm-6 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-9 0h1v2l1-1 1-2 5 2-1-1-1-1h-8l-1 3 1-1v-1h2Zm-6 1h-1v1h1v-1Zm-7 0h-3l-1 1h5l-1-1Zm-22 0-1-1v1l-1 1h3l-1-1Zm50 1h-1v1h1v-1Zm-26 0-1-2v4l1-1v-1Zm15 2h-3l-1 1h5l-1-1Zm-22 0v-3h-9l-7 1v4h5l11 1v-3Zm-20 3v-1h-1l-1 2h1l1-1Zm23 14 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l5-3v-5l-5-4v-1h7v3h1l1 1-2-2h9l1 2h11l1-2h6l7-5-2-2-1-1h-6v-3l3-2h6l1 2h6v2l5 1v4h-6v1l-1 1 2-1h16l1 1-16 1h17v4h-1l-1 3-1 4-5 3h-4l-6 5v2h6v4h-24l1-1Z" style="fill:';
    string private constant PART_9 =
        ';"/><path d="m156 71-1-1v1l-1 1h3l-1-1Zm-5 7h-1v1h1v-1Zm-6 0h3v-1h1-7l-1 1-1 2 1-1 2-1h2Zm18 1h1v1h-1v-1Zm6 0v-1h-17 5l5 1 1 1 1 1h2l3-1v-1Zm-24 5 1-1-2-1-1-1-2 1 1 1v2h2l1-1Zm18-2-2-2h-1v4l2-1v3l2-1 1-1-2-2Zm-8 3h-2l-3 1h6l-1-1Zm-16-3v-3 2l-1 2-2 1-1 2 2-1h2v-3Zm-2-1-1-1-1 1-2 2v3l2-2 2-2v-1Zm24 5h-1v1h1v-1Zm-3-5 2 1-2-2h-10l-1 6 1-2 1-3v3l2-4v3h4l1-3v5l1 2v-6h1Zm-46 7 2-2h-1l-4 4h1l2-2Zm38 5h-1v1h1v-1Zm-4 7-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-8 2 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2l4-3v-2l2-1h1-3v-3h-2v-2h4l3 2 2 3v1l-1 1 2 1h9l7 1v-7l-16 2-2-1-1-1 3-1h3-7l-3-2h-5v-1h6l1 2h9l1 2h11l1-2h6l4-3 3-2-2-3h-7v-3l3-2h6l1 2h6v2l5 1v4h-6l-1 2 7-1h10l2 3-1 5-1 5-5 3h-4l-6 5v2h6v4h-24v-1Z" style="fill:';
    string private constant PART_10 =
        ';"/><path d="m157 72-1-1h-2l3 2v-1Zm-14 7-1-1h-1v1l-1 1h3v-1Zm-9 1h-1v1h1v-1Zm-15 0h-8l1 1h7v-1Zm49 2h-1v1h1v-1Zm-31 1-2 3h4v-4l1 2v1l1-1h1v2h3v-5h-3l-3 1v-3l-2 3v-3l-2 2-2 2v3l2-2 1-1h1Zm24-4h1v1h-1v-1Zm-11 5v-1h5v1l-5 1v-1Zm7 0 1-3v3l1 2v-4l-1-4 1 2 1 1v6l2-1h3v-4l-2 1v-2h6v-3h-19l6 1v1h1-9l-1 3v2l1 1v2h4l5-1v-3Zm-21 4h-1v1h1v-1Zm-13-1 9 1v-6h-19l-1 2-1 1 2-1h2v2h-2l-2 2-2 2 2-2 2-1h10Zm27 6-2-1v2h2v-1Zm-3-1-1-1v3l1-1h1l-1-1Zm1 9v-1h-8v1h-1l4 1h4l1-1Zm-13 1 1-2 3-1 3-1 2-1 1-2-1-1-3 3-1-1-1-1 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-8 1v-2h2l1 1v-1l-1-1 4-5v-4 1l-1 2-1-2-2-1v-1l3 1h3l-1-1-1-1h-6v-1h6l1 2h9l1 2h11l1-2h7l1-1v-1l2 1 2 1h3v-2h-5l1-2 2-1-1-2-1-1h-7v-3l3-2h6l1 2h6v1l3 1 2 1v4h-6v1l-1 1 5-1h12l3 3-1 2-1 3v2l-1 3-5 3h-5v1l-1 2h-2l-2 1v3h6v4h-24l1-1Z" style="fill:';
    string private constant PART_11 =
        ';"/><path d="M135 84v-1l1 1 1 1h-3l1-1Zm-22 1v-1h2v2h-2v-1Zm-3 1v-1h2v2l-2 1v-2Zm32-19h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm17 5-2-1-1 1-2 1 2-1h2v2l2-1-1-1Zm-6 1h-1v1h1v-1Zm-17 7h-1v1h1v-1Zm-15 1v-1h-6l3 2h2l1-1Zm49 1h-1v1h1v-1Zm-5-1h1v1h-1v-1Zm-13 3v-1h5v1l-5 1v-1Zm13 2h1v1h-1v-1Zm-6-2 1-3v3l1 2v-4l-1-4 1 2 1 1v6l4 1 1-1v-1l1-3v-2h3v-4l-1 1h-18l6 1 1 1h-8l-3 1 1 2v2l1 2v1h4l5-1v-3Zm-37 5-1-1h-2l-3 1-1 1 4-1h3Zm43 1-1-1v1l-1 1h3l-1-1Zm-9 1h-1v1h1v-1Zm-5 1h1v1h-1v-1Zm2 0-1-1h-2v4l2-1 1-1v-1Zm-4 1-1-2v5l1-1v-2Zm6 8v-1h-12l-1 1h-2l14 1 1-1Zm-18 1v-1l6-2 3-1-1-1 1-1 1-1h-1l-3 2-2-2 1-1 2-2-1 2-1 1 1-1h1v-3h-9l-1-2h-10l-1 1-1 1-15 1 2-2v-1l-1-1h4l-1 2h2l1-3h10l10 1v-3l4 1v1l-1 1-1-1v2h3v-4l2 4v-6l2 1 1 2h3v-5h-3l-3 1v-3l-2 3v-1l-1-2-2 3-2 2v-3l-8 1-8 1-3-2-2-2 1 3v2l-1-1-1-2h-2l-1-1h5l-1-1-1-1-6-1h6l1 2h9l1 2h11l1-2h7l1-1 2-2-2 2-1 2 4-1h4v-2h-5l1-2 2-1-1-2-1-1h-7v-3l3-2h6l1 2h6v1l2 1 3 1v4h-6v1l-1 1 5-1h12l1 1 1 1v3l-1 3-2 2 1-1h1v2l-1 2-2 2-3 1h-5v1l-1 2h-2l-2 1v3h6v4h-24v-1Z" style="fill:';
    string private constant PART_12 =
        ';"/><path d="M108 81h1v1h-1v-1Zm24 2h1v1h-1v-1Zm3 1h1v1h-1v-1Zm-22 1v-1h2v2h-2v-1Zm21 2h1v1h-1v-1Zm9 10h1v1h-1v-1Zm2-30h-6l4 1h4l-2-1Zm-2 2h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm12 1-1-1-3 1v1h6l-2-1Zm6 3v-1l-1-1h-4l-3 1 1 2h4l3-1Zm5 3h-1v1h1v-1Zm-43 5v-1h-6l3 2h3v-1Zm32-2h3l2 1h-7l2-1Zm7 1v-2l1 1 1 1h-1l-1 1v-1Zm-2 0h1v1h-1v-1Zm7 1h1v1h-1v-1Zm-6 2h1v1h-1v-1Zm-5 0h3l1 1h-6l2-1Zm4 6-1-1 2-2 1-2v2l1 2 1-7v7l6-1v-6h3v-4l-10 1h-9l-2 2-1 1v5l1 1 2 2 1-1h2l1 1 2 1v-1Zm-36 0v-1h-6l-1 2h7v-1Zm44 1h-2l-1 1h4l-1-1Zm-4 0h-1v1h1v-1Zm-7 4h-1v1h1v-1Zm-7-3h1v1h-1v-1Zm2 6-1-2v-4l2 5 1-2 1-2h1l1 1 1-1v-1l-4 1-2-2-3-1 1 6 1 2 1 1h2l-2-1Zm-13 5v-1l3-1 3-1 2-1h2v-3l-2-1-1-1-2 1 1 1v1l2-1 1-1-1 2-2 1-2-2 2-2 2-2h-10l-1-2h-10l-1 1-1 1h-8l-7 1 2-1h1l-1-2-1-1h4v-3l2 2-3 3h1v1l2-2 1-2 19 1 1-4v6h3l1-2 1-3 1 5v-5l4 1v2h2v-7h-6v-2l-2 3v-2h-4l2 1-19 2-2-2-3-1v2l-1 1 1-2v-3l-6-1h5l1 2h9l1 2h11l1-2h7l1-1 2-2-2 2-1 2 4-1h4v-2h-5l3-3-1-2-1-1h-7v-3l3-2h6l1 2h6v1l3 1 2 1v4h-6v1l-1 1 5-1h12l1 1 1 1v4h-3l3 2-3 1h1l1 1v2l-1 1-5 3h-5v1l-1 2h-2l-2 1v3h6v4l-15-1h9v-2h-14l-3 1 7 1-4 1h-4v-1Z" style="fill:';
    string private constant PART_13 =
        ';"/><path d="M153 77v-1h3l2 1v1h-6l1-1Zm3 3h1v1h-1v-1Zm7 1h1v1h-1v-1Zm-51-1-2-2h-3l-2-1h4l2 1 1 1h4-2l-1 1 1 1v1l-2-2Zm-2 1h1v1h-1v-1Zm33-14h4-8v2l-1 1 1-1 1-1 3-1Zm9 3v-1h-12l7 1 3 1h2v-1Zm-34 12 3-1-3-1-2-1h4l1 2h11l1-2h7l1-1 2-2-3 4h7l3-4h-7l2-1 2-2 10 1v-2l-1-1h-1l-3 1-4 1-2-2-1-1 1 3h-2v-2h-7v-3l3-2h6l1 2h6v1l2 1 3 1v4h-5l-3 3-4 4-1-1-6-1h-6l3 2h-17l-3 1 2-1Zm35 1v-1l1 1 1 1h-3l1-1Zm-18 1h1v1h-1v-1Zm-21 0v-1l1 1 1 1h-3l1-1Zm52 0v-3h3v-4l-5 1h-5v-2h2l2 1-1-1-1-1 4 1h3l1 1 1 1v4h-3v4h3l-2 1h-2v-3Zm-59 5v-1h3l-1 2h-2v-1Zm39 2-1-2 1 1 1 1v1h-1v-1Zm2 5-1-1 1-2 1 2 1 2-2-1Zm-2 1-1-1-2 3 4-1-1-1Zm-11 5 1-2 3-1 3-1 1-1 2-2-1-1-2-1h-1l-1 1v2l2-1h2l-3 2-2-2 2-2 2-2h-10l-1-2h-10l-2 2h-10l4-4h6l-3 1h-4v2h7v-2h12l1-1v-2 5h3l3-1v-4l2 4v-4l3 3h1v-6l1 2 1 2 1 1 2 2h6l-1 2h-6l-2-1h-1l2-3-2 2-2 2 2 1v4l3 2 2-1v-6l2 4v-4l1 2 1 1 3-3-1-1-2-2 1-1h2l1 1 1-2v-3 5h4v1l-1 1-2-1h-3l1 2h4l3-2 2-1v1l-5 3h-4l-3 2-3 2v3h6v4l-7-1h6v-2h-21l-2 3 1-1Z" style="fill:';
    string private constant PART_14 =
        ';"/><path d="M143 68h7-9 2Zm0 2h3l1 1h-6l2-1Zm-4 0h1v1h-1v-1Zm-2 0v-2l1 1 1 1h-1l-1 1v-1Zm13 1h3v-1l-1-1 5 1-2 1-2 1-6-1h3Zm-6 1h1v1h-1v-1Zm13 2h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm0 2h1v1h-1v-1Zm-8-1 2-2v1h3l1 1h2-1l-1 1h-8l2-1Zm17 2v-1h2l-1 2h-1v-1Zm-3 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-49 0h3l1 1h-6l2-1Zm41 2v-1h1l-1 2h-1l1-1Zm-15 0h1v1h-1v-1Zm-14 0v-1l1 1 1 1h-3l1-1Zm26 1h1v1h-1v-1Zm-9 0-1-1h5v1l-2 1-2-1Zm27 1h1v1h-1v-1Zm-39 0h10-13 3Zm-12-1-1-2 2 2 1 1v1l-2-2Zm-2 1h1v1h-1v-1Zm8 1h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm50 1v-2h3v-3l-1-1-2-1h2l2 2v4h-3v1l-1 1v-1Zm-21 1h1v1h-1v-1Zm21 2v-1l2 1v1h-2v-1Zm-24 1h1v1h-1v-1Zm-24 0v-1l1 1 1 1h-3l1-1Zm-3 0h1v1h-1v-1Zm30 0v-1l4 2h-4v-1Zm-23 1h7l4-1v2h-12l1-1Zm44 1h2l1 1h-4l1-1Zm-7-1v-1h2l1 1v1h-1l-2 1v-2Zm-52 1v-1l2 1v1h-2v-1Zm9 1h3l2 1h-7l2-1Zm-5 1 1-2 1 1v1h-1l-2 1 1-1Zm40 1h1v1h-1v-1Zm-9 3h1v1h-1v-1Zm-2 1-1-2 1 1 1 1v1h-1v-1Zm15 6h1v1h-1v-1Zm-12-12h-1v1h1v-1Zm14 2 1-1v-2l-1-1-3 3 1-1 2-1-1 2-2 1v2h2l1-2Zm-5 6h-1v1h1v-1Zm-6 0v-2l-3 3h2l1-1Zm-10 4v-2l3-1 3-1 1-1 2-1-1-4-2 1v-2l-9-1h6l1-2v-2 4l2-1h1l2 2 1 2v2l3 3 2-1 1-1v-2l-1-1 1 1 1 1 1-4-7-1h7l1-2 2-1 1 2 1 2h6l-3 1h-3l-3 2-4 2 1 2 1 1h6l-7 1h-6l1-2h-2v1l-5 1-5 1v1l-1 1 1-1Z" style="fill:';
    string private constant PART_15 =
        ';"/><path d="M144 68h1v1h-1v-1Zm10 2h2l1 1h-4l1-1Zm-12 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-2 0v-2l1 1 1 1h-1l-1 1v-1Zm12 1h3l1 1h-6l2-1Zm-5 1h1v1h-1v-1Zm13 2h1v1h-1v-1Zm-12 1 2-2v2h6-1l-1 1h-8l2-1Zm17 2v-2l1 1 1 1h-1l-1 1v-1Zm-55 0h3l1 1h-6l2-1Zm40 2h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-23 1h1v1h-1v-1Zm56 1h1v-3l-1-1-2-1h2l2 2v4h-4l2-1Zm-37 0h2l1 1h-4l1-1Zm-6 0v-1l1 1 1 1h-3l1-1Zm-15 0h1v1h-1v-1Zm57 5h1v1h-1v-1Zm-49 1v-1l1 1 1 1h-3l1-1Zm41 1h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-9-1v-1l1 1 2 1h-3v-1Zm-17 1h3l1 1h-5l1-1Zm-8 0h1v1h-1v-1Zm44 1h1v1h-1v-1Zm-57 0h1v1h-1v-1Zm25 1h4l4-1 1 1 1 1h-10v-1Zm-14 0h1v1h-1v-1Zm-2 0v-1l1 1 1 1h-3l1-1Zm-5 0h1v1h-1v-1Zm49 1h3l1 1h-5l1-1Zm-3 0v-1h1l1 1-2 1-1 1 1-2Zm-7 1h1v1h-1v-1Zm3 2-1-1 1-2 2-1-1 2-1 1 1 1 2 1h-3v-1Zm-10 0h1v1h-1v-1Zm-2 1h1v1h-1v-1Zm4 2v-1h1l1 1v1h-1l-2 1 1-2Zm11 2v-1l1 1 1 1h-3l1-1Zm-7-2 3-2h1l-4 4h6l-4 1h-4l2-3Zm-7 1 2-2-1 2-1 2h-2l2-2Zm-5 2h2l1 1h-4l1-1Z" style="fill:';
    string private constant PART_16 = ';"/>';
    string private constant COLOR_1 = "hsl(176, 75%, 74%)";
    string private constant COLOR_2 = "hsl(181, 65%, 56%)";
    string private constant COLOR_3 = "hsl(220, 3%, 63%)";
    string private constant COLOR_4 = "hsl(184, 64%, 47%)";
    string private constant COLOR_5 = "hsl(186, 63%, 45%)";
    string private constant COLOR_6 = "hsl(215, 4%, 52%)";
    string private constant COLOR_7 = "hsl(187, 77%, 35%)";
    string private constant COLOR_8 = "hsl(220, 2%, 45%)";
    string private constant COLOR_9 = "hsl(223, 6%, 43%)";
    string private constant COLOR_10 = "hsl(213, 9%, 37%)";
    string private constant COLOR_11 = "hsl(213, 10%, 24%)";
    string private constant COLOR_12 = "hsl(220, 12%, 20%)";
    string private constant COLOR_13 = "hsl(222, 14%, 18%)";
    string private constant COLOR_14 = "hsl(223, 10%, 14%)";
    string private constant COLOR_15 = "hsl(228, 15%, 13%)";

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
            PART_8,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_8
                )
                : COLOR_8
        );
        string memory chunk3 = string.concat(
            PART_9,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_9
                )
                : COLOR_9,
            PART_10,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_10
                )
                : COLOR_10,
            PART_11,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_11
                )
                : COLOR_11,
            PART_12,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_12
                )
                : COLOR_12
        );
        string memory chunk4 = string.concat(
            PART_13,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_13
                )
                : COLOR_13,
            PART_14,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_14
                )
                : COLOR_14,
            PART_15,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_15
                )
                : COLOR_15,
            PART_16
        );
        return string.concat(chunk1, chunk2, chunk3, chunk4);
    }
}
