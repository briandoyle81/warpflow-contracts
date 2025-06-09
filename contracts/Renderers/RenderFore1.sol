// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderFore1 {
    string private constant PART_1 =
        '<path d="M50 119v-1h-1v1h1Zm-19 0v-1h-1v1h1Zm26 1v-1h-1v1h1Zm4 1v-1h-1v1h1Zm-48-1-1-1v3l1-1v-1Zm16 2v-1h-1v1h1Zm46 2-1-1-1 1h2Zm-25 3h-3l-6 1h13l-4-1Zm-10 1v-1h-1v1h1Zm-4 1v-1h-1v1h1Zm14 1v-1h-1v1h1Zm-7 0-1-1-1 1h2Zm-5 0v-1h-1v1h1Zm35 1v-1h-1v1h1Zm-36 32-4-4h-3l-2-2-2-2-7-1-7-1-1-7-2-2-1-2v-8l-4-5v-8l4-3 4-4h8l8 1 2-3 3-2h13l8-9h17l2 2 2 2 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-4 3h-3l-1 2-1 2H40l-4-4Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="m70 105-1-1-1 1h2Zm-6 0v-1h-1v1h1Zm-3 0-1-1-1 1h2Zm-5-1-2 2-2 1 3-1 2-1-1-1Zm-4 5-1-1-1 1h2Zm32 6v-1h-1v1h1Zm-55 3v-1h-1v1h1Zm51 0 1-2-1-1-1 2-1 2h2v-1Zm-21 0h-1l-1 1-1 1h1l2-1v-1Zm-4 3v-1h-1v1h1Zm-4 1-1-1v-3h-1v3l1 1h3-2Zm-4 0-1-1-1 1h-1 3Zm-14-7v-1h1l-1 2h-1l1-1Zm1 3 3-4-4-1-1 2v1l-1 1-2 3-2 2h5l2-4Zm-13 3v-1h1v1h-1Zm-3-1v-1h2v2h-3v-1Zm-4 1v-1h1v1h-1Zm-3 0v1h13v-2l1-1v-2l-9 1v-2l-3 3h-1l1-2-2 1-2 2-1 3 4-4-1 1Zm64 0h4l-3-1h-3l6-5h-3l-36-1-3 3-3 3v2h9l-5-2h5v-2l1 1v1h4v-3l11-1h4l3-1v2l-2 1h-2 5v-3l5 2v2h-7l1 2h2l3-1-2 1h-1l1 1v1l1-1 1-1h4Zm-12 1-1-2h-2l3 3h1l-1-1Zm12 2-1-1-1 1h-1 5-2Zm-10 1v-1h-1v1h1Zm-2 1v-1h-1v1h1Zm-47 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm63 1v-1h-1v1h1Zm-22 0v-1H39v2h15l1-1Zm-33 0v-1h-1l-1 2h2v-1Zm-3 1-1-1-1 1h-1 3Zm-5 0-2-1-4 1h8l-2-1Zm15-3-1-1v6l1-2v-3Zm24 5-1-1-1 1h2Zm-5-1h-5l-2 1h10l-3-1Zm-9 1-1-1-1 1h2Zm36 1-1-1-1 1h-1 5-2Zm-41-2v-1h1v1h-1Zm1-1v-1l1 1h2v-2h-3l-1 2-1 1 1 1v1l1-1 1-1-1-1Zm7 4v-1h-1v1h1Zm-13 2v-1h-1v1h1Zm37 4-1-1-1 1h-1 5-2Zm-49 4v-1h-1v1h1Zm-2-1v-1h-3v2h3v-1Zm1 7v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm24 16-3-4h-2l-3-1-2-2-3-3h-6l-1-1v-1l-2 1h-2l-2-1-1-1v-5l-2-2-1-2v-10H7l-2-1v-11l4-3 3-3h8l8 1 2-3 3-2h13l8-9h17l2 2 2 2 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-3 4H40l-2-3Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="m70 105-1-1-1 1h2Zm-6 0v-1h-1v1h1Zm-3 0-1-1-1 1h2Zm-5-1-2 2-2 1 3-1 2-1-1-1Zm-4 5-1-1-1 1h2Zm32 6v-1h-1v1h1Zm-55 3v-1h-1v1h1Zm51 0 1-2-1-1-1 2-1 2h2v-1Zm-21 0h-1l-1 1-1 1h1l2-1v-1Zm-4 3v-1h-1v1h1Zm-4 1-1-1v-3h-1v3l1 1h3-2Zm-4 0-1-1-1 1h-1 3Zm-14-7v-1h1l-1 2h-1l1-1Zm1 3 3-4-4-1-1 2v1l-1 1-2 3-2 2h5l2-4Zm-13 3v-1h1v1h-1Zm-3-1v-1h2v2h-3v-1Zm-4 1v-1h1v1h-1Zm-3 0v1h13v-2l1-1v-2l-9 1v-2l-3 3h-1l1-2-2 1-2 2-1 3 4-4-1 1Zm64 0h4l-3-1h-3l6-5h-3l-36-1-3 3-3 3v2h9l-5-2h5v-2l1 1v1h4v-3l11-1h4l3-1v2l-2 1h-2 5v-3l5 2v2h-7l1 2h2l3-1-2 1h-1l1 1v1l1-1 1-1h4Zm-12 1-1-2h-2l3 3h1l-1-1Zm12 2-1-1-1 1h-1 5-2Zm-10 1v-1h-1v1h1Zm-2 1v-1h-1v1h1Zm-47 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm63 1v-1h-1v1h1Zm-22 0v-1H39v2h15l1-1Zm-33 0v-1h-1l-1 2h2v-1Zm-3 1-1-1-1 1h-1 3Zm-5 0-2-1-4 1h8l-2-1Zm15-3-1-1v6l1-2v-3Zm24 5-1-1-1 1h2Zm-5-1h-5l-2 1h10l-3-1Zm-9 1-1-1-1 1h2Zm36 1-1-1-1 1h-1 5-2Zm-41-2v-1h1v1h-1Zm1-1v-1l1 1h2v-2h-3l-1 2-1 1 1 1v1l1-1 1-1-1-1Zm7 4v-1h-1v1h1Zm-13 2v-1h-1v1h1Zm37 4-1-1-1 1h-1 5-2Zm-53-2v-1h1v1h-1Zm2-2 1-4h-4l1 2 1 2-1 1-1 2v1h1l1-1v3-1l1-1v-4Zm2 8v-1h-1v1h1Zm-2-1v-1h-3v2h3v-1Zm1 7v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm24 16-3-4h-2l-3-1-2-2-3-3h-6l-1-1v-1l-2 1h-2l-2-1-1-1v-5l-2-2-1-2v-10H7l-2-1v-11l4-3 3-3h8l8 1 2-3 3-2h13l8-9h17l2 2 2 2 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-3 4H40l-2-3Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M68 104h-6l-3 1h12l-3-1Zm-14 3 3-3h-2l-3 3-2 2h1l3-2Zm-17 6v-1h-1v1h1Zm47 2v-1h-1l-1-1v1l1 1h1Zm-53 2 1-2h-2l-2 3h2l1-1Zm28 2v-1h-2l-1 2h2l1-1Zm-4 2v-1h-1l-1-1v1l1 1h1Zm3 1v-1h-1v1h1Zm-7-1h-1v-2l-1-1v4h4l-2-1Zm-33-1v-1h2v2h-2v-1Zm6 1v-1l1-3h-2l-2 1-3-1-2-1-2 2-2 2 1-2 2-2-3 2-4 3v1h16v-1Zm51-2v-1h1v1h-1Zm-32 1 1-2v5l4-2v-3h1l1-1 8-1h8l-3 2h4v-3l2 1h3v3h-7l4 4h2v-2h7v-1l-1-2 2 1 1 1v-2l-1-2 1 1h1v-3H50l-1-1-1-1v2h-8l-6 6v3l4-1h5v-2Zm32 4-1-1-1 1h-1 5-2Zm-10 0v-1l-2-1-1-2h-2l5 5v-1Zm-2 2v-1h-1v1h1Zm-47 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm64 0v-1h-1l-1 2h1l1-1Zm-23 1v-1H39v2h15l1-1Zm-33 0h-6v1h6v-1Zm-9 0h-2l-4 1h9l-3-1Zm44 2v-1h-1v1h1Zm-26-7h1l1-3 2-3 2-1 1-1h-4l1-2-1 1-2 1-1-1v1l1 1h1l1-1-3 4-4 4 1 8 1-8h2Zm22 8-1-1-1 1h2Zm-14 0-1-1-1 1h2Zm36 1-1-1-1 1h-1 5-2Zm-22 1v-1h-1v1h1Zm-6-2h3l-9-1v4l1-1 1-2h4Zm-10-2h1v-2h-3l-1 2-1 1 1 2v1l2-4h1Zm3 5v-1h-1v1h1Zm-10 1-1-1-1 1h2Zm36 4-1-1-1 1h-1 5-2Zm11 1v-1h-1v1h1Zm-64-3v-1h1v1h-1Zm2-2 1-4h-4l1 2 1 2-1 1-1 2v1h1l1-1v3-1l1-1v-4Zm14 7-1-1v3l1-1v-1Zm-11 0-3-1h-3v2h6v-1Zm-2 7v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm24 16-3-4h-2l-3-1-2-2-3-3h-6l-1-1-1-1h-6v-7l-2-1-1-1v-11H6l-1-1v-11l4-3 3-3 16 1 2-3 3-2h13l8-9h17l2 2 2 2 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-3 4H40l-2-3Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M68 104h-6l-3 1h12l-3-1Zm-14 3 3-3h-3l-2 3-2 2h1l3-2Zm21 6-1-1-1 1h2Zm-21 0-1-1-1 1h-1 3Zm32 1v-1h-1v1h1Zm-2 1v-1h-1l-1-1v1l1 1h1Zm-26 7v-1h-1v1h1Zm-4-2-1-1 1 1v2h1v-1l-1-1Zm21 4-1-1-1 1h-1 5-2Zm-10-10 1-1 1 1h-2Zm-6-1h2l1 1h2-6l1-1Zm-16 7v-2l1 1v2h-1v-1Zm31 1h3l4-4v-4l-2 1-1 1 1-3-2 1-2 1h-7l4-2H55l3 2h-7l-1-1-1-1-1 1-1 2v-3h-5l-8 8v3h18v-2h-2v-3l-2 4v-2l1-2 2-1 3-1h8l1 2h4v-3l3 1h2v3h-7l6 5v-3h3Zm-42 3-1-1v3l1-1v-1Zm39 2v-1h-1v1h1Zm-6-1 1-1-1-1-2-1-2-2-3-2-1 1-1 1h4l2 2 2 2-2 2h2l1-1Zm12 1 1-1-1 1-2 1v1h1l1-2Zm-3 2v-1h-1l-1-1v1l1 1h1Zm-54-6-2-2v-1h2l1 2 1 2h-1l-1-1Zm-6 1v-1h1v1h-1Zm3 0v-1h1v2h-2v-1Zm-9 1v-1l1 1v1l-1 1v-2Zm2 1 1-3h1l2 2 1 1v1l-2-1v2H8l2-2Zm12 2v-1l-3 1h-3v-2l2 1 1-1v-2h2l1 1 2-3 1-3-1-1v-1l-2 2-5-1-4-1-6 6v6h15v-1Zm35 2-1-1-1 1h2Zm-28-10v-1h1v1h-1Zm2 9v-1l-1-2-1-1 2-2 2-3 3-2 2-3 1-1v-1h-6v2h1l1-1v1l-1 1-1-1-1-1-2 3-2 2v3h-3l2 1h1v7h3v-1Zm22 2-1-1-1 1h2Zm-14 0-1-1-1 1h2Zm36 1-1-1-1 1h-1 5-2Zm-22 1v-1h-1v1h1Zm-3 0-1-1-1 1h2Zm-4 0v-1h-1l-1 2h1l1-1Zm-4 0v-2h9l-5-1h-5v3l1 1h1l-1-1Zm-2 1v-1h-1v1h1Zm24 1v-1h-1v1h1Zm-19-6h8l2-2H35l-1 2-1 1 1 3v3l2-6 8-1Zm9 7v-1h-1v1h1Zm14 1v-1h-1v1h1Zm-25 0v-1h-1v1h1Zm-5-1 1-1h-1l-1-1v3h1v-1Zm38 2v-1h-1v1h1Zm-10 1-1-1-1 1h-1 5-2Zm12 0v-1h-1l-1 2h1l1-1Zm-65-2v-1h1v1h-1Zm2-2 1-4h-4l1 2 1 2-1 1-1 2v1h1l1-1v3-1l1-1v-4Zm14 3 1-4h-2v10l1-1v-5Zm-11 4v-1h-6v2h6v-1Zm18 3v-1h-1v1h1Zm-3 1v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm13 1v-1h-1v1h1Zm-27 2v-1h-1v1h1Zm-2 0-1-1-1 1h2Zm24 16-3-3-6-3-1-2-2-2h-7l-1-1v-1h-6l-1-7-2-1-1-1v-11H7l-2-1v-11l4-3 4-3 15 1 2-3 3-2h13l8-9h17l2 2 2 2 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-1 2-2 2H40l-2-3Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M74 107v-1h-1v1h1Zm-13 0v-1h-1v1h1Zm5 1-1-1-1 1h-1 5-2Zm-12-1 2-2h14v-1l-1-1-14 1-4 3v1l-1 1h2l2-2Zm5 2 1-1-1 1h-2v1h2v-1Zm27 5-1-1v3l1-1v-1Zm-2-2h-2v1l1 1v2l1-2v-2Zm0 5h-1l-2 1 1 2 2-2v-1Zm-2 5-1-1-1 1h2Zm0 2-1-1-1 1h2Zm-14 1v-1h-1v1h1Zm13 2-1-1v3l1-1v-1Zm-25-8v-1h1v1h-1Zm10 7v-2l-4-3-2-2-1-1 4 2-1-1-1-1h-3l-4-1 1 1v1h-2l1 2v2l2-2 2 2 3 2 1-3 1 1 1 1-1 1-1 1h4l-2 1-1 1h1l2-1v-1Zm-48-6v-1h2l-1 2h-1v-1Zm-7 5v-1h1v1h-1Zm9 1 1-1 1 1h-4l2-1Zm-6-1-1-1h2v2h-1l-1-1Zm10-1v-3l1-2v-3H12l-3 2-2 3v7h17v-4Zm32 7v-1h-1v1h1Zm20 0v-1l-4-1v3h4v-1Zm2 3-1-1v3l1-1v-1Zm-12 2-1-1-1 1h2Zm9 1-1-1-1 1h-1 5-2Zm-32-6 1-1 1 1h-4l2-1Zm6 0-2-1h4l1 2h-2l-1-1Zm-10 0v-1l2-1v3h-2v-1Zm4 3v-1h1v1h-1Zm10 2 1-2v-2l-1-2 1-2 1-1v2h2l-2-4H37l-4 3v7h2v-3l1-3 2-1-1 3v3l1 3h14l1-1Zm-32 1v-1h-1v1h1Zm-8-1v-1h1v1h-1Zm2-2 1-4h-4l1 2 1 2-1 1-1 2v1h1l1-1v3-1l1-1v-4Zm8 7v-1H11l1 1v1h11v-1Zm28-27v-1h1v1h-1Zm-12 0v-1h1v1h-1Zm9 5v-1l1 1v1l-1 1v-2Zm-5 2v-1h1v1h-1Zm33 3v-2l-4 1v2h4v-1Zm-5 0v-3h7v5h-7v-2Zm-7 15 1-1 1 1h-2Zm8 3v-1h2l1-1-1 1v1h-2Zm-3 2 2-1 1 1 1 1h6v-2l-1-2v-3h-7v-10h4l4 1v-8l2-5v-4H49l-1 1-1 2v-3H33l-5 5v3h-1l-1-1v10h6v-7l2-3 1-3h2l-1 2-2 2v4h9v-2l2 2h7v-3h-2v-4l2 4v-4h2l1-1h7l1 2h4v-3l2 1h3v3h-7l4 5v2l1 3-2 2-1 1h-7v4h2v-2h5v3h-4v8h4l2-1Zm-7-3v-4l-2 1v3l-2 2-2 2h6v-4Zm8 5v-1h-1v1h1Zm-16-1v-1H38v1l1 1h15v-1Zm-20-1h1v1l-1 1h1l2-1v-2h-2l-2-2-2-2v-8l-3 2v-2h-2v12l3 2 3 1 1-1v-1h1Zm-11 5v-1h-1v1h1Zm-8-2-2-2v1l-1 2 1 1v1l3-2-1-1Zm57 11v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm15 1v-1h-1l-1 2h2v-1Zm-32 0-1-1v3l1-1v-1Zm-3 0-1-1v3l1-1v-1Zm-2 0v-1h-2l-1-1 1 2 1 1h1v-1Zm-3 5-1-3-7-3-1-2-2-2h-7l-1-1v-1h-6l-1-7-2-1-1-1v-11H7l-2-1v-11l4-3 4-3 15 1 2-3 3-2h13l8-9h17l4 4 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-2 3H39l-2-2Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="M74 107v-1h-1v1h1Zm-13 0v-1h-1v1h1Zm5 1-1-1-1 1h-1 5-2Zm-12-1 2-2h14v-1l-1-1-14 1-4 3v1l-1 1h2l2-2Zm5 2 1-1-1 1h-2v1h2v-1Zm27 5-1-1v3l1-1v-1Zm-2-2h-2v1l1 1v2l1-2v-2Zm0 5h-1l-2 1 1 2 2-2v-1Zm-2 5-1-1-1 1h2Zm0 2-1-1-1 1h2Zm-14 1v-1h-1v1h1Zm13 2-1-1v3l1-1v-1Zm-25-8v-1h1v1h-1Zm10 7v-2l-4-3-2-2-1-1 4 2-1-1-1-1h-3l-4-1 1 1v1h-2l1 2v2l2-2 2 2 3 2 1-3 1 1 1 1-1 1-1 1h4l-2 1-1 1h1l2-1v-1Zm-48-6v-1h2l-1 2h-1v-1Zm-7 5v-1h1v1h-1Zm9 1 1-1 1 1h-4l2-1Zm-6-1-1-1h2v2h-1l-1-1Zm10-1v-3l1-2v-3H12l-3 2-2 3v7h17v-4Zm32 7v-1h-1v1h1Zm20 0v-1l-4-1v3h4v-1Zm2 3-1-1v3l1-1v-1Zm-12 2-1-1-1 1h2Zm9 1-1-1-1 1h-1 5-2Zm-32-6 1-1 1 1h-4l2-1Zm6 0-2-1h4l1 2h-2l-1-1Zm-10 0v-1l2-1v3h-2v-1Zm4 3v-1h1v1h-1Zm10 2 1-2v-2l-1-2 1-2 1-1v2h2l-2-4H37l-4 3v7h2v-3l1-3 2-1-1 3v3l1 3h14l1-1Zm-32 1v-1h-1v1h1Zm-3-3v-4h-6v8l-1 1h6l1-5Zm5 7v-1H11l1 1v1h11v-1Zm28-27v-1h1v1h-1Zm-12 0v-1h1v1h-1Zm9 5v-1l1 1v1l-1 1v-2Zm-5 2v-1h1v1h-1Zm33 3v-2l-4 1v2h4v-1Zm-5 0v-3h7v5h-7v-2Zm-7 15 1-1 1 1h-2Zm8 3v-1h2l1-1-1 1v1h-2Zm-3 2 2-1 1 1 1 1h6v-2l-1-2v-3h-7v-10h4l4 1v-8l2-5v-4H49l-1 1-1 2v-3H33l-5 5v3h-1l-1-1v10h6v-7l2-3 1-3h2l-1 2-2 2v4h9v-2l2 2h7v-3h-2v-4l2 4v-4h2l1-1h7l1 2h4v-3l2 1h3v3h-7l4 5v2l1 3-2 2-1 1h-7v4h2v-2h5v3h-4v8h4l2-1Zm-7-3v-4l-2 1v3l-2 2-2 2h6v-4Zm8 5v-1h-1v1h1Zm-16-1v-1H38v1l1 1h15v-1Zm-20-1h1v1l-1 1h1l2-1v-2h-2l-2-2-2-2v-8l-3 2v-2h-2v12l3 2 3 1 1-1v-1h1Zm-11 5v-1h-1v1h1Zm-8-2-2-2v1l-1 2 1 1v1l3-2-1-1Zm57 11v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm15 1v-1h-1l-1 2h2v-1Zm-32 0-1-1v3l1-1v-1Zm-3 0-1-1v3l1-1v-1Zm-2 0v-1h-2l-1-1 1 2 1 1h1v-1Zm-3 5-1-3-7-3-1-2-2-2h-7l-1-1v-1h-6l-1-7-2-1-1-1v-11H7l-2-1v-11l4-3 4-3 15 1 2-3 3-2h13l8-9h17l4 4 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-2 2-2 1h-3l-2 3H39l-2-2Z" style="fill:';
    string private constant PART_8 =
        ';"/><path d="M74 108v-2h-2v3h2v-1Zm-4-1-1-1h-1v1l1 2v1l2-2-1-1Zm-3 1v-2h-4v2h1l2 1h-6l1-3h-2v3l-1 1h-1 10v-2Zm-11 0 1-2h-1l-1-1h16l-1-1v-1H55l-3 3-3 2v2h6l1-2Zm-36 18v-1h1v1h-1Zm4 2v-12l-5-1h-6l-7 6 1 4v4l8-1h9Zm-6 10v-8h-6v8l-1 1h6l1-1Zm6 4v-1l-1-1v-2l-1 1-1 2v-5l2 1 1-6h-4v8l-2 1h-8v3l13-1h1Zm48 4v-1h-1l-1-1v1l-1 1h3Zm9-30v-3h1l2 4-1-2-2 2-1 2 1-3Zm-46 2v-1h1v1h-1Zm35 0v-1h-1v1h1Zm-3-1v-1h3l1 1 1 2h-5v-2Zm-19 2v-1h1v1h-1Zm11 0v-1l1 1h1v1h-1l-1-1Zm-9 1v-2l1 1v2h-1v-1Zm-17 1v-1l1 1v1l-1 1v-2Zm46 1v-2h2l-1 2v1h-1v-1Zm-8 0v-1h6v1l1 1h-6l-1-1Zm-38 2v-1h1v1h-1Zm43 1v-1l1 1v1l-1 1v-2Zm-10 0v-1l1 1v1l-1 1v-2Zm13 1v-1l1 1v1l-1 1v-2Zm-29 5v-2l2 1v2h-2v-1Zm-10 0-1-1h2v2h-1l-1-1Zm-12 2v-1h1v1h-1Zm43-1v-1l1 1v1h4v-4h-2l-3 1 1-1v-1h5l1 4h3l-4 2h-6v-2Zm8 3v-1h1v1h-1Zm-44-1v-1l1 1v1l-1 1v-2Zm42 3v-1h1v1h-1Zm-14 0-1-1 1-1v-1h2l-3 2 5-1v2h-4Zm10 1 1-1 1 1h-2Zm-2-1v-2h5l-2 1h-1l-1 2-1 1v-2Zm-6-7v-1h-1v1h1Zm-7 11v-1h-1v1h1Zm-23 0-3-2v-7l1 2v3h1l1-1v2l1 1h1v-3l2 2 13-1 1-1 1-1v-7l1 4 1 4-2 3 1-2 2-1 1-9-2-1-1-1H37l-3 2-2 1v-2l4-2h16v-5l2-3h8l7 8v7h-1l-1-1v2h-5v-2l-4-5-3-4h2l1 2 1 2h2l3 4 4-3v-2l-4-4-4-3-2 1-2 1 1-1v-1h-2l-1 1-1 2v2l3 3 3 3v12l-1 2h-2l-10 1h-9l-2-2Zm21 3v-1h1v1h-1Zm-6 0 1-1 1 1h-2Zm-2 0v-1h1v1h-1Zm-5 0v-1h1v1h-1Zm11 1v-1l1 1 2 1h10l2-1 1-2 2 2 2 1h5v-9l1 8 2 2v-25l2-3 2-4v-3H33l-4 4-4 4v23h2v2l-1 1h8v1h20v-2Zm-34 4v-1h2v2h-2v-1Zm4 0v-2l-1-2-2 1-1 2 1-3h-2v6h5v-2Zm-10-2v-1h1v1h-1Zm2 1h1l-1-1v-2h-4v2l1 5 1-2v-2h2Zm66 4-1-1v3l1-1v-1Zm-47-3-1-1v6l1-2v-3Zm41 7v-1h-1v1h1Zm-3 0-1-1-1 1h2Zm-5 0v-1h-1v1h1Zm-2 2v-1h-1v1h1Zm11 1v-2h-2v3h2v-1Zm-3 0v-2h-7l1 1h2v2h4v-1Zm-9 1-1-1-1 1h2Zm-22-1v-2h-6l2 3h4v-1Zm26 1v-1h-2l1 2h1v-1Zm-7 2-1-1-3 1h6-2Zm-11-1h-6l17-1v-3H44v4l1 1h13l-7-1Zm-14 3-1-3-7-3-1-2-2-2h-7l-1-1v-1h-6l-1-7-2-1-1-1v-11H7l-2-1v-11l4-3 4-3 15 1 2-3 3-2h13l8-9h17l4 4 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-4 3h-3l-2 3H39l-1-2Z" style="fill:';
    string private constant PART_9 =
        ';"/><path d="M74 108v-2h-2v3h2v-1Zm-7 0v-2h-4v1l-1 1-2-3h7l1 2v2h-1v-1Zm-10-1-1-2h3v4h-2v-2Zm14 2v-2l-1-1-1-1h2v-2H55l-8 7h23l1-1Zm-47 19 1-13H12l-5 6-1 3v4h1v1l8-1h9Zm60 1-1-1v4l1-1v-2Zm-67 10 2-1v-8h-8l1 4 1 3-2 1-2 1h8Zm67 5v-1h-1v1h1Zm-63-5v-1h1v1h-1Zm-5 4 3-1h5v-11h-4v7l-2 2h-8v3h1v1l2-1h3Zm68 3v-1h-1v1h1Zm0 2v-1h-1v1h1Zm-54 1v-1h-1v1h1Zm-3 0v-1h-2v2h2v-1Zm-13-2v-1h1v1h-1Zm2 1h1l-1-1v-2h-4v2l1 5 1-2v-2h2Zm17 2v-2h-2v3l1 1h1v-2Zm-7 2v-1h-1v1h1Zm-5-3v-1h1v2h-2v-1Zm3-1v-3h-5v7l3-1h2v-3Zm60 3v-2l-2 4v-6h-2v5l1 1h2l1-2Zm-3-35 1-2 2 1v2l-1-1v-1l-2 2-1 2 1-3Zm-46 2v-1h1v1h-1Zm32 0v-2h3l1 3-1-1v-1l-3 2v-1Zm-11 1v-1h1v1h-1Zm-8 0v-1h1v1h-1Zm11 0v-1l1 1h1v1h-1l-1-1Zm21 2v-1h1v1h-1Zm-30-1v-2l1 1v2h-1v-1Zm24 2v-1h1v1h-1Zm-41 0v-1h1v1h-1Zm43 0v-1l1 1h1v1h-1l-1-1Zm-5 0v-1l1 1h1v1h-1l-1-1Zm-5 3v-1l1 1v1l-1 1v-2Zm-12 4v-1h1v1h-1Zm-4 2v-2l2 1v2h-2v-1Zm-11 0v-1l1 1h1v1h-1l-1-1Zm32 2v-1l3 1h2v-4h-2l-2-1 3 1h3v5h-7v-1Zm2 3 1-1 1 1h-2Zm-2 0v-1h1v1h-1Zm-5 0v-1l1 1v1l-1 1v-2Zm-23 3-1-1-1 1h2Zm-8 1-3-1v-6l1 4 2 1 1 2h1l1-1v-1l-1-2 1 1 1 1h4l3-1-1 1v1h3l3-1 4-4v3l-1 3 1-2 2-2v-4l1-5-2-1-1-1H36l-3 3-1-1 1-1 2-2h17v-5l2-3h8l7 8v5l-3 3h-4v-2h5l-3-1h-3l-6-8h1l7 7h5v-4l-4-4-3-3-7 1-1 2v2l3 3 3 3-1 12v2H37l-2-2Zm21 4v-1h1v1h-1Zm14 0v-1l1 1h1v1h-1l-1-1Zm3 3v-1h2l-1 2h-1v-1Zm-20 0 2-2v1h1l-1 1v1h-3l1-1Zm-9 1v-1h1v1h-1Zm-7-1h4l1 1h-7l2-1Zm31 4v-1h-1v1h1Zm-2 0-1-1h1l2-1 1 2 1 1h-3l-1-1Zm-4 0v-3l-5-2 10 1 1-2 1-1v3h1l2-1v4h-2l-2-3-3 1h-2v3l1 1 1 1h13l-1-2v-3l1-1 1-2 2 1h1v-25l4-5v-4H32l-3 4-4 4v24l1 1 1 2h6v-1l1-1v8h28v-2Zm-32 1-1-1h-2l3 2h2l-2-1Zm12 4-1-1-1 1h-1 3Zm35 4v-5h-5l-5 1h8v2l-4-1h-4l2 1 2 2h2l3 1 1-1Zm-8 0v-1h-2l1 2h1v-1Zm5 2v-1h-2v2h1v-1Zm-3 1v-1h-1v1h1Zm-12 1-1-1-1 1h-1 5-2Zm-13-3 2-1h2l2 1h-7 1Zm-7 0 1-1 1 1h-2Zm4 1-1-2h2v3h20l-1-1-1-1H51l7-1h7l-3-2h4v-3H55l-12 1 22 1H35v1l1 1h1l1-1-1 2 4 4h1l1-1v-1Zm-6 2-1-3-7-3-1-2-2-2h-7l-1-1v-1h-6l-1-7-2-1-1-1v-11H7l-2-1v-11l4-3 4-3 15 1 2-3 3-2h13l8-9h17l4 4 1 2 1 3h10v11l-2 1v32l-2 1-2 2v3l-4 3h-3l-2 3H39l-1-2Z" style="fill:';
    string private constant PART_10 =
        ';"/><path d="M14 140v-1h1v1h-1Zm60-33v-2l-2 1v4l2-1v-2Zm-11-1 1-1 1 1h-2Zm-3 0v-1h1v1h-1Zm-3 0 1-1 1 1h-2Zm10 1-1-2 1 1 1 1-1 3v-3Zm-9 2v-1h1v1h-1Zm13-2v-4h-5l-4-1-7 1-4 4-3 3h23v-3Zm-57 42v-1h1v1h-1Zm3 1 1-3v-2h-6l1 6h4v-1Zm4-1v-1h1v2h-2v-1Zm3-1v-3h-5v7h4l1-4Zm44-31v-1h1v1h-1Zm-12 2v-1h1v1h-1Zm-6 2v-1h1v1h-1Zm32 1v-1l1 1v1l-1 1v-2Zm-22 4-2-2 3 3 2 1 1 1h-3l-1-3Zm-6 3v-1h1v1h-1Zm8 2v-1h4l-1-1v-1h1l1 1 1-3v-2l-4-4-3-3-7 1-1 2v2l2 3H36l-2 2-2 1v-1l2-1 1-2h17v-5l2-3h7l4 4 4 3v6l-2 1-1 2h-3l-1-1Zm-12 0v-2l2 1v2h-2v-1Zm-11 0v-1l1 1h1v1h-1l-1-1Zm32 2v-1l3 1h2v-4h-2l-2-1 3 1h3v5h-7v-1Zm11 2v-2l1 1v2l-1 1v-2Zm-11 1v-1h1v1h-1Zm-5 1v-1h1v1h-1Zm-13 1v-1h1v1h-1Zm29 2v-1l1 1v1l-1 1v-2Zm-38 1h-8l-4-3 1-1 4 4 1-1v-1h18l1-7 1-5h-2v-2l3 2v11l-2 2-2 2h-3l-8-1Zm38 2v-1h1v1h-1Zm-14 2v-1h1v1h-1Zm-14 1v-1h1v1h-1Zm14 1v-1h1v1h-1Zm14 0v-2l1 1v2l-1 1v-2Zm-28 1v-1h1v1h-1Zm16 1 1-1 1 1h-2Zm12 2v-1h1v1h-1Zm-3-1v-3l1 3v3h3l1-14v-14l-1 1-1 1 1-2 1-2v-2l-1-2h3v-7H33l-8 8v25l4 4 4 3v-3l1-4v8h45v-3Zm-50 1-2-3h-2v4l1 1h5l-2-2Zm45 6v-1h1v1h-1Zm-6 2v-1h1v1h-1Zm4 5 2-1v-3l1 1 2 1 1-1v-4l-1-2h-5l-5-1v10h5Zm-24-7v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm8 5v-2l1 2v2h21l-1-6h2v-3H44v2h-2l1-2H30l1 2h3l-1 1v1h1l1-1 5 6h3v-2Zm-6 2-1-3-3-1-3-2-2-2-2-2h-6l-2-1-1-1h-3l-3-1v-6l-1-1-2-1v-10l-2-2-1-1v-10l4-3 3-3h2l-4 4-4 3v4l1 4 5-1h5l-3 1-2 1-2 9 2 1h-1l-1 1v2l1 1h2l2-1h9v-13h-4v8l-2 2h-2l1-1 2-1v-8h-2v-2h7v-7l1-3v-3l-10-1 13 1 2-3 3-2h13l4-4 5-5h16l3 4 2 2 1 3h10v11l-2 1v31l-3 3h-2l1 4-4 3h-3l-2 3H39l-2-3Z" style="fill:';
    string private constant PART_11 =
        ';"/><path d="M60 106v-1h1v1h-1Zm-13 4v-1l7-7 1 1-4 4-4 4v-1Zm-35 5v-1h1v1h-1Zm45 2v-1h1v1h-1Zm3 0-1-1h2l1 2h-1l-1-1Zm-4 2v-1h1v1h-1Zm20-10v-1h-1v1h1Zm-51 8v-3l1 1h1l-1 1v2l7-8h38v-8l2 1 2 2h-2l-1 1v4h1l3-3 1 1v2h10v8l-2-6H32l-7 8v-3Zm39 3v-1h1v1h-1Zm-56-2 1-2h2l-4 4H6l2-2Zm42 3v-1h1v1h-1Zm34 0v-1l1-1 2-1v2l-1 2h-2v-1Zm-18 1v-1l1 1h1v1h-1l-1-1Zm-16 3 3-1-1-5 1-1 1-2h2l-3 2v7h-6 3Zm-12 0 2-1 2 1h2-7l1-1Zm-4 1 1-2h1l-3 4h-1l2-2Zm-10-2v-4l1 4-1 5v-5Zm-11 5v-1h1v1h-1Zm54 1 1-1v-3l1-2v6h-3 1Zm9 0v-1l-4-1h5v3h-1v-1Zm-12 1v-1h1v1h-1Zm-25 0v-1h1v1h-1Zm32 3v-1h6v1h-6Zm-13-3v-3l-1-2-2-1 2 1 2 1v6l-1 1h-1l1-3Zm26 0v-8l1 4v4l-1 8v-8Zm-52 7v-1l1 1h1v1h-1l-1-1Zm-14 1v-1h1l-1 2h-1l1-1Zm-7 1v-1h1v1h-1Zm43 1 3-2 3-2-2 2-2 2h-2Zm-11 0v-1h1v1h-1Zm41 2v-4l1 4-1 5v-5Zm0 7v-2l1 1v2l-1 1v-2Zm-71 2v-1h1v1h-1Zm71 1v-1h1v1h-1Zm-17 1 1-1 8 1h-5l-5 1 1-1Zm-29 0h-5l-8-7v-2l4 4 4 4 33 1-22 1-6-1Zm-12 1-2-2-5 1-1-1v-8h-6v7l-1-6-3-3v-6l1-6-1 1H7l-2-4v-4l1-3v8h6l-1 3v3h-1l-1-1v4l1 4 1 1v2l1-1h11l1-7v-7h-4v4l-1 4v-9h-2 8l-1 16h-5v4l-1 3 1 1 2-1h3v-3l1 2 1 2h4l-1 1h-1l1 1v1h-1l-2-1Zm53 2-1-1 2-1 2-1-3 1h-2v-2h3l2 1 1 2h-3l1 2h-2v-1Zm-45 2v-1h-1v1h1Zm-3 0-2-1 2-1h3v1l1 1-1 1-3-1Zm4 2v-1h1v1h-1Zm42 1v-1l3-2v1l-3 3v-1Zm-39 3-1-2v-1l6 3h23v-1h-1l2-4v5h3l2-1 3-2-1 2-2 2H40l-2-1Z" style="fill:';
    string private constant PART_12 = ';"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(197, 34%, 48%)";
    string private constant COLOR_3 = "hsl(39, 6%, 43%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(220, 2%, 37%)";
    string private constant COLOR_6 = "hsl(223, 6%, 24%)";
    string private constant COLOR_7 = "hsl(213, 9%, 20%)";
    string private constant COLOR_8 = "hsl(213, 10%, 18%)";
    string private constant COLOR_9 = "hsl(223, 10%, 13%)";
    string private constant COLOR_10 = "hsl(224, 12%, 14%)";
    string private constant COLOR_11 = "hsl(225, 17%, 9%)";

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
            PART_12
        );
        return string.concat(chunk1, chunk2, chunk3);
    }
}
