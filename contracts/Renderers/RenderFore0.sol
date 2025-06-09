// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderFore0 {
    string private constant PART_1 =
        '<path d="M42 127h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm5 4h-1v1h1v-1Zm-11 10-1-1-1 2h2v-1Zm14 20-1-2-6-5h-6l-3-2-4-1-1-2-4 2-4 1-2-3-2-2 2-2 3-2h3l4 1 2-1 2-1-1-1v-1h-2l-2 1-1-1-1-2v-8l-2-1v-7l3-3 3-3h16v-2l1-1h10l5-5 4-4h18l1 4 1 5h2l2 1h3v38l-10 10h-7v2H42l-1-2Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="M42 127h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm6 6-1-2h-2v4h3v-2Zm-12 8-1-1-1 2h2v-1Zm14 20-1-2-6-5h-6l-3-2-4-1-1-2-4 2-4 1-2-3-2-2 2-2 3-2h3l4 1 2-1 2-1-1-1v-1h-2l-2 1-1-1-1-2v-8l-2-1v-7l3-3 3-3h16v-2l1-1h10l5-5 4-4h18l1 4 1 5h2l2 1h3v38l-10 10h-7v2H42l-1-2Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="M59 107h-1v1h1v-1Zm14 0h-3v2l1-1h2v-1Zm-5 1h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm8 8v-1H56v1h8l8 1v-1Zm5 1-3-2h-1v2h3l1 1 1 2h2l-3-3Zm-11 1-1-1v3l1-1v-1Zm-32 1h-1v1h1v-1Zm13-2 8-1v-1H40l-2 2-3 3v1l2-2 2-2h8Zm-13 4h-1v1h1v-1Zm-4 0 2-1h-5l-2 3h3l2-2Zm-5 0 1-1-2-1-3 3v-1l-1-2-1 4h5l1-2Zm7 1-1-1v3l1-1v-1Zm44 3h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-26 1 1-1h9l1-2H48v2l-1 2-1-1h-1v2h2l1-2Zm-8 1-1-1-1 2h2v-1Zm3 1v-1h-3l3 2h1l-1-1Zm13 1h-1l-3 1h4v-1Zm-21-2h2-5l-1 1-2 2 2-1 1-1 3-1Zm4 6-1-2h-2v4h3v-2Zm27 7 1-1h-2v2h1v-1Zm-39 1-1-1-1 2h2v-1Zm-14 4h-1v1h1v-1Zm28 16-1-2-6-5h-6l-3-2-4-1-1-2-4 2-3 1-2-2-2-2v-2l2-2 2-1h3l4 1 2-1 2-1-1-1v-1h-2l-1 1-3-3v-8l-2-1v-7l3-3 3-3h16v-2l1-1h10l9-9h18l1 4 1 5h2l2 1h3v37l-5 5-4 5h-8v3H42l-1-2Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M60 107h-2l-2 1h4v-1Zm13 0h-3v2l1-1h2v-1Zm-9 1v-1h2l-1 2h3l-3-3h-1l-2 1v2h2v-1Zm8 8v-1H56v2h16v-1Zm8 3v-1l-2-1h-2l1-2h-4v2h3l1 1 1 2h2v-1Zm-13 0v-1h-2v2h2v-1Zm-6 1 1-1h-2v2h1v-1Zm-13-4h7v-1H40l-3 2-2 3v1l5-4 8-1Zm-4 5h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-8 1 1-1h-1l-2 1v2h1l1-2Zm-1-2 2-1h-3l-4 1-1 1-1 1 2 1h1l1-1 1-1 2-1Zm-7 0v-1h-4l-1 2-1 2h3l2-1 2-2h-1Zm51 5h-1l-3 1h4v-1Zm-30 1h1v1h-1v-1Zm3 0 1-1h8l1-2H49l-2 1-2 2v2h2l1-2Zm-9 1-1-1-1 2h2v-1Zm4 1v-1h-4l3 2h1v-1Zm11 1h-3l-2 1h6l-1-1Zm-20-2h2-5l-1 1-2 2 2-1 1-1 3-1Zm18 4h-1v1h1v-1Zm-14 2v-1l-1-1-1-1-1 1v4h3v-2Zm37 5h-1v1h1v-1Zm0 2h-1v1h1v-1Zm-10 0 1-1h-3l1 2h1v-1Zm-15 1h-1l-3 1h4v-1Zm-24 0-1-1-1 2h2v-1Zm-13 4h-1l-3 1h5l-1-1Zm6 1h-1v1h1v-1Zm21 15-1-2-6-5h-6l-3-2-4-1v-1l-1-1-4 2-4 1-1-2-2-2v-2l2-2 2-1h3l4 1 2-1 2-1-1-1v-1h-2l-1 1-3-3v-8l-2-1v-7l3-3 3-3h16v-2l1-1h10l9-9h18l1 4 1 5h2l2 1h3v37l-5 5-4 5h-8v3H42l-1-2Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M60 107h-2l-2 1h4v-1Zm13 0h-3v2l1-1h2v-1Zm-8 0h1v1h-1v-1Zm2 0-2-1h-1l-2 1v1l6 1-1-2Zm5 9v-1H56v2h16v-1Zm8 3v-1l-2-1h-2l1-2h-4v2h3l1 1 1 2h2v-1Zm-13 0v-1h-2v2h2v-1Zm-6 1 1-1h-2v2h1v-1Zm-13-4h7v-1H40l-3 2-2 3v1l5-4 8-1Zm-7 5h-1v1h1v-1Zm3 0-1-1v3l1-1v-1Zm-11 1 1-1h-1l-2 1v2h1l1-2Zm-1-2 2-1h-3l-4 1-1 1-1 1 2 1h1l1-1 1-1 2-1Zm-7 0v-1h-4l-1 2-1 2h3l2-1 2-2h-1Zm51 5h-1l-3 1h4v-1Zm-30 1h1v1h-1v-1Zm3 0 1-1h8l1-2H49l-2 1-2 2v2h2l1-2Zm-9 1-1-1-1 2h2v-1Zm4 1v-1h-4l3 2h1v-1Zm-9-1h2-5l-1 1-2 2 2-1 1-1 3-1Zm18 4v-2l1 2 1 1h2v-3h-6v3h2v-1Zm-14 2v-1l-1-1-1-1-1 1v4h3v-2Zm37 5h-1v1h1v-1Zm0 2h-1v1h1v-1Zm-10 0 1-1h-3l1 2h1v-1Zm-15 1h-1l-3 1h4v-1Zm-24 0-1-1-1 2h2v-1Zm-13 4h-1l-3 1h5l-1-1Zm6 1h-1v1h1v-1Zm21 15-1-2-6-5h-6l-3-2-4-1v-1l-1-1-4 2-4 1-1-2-2-2v-2l2-2 2-1h3l4 1 2-1 2-1-1-1v-1h-2l-1 1-3-3v-8l-2-1v-7l3-3 3-3h16v-2l1-1h10l9-9h18l1 4 1 5h2l2 1h3v37l-5 5-4 5h-8v3H42l-1-2Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M68 107v-2l-2 2-2 1 2-2h-4l-1 1 1 1v1h6v-2Zm-8 0v-1h-2l-1 1-1 2h4v-2Zm13 0h1v1h-1v-1Zm2 2v-3h-5v3h4v3h1v-3Zm-20 1v-1l-3 3 2-1 2-1h-1Zm-23 13 1-1h-3v3h2v-2Zm3 6h-1v1h1v-1Zm41 1-1-2v4-1h1v-1Zm-23 1v-2l1 2 1 1h2v-3h-6v3h2v-1Zm27 1h-1v1h1v-1Zm-9 0-1-1-1 2h2v-1Zm-36 0h-1v1h1v-1Zm-4 1-1-1-1 2h2v-1Zm12 1h-1v1h1v-1Zm-8 0h-1v1h1v-1Zm25 0 2-2-1-1h-1v2l-6 3h4l2-2Zm-3-17 1-1 1 1v1h-2v-1Zm-10 1h1v1h-1v-1Zm8 1v-3l1 4v1l-1 1v-3Zm-4 2v-2l1 1v1l-1 1v-1Zm-13 1v-2h6l-2 4h-1v-2l1-1h-3v1l1 1h-1l-1 1v-2Zm27 0-2-2 1-1h4l-4-2h5v5l-3-2 2 2 1 2-2 1-2-3Zm-28 3h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm2 2h1v1h-1v-1Zm9 2v-2l1 1v1l-1 1v-1Zm5 6v-1h-2v-7l5-1 3 1h3v2l1 1-1-6h-1l-1 1 1-2v-2h2l1 3 2 2 4 1h4v-4h-2v-3h2l1-4v11l7-1v-9l-2-1-2-1H40l-6 6v-2l-11-1-3 2-2 2v3h6v-4l1 4h3l2-4 3-1v1l1 1-2 3-2 2v4h1l2 1-1-3v-1l-1-1 3 1 3 1 6-2v3l-1 2h2v-3l-1-3 6-7-2 4-3 5 2 2 1 3 2 3h2v-1Zm-13-4h1v1h-1v-1Zm1 2v-2l-1-1v-1l-1 2-1 1v3h2l1 1v-3Zm-13 4-1-1-1-1v2l1 1h1v-1Zm-6-1-1-1v3l1-1v-1Zm60 0v-2h-7v3l1 1v1h6v-3Zm-29 5h-1l-3 1h4v-1Zm-24 0-1-1-1 2h2v-1Zm49 0 1-1 1 1v1h-2v-1Zm3 1 1-2h-7v4l2 1 1-1h1l2-2Zm-12-2v-1h-3v2h3v-1Zm-4 2v-3l1-1h5v2l1 4h-6l-1-2Zm-5 1h2v1h-4l2-1Zm14-4v-5h-7l-2 2-2 2v4l-2-1h-1l-1 1-1 1v2h16v-6Zm-29 3h1v1h-1v-1Zm12 1v-1h-3l-1 2h-4l1-5h-3v2h-7v1l1 2 1 1h15v-2Zm-25 2h-1v1h1v-1Zm-3 0h-4v1l1 1 1-1h2v-1Zm-5 0v-1l-3 1h-3v2h6v-2Zm-7 0v-1l-4 1v1l1 2 2-1 1-2Zm51 3h-1l-3 1h4v-1Zm6 8v-1h-3l-1 2h4v-1Zm-7 0h-1v1h1v-1Zm10 1 1-1h-2v2h1v-1Zm-32 1h-1v1h1v-1Zm16 2h-1v1h1v-1Zm-18 1-1-2-6-5h-6l-3-2-4-1-1-1h-9l-3-3 2-2 2-2h4l4 1 2-1 2-1-1-1v-1h-2l-1 1-3-3v-8l-2-1v-7l3-3 4-3h15v-2l1-1h10l9-9h14l5 1v4l1 4h2l2 1h3v37l-5 5-4 5h-8v3H42l-1-3Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="M73 110v-2l1 1v1l-1 1v-1Zm2-1v-3h-5l-1 1 1 3v2h5v-3Zm-9 3h2v-6h-7v5l3 2h1l1-1Zm-9-2h1v1h-1v-1Zm2 1h1v-5h-4l-1 2v2h-2v3l3-1 2-1h1Zm23 18v-1l-2 1v2h2v-2Zm-10 0-1-1v3l1-1v-1Zm-4 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm16 5-1-1v3l1-1v-1Zm-33 1-2-1v2h2v-1Zm-26 0-1-1v3l1-1v-1Zm-2 0v-2h-2v5h2v-3Zm62 4-1-1v3l1-1v-1Zm-56-1v-2l-2-1h-1v3h2l-1 1v2h1l1-3Zm52 6-1-1-1 2h2v-1Zm-49 0-1-1-1 2h2v-1Zm36-28h1v1h-1v-1Zm-26 3h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm38 1v-2l1 1v1l-1 1v-1Zm-10 0h1v1h-1v-1Zm-22 1v-1l2 1v1h-2v-1Zm27 1v-1l3-3v1l1 1h-3v2l1-1h1v1l1 1h-3l-1-1Zm-39 2h1v1h-1v-1Zm18 1v-1l2-2 2-3-2 4-1 2-1 1v-1Zm-25 0-2-1h5v2h-1l-2-1Zm25 5h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm22 3h1v1h-1v-1Zm-4-2h1v-3h-4l-3-1v4h6Zm-5 2h-2v-7h10v7h-8Zm-16-1 1-2h-1l-1 1v3h1v-2Zm-2 4-2-2v-1l-1-2 1-1 2-1-1 5 1 1 1 2 1-2 2-2 1 1h1v-5h-3v4l-1 1-1 1-1-3 1-2 1-2h6v8l2-1h1l-2 1-2 2h-6l-1-2Zm42 9-1-1 5-2 1 1v-12h-2l-2 1v-4l1-1 1-2 1 1 1 1v-2l1-2v-5l2 1v-1l-1-2v-1h-1l-1 1v-2H39l-1 2-2 1-1 1-1 1 1-2H22l-5 5v2l5 7h2v-10l1 4v3l1-1h1v3l-2-1v2h3v-5l1-5 1-1h1l-1 2v2h2l-1 1-1 2-1 5 1 2 1 2v2l1-1h1v1l1 1h10v-3l1-2 1-1h2l2 4 2-1 2-1h5v-1h2v-2l2-2v-4h-1l-2 1 2-1 1-2-2-2 4 4 8-1v2l1-1h1v1l1 1h-2v1l1 2h-2v7h4l-4 1v5l1 1v1h2l-1-1Zm-21 1h-1v1h1v-1Zm-7-2h1v1h-1v-1Zm2 1 1-2v4h2l-1-2v-1h3l1-2v-2l-2-1-3 1h-2l2 1 1 2h-4v-3l1-2-1-1-1-1-2 4h-7l1 2 2 2h5l-1 1v1l-1-1-1-1 1 3h3l2-1 1-1Zm-22 0v-1h-4l1 1 1 2h2v-2Zm54 2h-1v1h1v-1Zm-10 2v-1h-2v2h3l-1-1Zm-5-10 1-1-4-1h5v3h-2v-1Zm-1 3-2-1v-3l2 3h4v2h-3l-1-1Zm2 2 1-1 1 1v1h-2v-1Zm-1 5 1 1v-3h-3v-2l1-1h1v1l1 1 3 1h3l-1-2h-1l-2 1 2-1 1-2v-12h-4l-3 1-2 3-2 2-2 3-2-1h-1v4l3 3-1-1-2-1 2 2 1 1 1-1v-1l3 2v3l3-2v1Zm-40 0h-1v1h1v-1Zm57 1h-1v1h1v-1Zm-37 0h-6 7-1Zm-8 0 1-1-2-1-1-2h-4l-1-4v9h7v-1Zm29 4v-2l1 1v1l-1 1v-1Zm1 3-3-1h9l-1 1v1h1l1 1v-1l-1-1 2-2 2-1 1 1v-2l1-2h-4l-1 1-1 1v-1l1-1-3 1v1l1 2-1-1-2-1-2 1 3-3h-4l-1 2-1-1-2-1h-4l6 6 2 1 1 1h2l-2-2Zm-10 1h1v1h-1v-1Zm2 0-1-1h-5v3h3l3-1v-1Zm-12 1-5-1v-4l1 4h6v-4H39l2 3 3 3h4l4-1h-4Zm-7 1-1-2-6-5h-5l-4-2-4-1v-1l1-1-5 1-5 1-2-1-1-2v-3l1 1v1l3 1 2 1v-2l7 1v-4H11l1-1h4l4 1 2-1 2-1-1-2-3-1h-3v-9l-2-1v-6l7-7h15v-2l1-1h10l4-4 4-4h20v4l1 4h2l2 1h3v37l-9 10h-8v3H42l-1-3Z" style="fill:';
    string private constant PART_8 =
        ';"/><path d="M17 149h-1v1h1v-1Zm-7 0-1-1v-1l1-2v4h3l2 1v-3h3v2l1-1h2v2l-6 1h-4l-1-2Zm63-37h2v-6h-6v4l1 3h2l1-1Zm-5-3v-3h-7v6l3 1h4v-4Zm-10 3h2v-6h-3l-5 5 1 2 2-1h3Zm-35 24-1-1v3l1-1v-1Zm-2 0v-2h-2v5h2v-3Zm6 4v-3l1-1-2-1h-2v5l1 2h2v-2Zm11 4h-1v1h1v-1Zm45 1h-1v1h1v-1Zm-53 0-1-2-1 4 1 3 1-2v-3Zm43 3 1-2-3 3h-3v2h3l2-3Zm-47 2 1-1h-2l-1 1v-2h3l-1-5-1 1-2 1v6h3v-1Zm57 0v-1l-3-1 1 2 1 2h1v-2Zm-17-33h1v1h-1v-1Zm1 3h2v1h-4l2-1Zm-27 0h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm38 1v-2l1 1v1l-1 1v-1Zm-10 0h1v1h-1v-1Zm-22 1 1-1 1 1v1h-2v-1Zm28 1 1-1 2 1v1h-3v-1Zm-21 1v-1l2-1 1-2-1 2-2 2v1-1Zm-25 1h1v1h-1v-1Zm-2 2h1v1h-1v-1Zm61 1 1-1h1v2h-2v-1Zm-22 3v-2l-7-1v5l6-1 1-1Zm-8-1v-3h10v7H49v-4Zm-7 7 1-1h1l-1 2h-1v-1Zm38 1h1v1h-1v-1Zm-39-6v-1h-2l1 2h1v-1Zm-6 1v-2l-1 1v2l1 2v-3Zm4 4h-1v1h1v-1Zm-7 0-1-2v-2l1-3v5l1 2 1 1h3l-5-4 3-5h4l3 2v5h-2l-2-5 1-1h-3v5h2l2 1 1 1-1 1v1h-6l-2-2Zm43 2h1v1h-1v-1Zm-9 1 1-1-3-1h3l1 1v2h-2v-1Zm14 1v-2l1 1v1l-1 1v-1Zm-8 0v-3l1 4v1l-1 1v-3Zm-7 2-2-1v-3l2 3h4v2h-2l-2-1Zm7-14-1-1v3l1-1v-1Zm-2 0-1-1v3l1-1v-1Zm-2 1h-1v1h1v-1Zm-2-1-1-1v3l1-1v-1Zm-19 12 1-2-2-1-1-2v-2l1 2 2 1h4l5 1v-3l1 2 2 1v-1l1-1v-2l-1 2-1 1v-1l1-2 1 1h1l1-1 1-2-1-3v-4l-1-1-2-2 2 2 2 1v2h10l2 1 1 1v-1l4 4h-5v-3h-2v1l1 2h-2v3l-1 3v-6h-7l-2 4-3 4h-4l1 3-2-2-1-1h-3l-4 1 2 1 2 2h-4v-3Zm30 3h1v1h-1v-1Zm-33 1h1v1h-1v-1Zm-4 5v-1h-1l-1 1-1-3-1-3 1-1 1-2v5l4 2h13v-5l1 5h7v2h2l2 1v-3h5v-4l3 3 3 1 1-2v-2l2 1v-2l2 1-1-28-2 1v-2H39l-1 2-2 1-1 1-1 1v-1l1-1H22l-5 5v6h3l-1 1v1h1l1 1h2l1 1v-11l1 10h2l1 1v-6l1-5 2-1-1 2v3l2-2-3 4v5l1 2 1 2v2l1-1h1v1l1 1h10l1-3v2l-1 1-3 1h-4l-1 2-1 2-2-1h-2v8h9v-2Zm6 0h1v1h-1v-1Zm3-1h-3l-3 1-1 1v-1l-1-2v4h5l3-2v-1Zm3 4h-1v1h1v-1Zm3 2 1-1h-2l-1 2h2v-1Zm24-2h1v1h-1v-1Zm-6 4h1v1h-1v-1Zm-7 0h1v1h-1v-1Zm4 1v-2l1 1v1l-1 1v-1Zm8-2 3-3h-1v-1H58l4 3 3 3v1h9l4-3Zm-18 3-2-2-3 2 1-1 1-2-1 1h-2v4h8l-2-2Zm-12 0h1v1h-1v-1Zm-3 0 1-1 1 1v1h-2v-1Zm7 0v-1l-1 1-1 1v-5H39l1 1 1 2 2 1 1 2h9l-1-2Zm-11 2-1-2-6-5h-5l-4-1-4-2 1-3v-4H11l1-1h4l4 1 2-1 2-1-1-2-3-1h-3v-9l-2-1v-6l7-7h15v-2l1-1h10l4-4 4-4h20v4l1 4h2l2 1h3v37l-9 10h-8v3H42l-1-2Z" style="fill:';
    string private constant PART_9 =
        ';"/><path d="M67 120h1v1h-1v-1Zm-35 0h1v1h-1v-1Zm38 1v-2l1 1v1l-1 1v-1Zm-10 0h1v1h-1v-1Zm-22 1h1v1h-1v-1Zm30 1h1v1h-1v-1Zm-7 0h1v1h-1v-1Zm-16 1v-1l2-1 1-2-1 2-2 2v1-1Zm18 2v-2l1 1v1l-1 1v-1Zm16 2 1-1 1 1v1h-2v-1Zm-3 3v-1l1-1 2 1 2 2h-5v-1Zm-4-1v-1h-3v2h3v-1Zm-4 0h-1v1h1v-1Zm-2-1-1-1v3l1-1v-1Zm-2 1-1-2h7l3-1h2v1l1 1h-2v1l1 2H64v-2Zm8 3h1v1h-1v-1Zm-15-2v-2h-4l-3-1v5h7v-2Zm-8-1v-3h10v7H49v-4Zm-18 4v-3l1 3-1 2v-2Zm10-2v-1h-2l1 2h1v-1Zm-2 4h1l-1-3-1-2 1-1h-4l1 4-2-3 1 5-2-2 1-3 1-2h4l3 2v5h-2l-1 1h-2l2-1Zm26 2 1-1 1 1v1h-2v-1Zm-30 0h2l-1-4 2 3 2 2h-3l-4-1h2Zm31 2 1-1 1 1v1h-2v-1Zm0 2h1v1h-1v-1Zm-3 0v-1l1-1v1l1 2h-1l-1-1Zm-7 0h1v1h-1v-1Zm12 1h1v1h-1v-1Zm-21 0v-3l1-1-2-1-1-2v-2l2 2 2 2h10l5-5-2 3-2 4h-9l-3 1 1 3h-1l-1-1Zm34 1v-2l1 1v1l-1 1v-1Zm-9 2v-2l1 1v1l-1 1v-1Zm-62 3-1-1v-2l2 2 1 3h-1l-1-2Zm50-40v-3h-3l-3 2-2 3v2h8v-4Zm-37 27-1-2v4-1h1v-1Zm4 3v-2l2 3v-3l-3-2h-2v5l1 2h2v-3Zm6 3v-1h-2v2h2v-1Zm39 8v-1h-4v2h4v-1Zm-47-1v-2l1 1v1l-1 1v-1Zm2-2v-4h-2l-1 1h-1v7h4v-4Zm56 3v-1l-3-1 1 2 1 2h1v-2Zm-43 2h1v1h-1v-1Zm11 1h-2v-5l-3 1-3 1-3-2-3-1v-2l-1-1h-8v6h1l1 1v-3l1-3v7h-2l-3 1 5-1h5v2h16l-1-1Zm5 2v-1h-3v2h3v-1Zm8 6h-1v1h1v-1Zm-2-1-1-2-2 1v-3h-2l-1 1h-2v4h3l3 1h2v-2Zm-7 2h-1v1h1v-1Zm-13 1-1-1v-2l4 1 4 1 2-1 1-1v-6l-1 3-1 3v-5H39v2h2v3l-3-3-3-2v-1h-6l-4-2-4-1v-1l-1-1-3 1-2 1v-5l1 3h6v-5H11h1v-1h11l1-1-1-2-2-1v-5l-2-1v6h-2v-9l-2-1v-7l3-2 3-2v-1l-1-1h16l1-2 1-1h10l8-8h5l5-1 1 1v1h-6v6l3 1h4v-8h1v7l6 1v-7l-5-1h6v4l1 4h2l2 1h3v38l-3 2-3 2 2-1 1-2v-2l-18 1 4-1v-3h6l1-1h9v-31l-2-1H39l-2 3-14-1-3 3-3 3v7l1-1 2 2 1 2h3v-11l1 12h3v-7l1-6 1 5 1-1 1-1-2 2-1 3v4l1 3v2l1 1 2-1v2h11l1-3v2l-1 1-9 1 2 4 3 3h23v2l-3 1-3 1 8 7 5 1h4l2-2 2-2-2 2-1 3h-8v3H42v-1Z" style="fill:';
    string private constant PART_10 =
        ';"/><path d="M71 105h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-3 0 1-1 1 1v1h-2v-1Zm-3 1v-1h2l-1 2h-1v-1Zm8 1v-2l1 2v1h-1v1-2Zm-14 0 2-2h1l-2 2-1 2h-1l1-2Zm-22 13h1v1h-1v-1Zm38 1h1v1h-1v-1Zm-10 0h1v1h-1v-1Zm-14 1h1v1h-1v-1Zm15 1h1v1h-1v-1Zm-16 1h1v1h-1v-1Zm18 1h1v1h-1v-1Zm-34 1v-2l1 1 1 1v1h-1l-1-1Zm42 2h3l1 1-6-1h2Zm-36 2 1-1h4-1l-3 1-3 1 2-1Zm-7 0h1v1h-1v-1Zm49 1h1l2 1h-5l2-1Zm-6 0h3l1 1-6-1h2Zm-7-1v-2h3v2l1 2h-2v-4l-2 4v-2Zm-6 3v-2l1 1v1l-1 1v-1Zm-5 0 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm-2-3v-3h9l1 4h-2v-1l1-1h-4l-4-1v3l-1 3v-4Zm-8 3v-2l1 2v1h-1v1-2Zm-2 0v-2l1 2v1h-1v1-2Zm-6 0v-2l1 2v1h-1v1-2Zm12 2h1v1h-1v-1Zm16 1 1-1h1l-1 2h-1v-1Zm-22 0h1v1h-1v-1Zm-18 0h1v1h-1v-1Zm17 2h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-17-3v-5l-2-1v-7h1l1 1v-1l1-2-1 5v4l2 2 2 2h3l1-7v8h3l1-3v4h-8v-2h-2l-2 6v-4Zm27 4h1v1h-1v-1Zm3-1-2-2 3 1 2 1h11l-1 1-1 1h-5l-4-1v1h-1l-2-2Zm16 3v-2l1 1v1l-1 1v-1Zm-7 1h1v1h-1v-1Zm-9 0h1v1h-1v-1Zm-32 2h1v1h-1v-1Zm57 1h1v1h-1v-1Zm-45 1h1v1h-1v-1Zm-17 3-1-1v-2l2 2 1 3h-1l-1-2Zm17 2v-1l1-2v3h2l1 1h-3l-1-1Zm-6 0v-1h-5l1-1h5v-1l1-2v6h-1l-1-1Zm5 2-2-1h2l3 2h-2l-1-1Zm55 0v-2H67v-4l1 4h4v-2l-1-1h4l2-1h3l1 2 1 3 1-3h-2v-2l2 1v-33H39l-3 2 1 1v1l-1-1H23l-2 1-1 1v-2l1-2h15l2-4 12 2v-1l1-2-2 2v-1l1-1 1 1 2 1 8 1-1-3v-2l1 2 1 2h5l1-1 1-2v3h6v-7l-1-1h-2 4v2l1 2v5l2-1 2 1h2l1 38-2 1-2 2 1-2Zm-33 1 1-1 1 1v1h-2v-1Zm-12 2-2-2-2-1h-2l16 1h1v1h-8v1l-1 2-2-2Zm37 4 1-1 2-1 2-2-2 2-1 3h-4l2-1Zm-4 0h2v1h-4l2-1Zm-35-18-3-3v4h3v-1Zm23 9-1-1-1 2h2v-1Zm-3 0h-1v1h1v-1Zm2 4v-1h-3v2h3v-1Zm5 3-4-3-1 1-1 1h-3v-5h-1l-2 1v-4h-9l-5-5-5-1h-6l-1 1-1 2v-2h-3l-3 1 7-2 1-1-1-2v-1h-1l-1 1v-2l1-1h2l-1 1 1 2 2 2 1-1h2v-5l6 6 5 6h23v3h-5v2l7 8 1-1 1-1-1 2v1h-2l-3-4Zm-19 5h-1v-2h1l1 1h5l5 1 1-5v5h6l6-1 1 1v1H43l-1-1Z" style="fill:';
    string private constant PART_11 =
        ';"/><path d="m63 105 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-7 7 1-1 2 1h-3Zm7 2v-1h18l1-1 1-2v2l1 1 3 2H56v-1Zm25 1 1-1 2 1h-3Zm-42-1h-1v1h1v-1Zm-2 1v-1h1v-1l17 1-17 1h-1Zm-3 1h1l2 1h-5l2-1Zm2 2h1v1h-1v-1Zm-15 0 1-2h9l-8 1-3 3 1-2Zm25 4h1v1h-1v-1Zm17 3h1v1h-1v-1Zm-33 1h1v1h-1v-1Zm53-2v-5l1 5-1 4v-4Zm-18 4h1v1h-1v-1Zm-16 1v-2h7l1 2-4-1h-3v2l-1 1v-2Zm-14 1 1-1h2l-3 2h-2l2-1Zm-11 0v-2l1 1v1l-1 1v-1Zm52 1h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-7 0h1v1h-1v-1Zm-48-1-1-2v-6h1l1 1v3l-1 2 2 2 1 2h-2l-1-2Zm33 2h1v1h-1v-1Zm-8 1v-2l1 2v1h-1v1-2Zm-2 1v-2l1 1v1l-1 1v-1Zm-6 0v-2l1 1v1l-1 1v-1Zm-7 1-2-1-2 1-1-2-2-2 3 2 2 1v-2l1-1v3h4v2h-1l-2-1Zm57 0v-4l1 4-1 3v-3Zm-31 3h1v1h-1v-1Zm-3 0 1-1 1 1v1h-2v-1Zm-20 0v-2l1 1 1 1v1h-1l-1-1Zm-12-1v-2l1 2v1h-1v1-2Zm41 2v-1h3l-1 2h-2v-1Zm-4 0v-1l2 1v1h-2v-1Zm-10 0h1v1h-1v-1Zm-23 0h1v1h-1v-1Zm11 1h1v1h-1v-1Zm-9 0h1v1h-1v-1Zm40 1v-2l1 1v1l-1 1v-1Zm20 1v-2l1 1v1l-1 1v-1Zm-27 0h1v1h-1v-1Zm-22 1h2v1h-4l2-1Zm-9 0-2-1h5l1-1h2v2l-1-1-2 1h-3Zm-3 0h1v1h-1v-1Zm-2 1h1v1h-1v-1Zm63 1v-2l1 1v1l-1 1v-1Zm-61 0h1v1h-1v-1Zm15 1v-2l1 1 1 1v1h-1l-1-1Zm17 2 1-1 1 1v1h-2v-1Zm-8 0h2v1h-4l2-1Zm-6 0h1v1h-1v-1Zm-31 0v-2l1 1v1l-1 1v-1Zm49 1v-1h2l-1 2h-1v-1Zm-9 0 1-1 1 1v1h-2v-1Zm18 1h1v1h-1v-1Zm-6-1v-1l2 1v2h-2v-2Zm-9 2h1v1h-1v-1Zm-30-2v-3l1 4v1l-1 1v-3Zm27 3 1-1h1l-1 2h-1v-1Zm-24 0h1v1h-1v-1Zm56 0-1-2h-1l-1 1-1-2h-2l1 2h-4l4-4 1 2 2 1v-3 1l1 1 4-2v6l-1-2v-2h-2l1 5h-1v-2Zm-54 1h1v1h-1v-1Zm21 1 1-1 1 1v1h-2v-1Zm-3 0h1v1h-1v-1Zm-10 0v-1h1v1l1 2h-2v-2Zm22 1-3-2h-1v1-1l1-1 2-1h2l-1 1-1 2h1l4 3h-2l-2-2Zm-3 1h1v1h-1v-1Zm-2 0v-2l1 1v1l-1 1v-1Zm-14 0v-1l1-1h2l-2 2-1 1v-1Zm38 2h1v1h-1v-1Zm-15 1v-2l1 1 1 1v1h-1l-1-1Zm-8 0h1v1h-1v-1Zm20 1h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-6 1v-2l1 1 1 1v1h-1l-1-1Zm-3 2h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-3 0 1-1 1 1v1h-2v-1Zm-3 0h1v1h-1v-1Zm-4 0h1v1h-1v-1Z" style="fill:';
    string private constant PART_12 = ';"/>';
    string private constant COLOR_1 = "hsl(193, 43%, 53%)";
    string private constant COLOR_2 = "hsl(45, 3%, 52%)";
    string private constant COLOR_3 = "hsl(25, 17%, 46%)";
    string private constant COLOR_4 = "hsl(21, 22%, 40%)";
    string private constant COLOR_5 = "hsl(220, 2%, 37%)";
    string private constant COLOR_6 = "hsl(223, 6%, 24%)";
    string private constant COLOR_7 = "hsl(213, 9%, 20%)";
    string private constant COLOR_8 = "hsl(213, 10%, 18%)";
    string private constant COLOR_9 = "hsl(223, 10%, 13%)";
    string private constant COLOR_10 = "hsl(223, 15%, 10%)";
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
