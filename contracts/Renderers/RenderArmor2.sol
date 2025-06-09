// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderArmor2 {
    string private constant PART_1 =
        '<path d="M122 120v-1h-1v1h1Zm-37 17h-1l-2 1h3v-1Zm51 41v-1l-5 1-8-7-14-2-6-6h-4l-2 3H81l-2-3h-3l-2-3h-7v-41h2l7-3 1-2h7l6-6h17l5 6h6l11-11h40l4 3v9l7 7v23l-11 13v13l-5 4h-6l-5 4h-4l-1-2v2h-5l-1-2v2h-6v-1Z" style="fill:';
    string private constant PART_2 =
        '"/><path d="M80 136h21v10H80z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M161 105h-1l-1 1h2l-1-1h1Zm-31 1 1-2-3 3v1h1l1-2Zm36 1h1l1 1h-4l2-1Zm3 0v-2h-5v4h5v-2Zm-34 4v-1h-1v1h1Zm33 1v-1h-1v1h1Zm-25 0v-1h-1v1h1Zm20 0v-1l-4 1 1 1 3-1Zm-23 0 1-1h-1l-1 2h1v-1Zm2-5v-1l1 1-1 1v-1Zm-6 1v-1l3-1-1 2h-2Zm12 1h15v-4l-3 2-3-2h-1l1 3h-4v-2l2-1h-2l-1 2h-2l1-2h-16l-9 8 7-4h15Zm-1 5v-1h-1v1h1Zm-21 0v-1h-1v1h1Zm-25-2 5 1v-2H94v4l1-3h6Zm-9 1 1-1h-2v2h1v-1Zm76 3h-4l-8 1h15l-4-1Zm-15 0h-1l-1 1h2l-1-1h1Zm-6 0h-1l-1 1h2l-1-1h1Zm-6 0h-1l-1 1h2l-1-1h1Zm-6 0h-1l-1 1h2l-1-1h1Zm-39 5v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm20-2h4l2-2h-11v6l1-3 4-1Zm-15 3v-1h-1v1h1Zm80-1-2-3h-10l2 1 6 2-1-2h3l2 4h2l-2-3Zm-90-2h4l2-1 1 2 10-1 2-2H82l-4 3v4l2-5h3Zm83 5v-1h-1v1h1Zm-11-1 1-1-3 1v1h2v-1Zm-19 1v-1h-1v1h1Zm-45 0v-1h-1v1h1Zm15-1 2-3h-1l-5 5h1l3-2Zm58 3v-1h-1v1h1Zm11 1v-1h-1v1h1Zm-58-6h-1l1-3 5-1v2l-4 3-1-1Zm3 1h2l-1-2 3 1v-2l-3-3h-4l-2 5h-3v2l6-1v6l1-5h1Zm-5 4h-1l-4 1h6l-1-1Zm-10 2v-1h-1v1h1Zm-8-1h-6l-14 1h26l-6-1Zm71 2v-1h-1v1h1Zm-5 0v-1h-1v1h1Zm-13-2 2-2-5 4h2l1-2Zm-8 1 1-2-2 1v2h1v-2Zm-12 0 1-1h-2v2h1v-1Zm-4-3v-5h33l2 1v-3h-35l3-2h-4v13l-8 1h9v-5Zm19 6v-1h-1v1h1Zm16 1v-1h-1v1h1Zm8 1v-1h-1v1h1Zm-63-2h-1v2l1-1-1-1Zm43 3v-1h-1v1h1Zm-56 1v-1h-1v1h1Zm74 1-1-1-3 1h4Zm-7 0v-1h-1v1h1Zm-4-2h-1v2l1-1-1-1Zm-37 0-1-1v3l1-1v-1Zm40 4v-1h-1v1h1Zm-19 0v-1h-1v1h1Zm-50 0v-1h-1v1h1Zm-5-1v-1h-2l-1 2h3v-1Zm75 3v-1h-1v1h1Zm-37-1 1-1h-1l-1 2h1v-1Zm-39 1v-1h-1v1h1Zm81 3v-1l-2-1 1 2h1Zm-11 0v-1h-1v1h1Zm-16 0v-1h-1v1h1Zm-41-2 1-1-4-3-3 3 1 3h5v-2Zm75 3v-1h-1v1h1Zm-40 0v-1h-1v1h1Zm32 1v-1h-1v1h1Zm-66 0v-1h-1v1h1Zm10 1v-1h-1v1h1Zm-5 1v-1h-1v1h1Zm16 1 1-1h-2v2h1v-1Zm-13 1v-1h-1v1h1Zm41 1v-1h-2l1 2h1v-1Zm5 2v-1h-1v1h1Zm-29 2-1-1-3 1h4Zm13 24v-1l-5 1-8-7h-5l-1-2h-8l-6-6h-4l-2 3H81l-2-3h-3l-2-3h-7v-41h3l9-5h5l6-6h17l4 6h7l12-11h38l4 2v11h3l4 5v24l-10 13v13l-5 4h-6l-4 4h-4l-2-2v2h-5l-1-2v2h-5v-1Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="M145 122v-1h1v1h-1Zm22-14v-1h1v1h-1Zm2-1v-2h-5v4h5v-2Zm-34 4v-1h-1v1h1Zm8 1v-1h-1v1h1Zm25-1h-1v2l1-1-1-1Zm-3 2v-1h-1v1h1Zm-24-1v-1h-2v2h2v-1Zm-3-5v-1h1v1h-1Zm-8 0v-1h1v1h-1Zm24 0h1l2 1h-5l1-1Zm-12 1v-1h1v1h-1Zm-6 0v-1h1v1h-1Zm12 1h15v-4h-29l-1 3h-2l1-2-2-1-5 5 4-1v-2l2 1-5 5 7-4h15Zm-24 4v-1h-1v1h1Zm38-1 1-1-4 1 1 2 1-1 1-1Zm-6 2v-1l-2-1v2h2Zm-9 0v-1h-1v1h1Zm-21 0v-1h-1v1h1Zm-30-1v-1h9l1 3v-4H94v3h2v-1Zm-3-1v-1l-2 1v2l2-1v-1Zm48 4h-1l-1 1h2l-1-1h1Zm-6 0h-1l-1 1h2l-1-1h1Zm40 2v-1h-1v1h1Zm-6 3v-1h-1v1h1Zm-86 2v-1h-1v1h1Zm8 1v-1h-1v1h1Zm-2-4v-1h1v1h-1Zm-1 2-2-2v-1h2l-1 2 3 2 2-3v2l3-1v-2h2l1 3-3-1 2 2h3l-1-2h2l1-4H81l-3 3v4l4-5v2l3-2v2l3 3h1l-2-2Zm66 2 1-1h-2v2h1v-1Zm-24 0 1-1h-1l-1 2h1v-1Zm36 1h1l2-3-3 2-3-2v5l2-3h1Zm-20 1v-1h-1v1h1Zm-24 0v-1h-1v1h1Zm-12-6h2l2-3h-11v5l4-3 1 1-5 5v2l6-8 1 1Zm-31 4h-1v2l1-1-1-1Zm96 3v-1h-1v1h1Zm-51-2h-1v2l1-1-1-1Zm-7-7v-1h1v1h-1Zm2 7v-2h3l-1-2h-2v-1l3-3-1 3 3 3v-4l-1-3h-6l-1 4-4 1v2l6-1v5l2-1-1-2Zm-4 1h-1l-4 1h6l-1-1Zm44 2v-1h-1v1h1Zm-21 0v-1h-1v1h1Zm-32-1h-1l-2 1h3v-1Zm62 2v-1h-1v1h1Zm-18-1 1-2 2 1-2-3h-1l1 2-3 2-1-1-1 2h3l1-1Zm-20 0 1-1h-2l-1 2h2v-1Zm44 0h-1v2l1-1-1-1Zm-11 1 1-1h-3v2h1l1-1Zm-5 1v-1h-1v1h1Zm10 1v-1h-1v1h1Zm-15 0v-1h-1v1h1Zm-5 0v-1h-1v1h1Zm-12 0v-1h-1v1h1Zm6-3v-1h1v1h-1Zm3 2-2-1 1-5h-3l2 1-3 3 5 4h1l-1-2Zm-54-2h11l1-1H78v6l1-5h12Zm78 5v-1h-1v1h1Zm-40-2h-1v2l1-1-1-1Zm32 1-1-1-1 4 2-3v-1Zm-29 2v-1h-1v1h1Zm-4 1v-1h-1v1h1Zm-35 0v-1h-1v1h1Zm63 0 1-2-2 1v2h1v-1Zm11 0 1-1-5 1-1 2 5-1v-1Zm-58 2v-1h-1v1h1Zm51-1-1-1-1 4 2-3v-1Zm-17 2v-1h-1v1h1Zm-3-1 1-1h-1l-1 2h1v-1Zm-50 1v-1h-1v1h1Zm-5-1v-1h-2l-1 2h3v-1Zm63-4-1-1 1 8 1-6-1-1Zm-40 6v-1h-1v1h1Zm16 0v-1l-2-1v3h2v-1Zm-38 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm77 0v-1h-2l1 2h1v-1Zm-17 2v-1h-1v1h1Zm22 1v-1l-3-1 1 2h2Zm-11-2v-1l-4 1 1 2h2l1-2Zm-17 2v-1h-1v1h1Zm-10-1 1-1h-1l-1 2h1v-1Zm-28 1v-1h-1v1h1Zm-3-2 1-2-1-2h-4l-1 3 1 3h4v-2Zm61 3v-1l-2-1 1 2h1Zm-26 0v-1h-1v1h1Zm32 1v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm-35 0v-1h-1v1h1Zm-15-11-1-3v15l1-8v-4Zm-8 11v-1h-1v1h1Zm74-2-1-1-2 5 3-4Zm-25 3v-1h-1v1h1Zm-38-1h-1l-2 1h3v-1Zm17 2v-1h-1v1h1Zm-23 0v-1h-1v1h1Zm34 1v-1h-1v1h1Zm2 1v-1h-1v1h1Zm17 1v-1h-1v1h1Zm-50-3-1-1-1 4 2-2v-1Zm60 4v-1h-1v1h1Zm-67 0v-1h-1v1h1Zm53 1v-1h-1v1h1Zm-6-3-1 1 1 5 1-5-1-1Zm-23 5v-1l-2-1-1 2h3Zm-3-6 1-1h-3v8l1-6 1-1Zm21 16v-1h-1v1h1Zm20 1v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm-15 0v-1h-1v1h1Zm-2 13v-1l-5 1-8-7h-5l-1-2h-8l-6-6h-4l-2 3H81l-2-3h-3l-2-3h-7v-41l6-1 6-4h5l6-6h17l4 6h7l12-11h38l4 2v11h-16l3 2h-6l-1-2-1 2h-4l-1-2-1 2h-15l-1-2h-4v13h-7v17l1-14 2-2h6l-1-3h2l-1-7h3l5 5 1-2h-2l1-3h9v2l13 1 3-2 2 2-2-4 11 1 3 4 1-2-3-2v-3l2-1 5 5v25l-10 12v13l-5 4h-6l-4 3-5 1-1-2v2h-5l-1-2v2h-5Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="M171 121v-1h1v1h-1Zm-7 1v-1h2l4-1-1 2-2-1v2h-3v-1Zm-11 0h1l1 1h-3l1-1Zm-18 0 1-2 3 1-1 2-2-2v2h-2l1-1Zm-7 2-1-1 1-2h2v3h-2Zm21 1v-1l2 1v1h-1l-1-1Zm9 2v-1l5-1v2h-5Zm-2 0v-1h1v1h-1Zm9 0-1-1 4-1 1 2-2-1-1 2-1-1Zm-19 1v-1h1v1h-1Zm15 1v-1h1v1h-1Zm-30-1v-2l-3 1 3-2 1 1-1 4v-2Zm38 2v-1h1v1h-1Zm-13-1v-1l1 1-1 1v-1Zm-18-1-1-3v-1l4 1-1-5h2v7h-2l-1 2 2-1-1 2h-1l-1-3Zm-4 3v-1h1v1h-1Zm-7 0v-1h1v1h-1Zm21 0v-1h4l-1 2h-3v-1Zm-2 0-1-2h2v3h-1l-1-1Zm21 2v-2h2l-1 3h-1v-1Zm-5 1v-2l2-3h3l-4 2v3l3 1h-3l-1-1Zm-8 1v-1l2-1-1 3h-1v-1Zm3 2 1-2-1-2h2v4l-4 1 2-1Zm-16 1v-1h1v1h-1Zm-18 0v-1l2 1 1-2v3h-4l1-1Zm29 1v-1h-1v1h1Zm-3 0v-1l3-2 2 2-1 2h-3l-1-1Zm-10 1v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm6 1v-1h1v1h-1Zm24 0h2l-3-3 4 2-1 2h-5l3-1Zm-10 0-2-1h3l1 2h-1l-1-1Zm-29 0 1-1 1 1-4 1 1-1Zm42 2v-1h1v1h-1Zm-12 1v-1h1v1h-1Zm-28 0v-1h1v1h-1Zm32 0h1l-2-4 1-3h4l-1 3-2-1v5l-2 1 1-1Zm-28 2v-1h1v1h-1Zm33 0v-1l1 1-1 1v-1Zm-7 1v-1h1v1h-1Zm-3-1v-1h2l-1 2h-1v-1Zm7 2v-1h1v1h-1Zm-6 2v-1h1v1h-1Zm-4-1v-1h2l-1 2h-1v-1Zm-14 2v-1l-3 2 3-4 1 2-1 3v-2Zm31-43-1-1v5l1-3v-1Zm-5 5v-1l2 1v1h-1l-1-1Zm3-3v-5h-5v10h5v-5Zm-10 3-1-1v3l1-1v-1Zm-27-5v-1h1v1h-1Zm14 1v-1h1v1h-1Zm-15 2v-1h1v1h-1Zm13 0-2-1h2l4 2h-3l-1-1Zm-11 1v-1h1v1h-1Zm-7 0v-1h1v1h-1Zm-1 2v1h5l2-2v3l2-3v2h3v-3h-2l2-3v3l3-2 3 1h-4v4h2v-3h2l-1 3h2v-2l1 2h12v-3l2-1 1 4h3v-10h-31l-2 3 1-3h-2l-9 11 4-3 1 1Zm-29-1v-1h1v1h-1Zm7 1 1-2v3h2v-4H94v4h8l1-1Zm-10-1v-2h-3l-3 3 3-1v2h3v-2Zm-16 7v-1h-1v1h1Zm-4 2h-1v2l1-1-1-1Zm-2 2v-1l-2-1-1 2h3Zm35-5h1l1 1h-2v-1Zm-1 3v-1h1v1h-1Zm5 0 4-4-2-2-9 1v9h3l4-4Zm-24-1v-1h1v1h-1Zm-4 0 1-1h2l-1 2h-2v-1Zm14 2v-1h1v1h-1Zm-8 0v-1h2v2h-1l-1-1Zm10 2v-1h1v1h-1Zm-12 0v-1h1v1h-1Zm-7-1 1-1h1l-1 2h-1v-1Zm22-1v-3l1-3H81l-3 3v6h23v-3Zm23-1v-6h-7l-6 7v1l7-1v4h6v-5Zm-47 6v-1h-1v1h1Zm20 6h-1l-2 1h3v-1Zm-3 0h-1l-2 1h3v-1Zm5 2v-1h-1v1h1Zm-11 0v-1h-1v1h1Zm2 1 1-2-2 1v2h1v-1Zm-5 0-1-1-3 2h5l-1-1Zm1 4v-2h-3l2 3h1v-1Zm14 2v-1h-1v1h1Zm-3-2 1-2-1-2h-4l-1 3 1 3h4v-2Zm1 4v-1h-1v1h1Zm-6 0v-1l-3-1 2 2h1Zm11 2v-1h-1v1h1Zm6 0h-1v2l1-1-1-1Zm7 1v-2h-3l3-1v-19h-5v24h5v-2Zm-21 2h-5l-11 1h21l-5-1Zm11-11v-1l2 1v1h-1l-1-1Zm-1 12h2v-4l3-2-1-18H78v24l1-1v-21h28-2v20l-4 1v2l3-1h1Zm54 2v-1h-1v1h1Zm-80 1h-1v2l1-1-1-1Zm16 3v-1l-2-1v2h2Zm-13 0v-1h-1v1h1Zm79 7v-1h-2v3l3-1-1-1Zm-3 1v-1l-4-1h-14l2 3h16v-1Zm-19-1v-1h-2v5l2-3v-1Zm-3 0-1-1-5 2h5v3l1-4Zm12 4h-1l-1 1h2l-1-1h1Zm-12 10v-1l-5 1-7-7h-6l-1-2h-8l-5-6h-5l-2 3H81l-2-3h-3l-2-3h-7v-40l5-2h2l4-4h6l6-6h17l4 6h7l12-11h38l4 2v11h-15v2h-3v-2h-3l-1 3-4-3-1 2h-3v-2h-4v2h-3l-1-2-1 2h-3v-2h-5v13h-8l1 16h6l6 6 5-1-2 2-4 1-5-6h-7v7h30v-13l-3-1 3-1v-3l-5-1-3 2 1-2h-7v3l-3-1-2 2v-4l5-2h15v18l4-1-1 3-3-1v2h8v-2l-4 1 2-2 11-1-2 3 11-11 1-20 3 1v-2l-5-5h2l4 4v25l-10 12v13l-5 5h-6l-3 2-6 1-1-2v3h-5v-3l-2 3h-4v-1Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M124 120v-1l1 1-1 1v-1Zm40 2h1l1 1h-3l1-1Zm-18 6v-1h1v1h-1Zm18 2v-1h1v1h-1Zm-16 1v-1h1v1h-1Zm10 3v-1h1v1h-1Zm4 18v-1h1v1h-1Zm-3-1h1l1 1h-3l1-1Zm-32-1-3-3h-6l3-2h3l6 7h-1l-2-2Zm15-37v-1h1v1h-1Zm21 0v-2l1 4h5v-7l2 6v-6l-3-3h-38l-9 9v1h42v-2Zm-55 0h-1v2l1-1-1-1Zm-2 0v-2H94v4h12v-2Zm-13 0v-2l-2-1-5 5h7v-2Zm-20 10v-1l-5-1v3h5v-1Zm-1 13v-1h-1v1h1Zm106 8v-1h-1v1h1Zm-109 1v-1h-1v1h1Zm47-7v-13h-5v25h5v-12Zm-4 14v-1h-1v1h1Zm-32-34v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm24 5v-2l1 2-1 1v-2Zm-1 14v-1l-3-1 1 2h2Zm-16 0v-1h-3v2h4l-1-1Zm17 3v-2h-2v3h2v-1Zm-16 1v-2h-4v2l3-1v2h1v-1Zm12-1v-2l-5-2-1 4 1 3 4-1 1-2Zm1 3 1-1-3 2v1h1l1-2Zm-16 2v-1h-1v1h1Zm20 2v-1h-1v1h1Zm-16-12v-1l3-1 1 1-3 2-1-1Zm9 10-4 1-3-6 2-5h6l-8-3-4 2-3 1 6 1v7l4 4 4-1Zm-12 2v-1h-1v1h1Zm20 2-1-1-3 1h4Zm-14-1h-1l-3 1h5l-1-1Zm-5 0h-1l-3 1h5l-1-1Zm-5 1-1-2v-15l1-3h24l1 4-1 17H80v-1Zm30-10v-12H86l23-1v-3l6-7H78l-3 5v5h2v-5l1 5 8 1H75v23l2-2v-20l1 24h31l1-13Zm-33 12v-1h-2v2h2v-1Zm39 3v-1h-1v1h1Zm-4 3v-1h-1v1h1Zm-2-1v-1h-9l-3-2v2l-5-1v3h17v-1Zm-18 0v-1l-5 1 1-2h-8v1l1 2h11v-1Zm-13-1v-2h-1v4h2l-1-2Zm76 5h-1l-1 1h2l-1-1h1Zm-9 1v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-4-1h-1l-4 1h6l-1-1Zm13 2v-1h-1v1h1Zm-3-2h-1v2l1-1-1-1Zm-39 3v-1h-1v1h1Zm2 1v-1h-1v1h1Zm-23 1v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm33 1v-1h-1v1h1Zm4 0 1-1h-4l1 2h2v-1Zm37 2v-1h1v1h-1Zm2 2h1l2-6-1-3h-5v11l1-2h2Zm-23-2v-1h1v1h-1Zm9 2v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-12 0v-1h1v1h-1Zm2-2v-3l1 6h21l-1-8h-24l-3-3-1 1v8l2 2h5v-3Zm0 10v-1l-5 1-7-7h-6l-1-2h-8l-5-6h-5l-2 3H81l-2-3h-3l-2-3h-7v-39l7-3 4-4h6l6-6h17l4 6h7l11-11h39l4 2v11h-16l1 2h-3v-2h-3v2h-3v-2h-4l-1 3-1-3h-4l-1 3-3-3h-2l1 2h-3v-2h-13l-6 7v1h5l1 3 7 1 1-6v7l-8-1v28l1 1 4-2 25-1v-20h-16l17-1v21h16l7-9 5-2-1-3 3 2v-16l-4-1h4v-4l-2-1-2-4 6 4v26l-6 6-5 6v13l-5 4h-6l-4 3-6-1v2l-4-1-2-1-1 1-4 1-1-1Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="M164 122h1l1 1h-3l1-1Zm-40 6v-1l1 1-1 1v-1Zm23 6v-1h1v1h-1Zm-4-1h1l1 1h-4l2-1Zm-4 1v-1h1v1h-1Zm-3-1h1l1 1h-3l1-1Zm39 8v-1h1v1h-1Zm-28-1v-5l1 5-1 6v-6Zm-23 6v-1h1v1h-1Zm-5 1v-1h1v1h-1Zm6 1v-1h1v1h-1Zm22 0v-2l1 2-1 1v-2Zm-19 7 1-1h4l-4 2h-1v-1Zm-7 1v-1h1v1h-1Zm17 0v-1h-1v1h1Zm-2 0v-1l2-1 1 1-2 2-1-1h1Zm33-45v-2l1 2-1 1v-2Zm0 3v-1l2 3v-9l-2-2h-39l-9 9v1h48v-1Zm-61 0v-2l-2-1-12-1v5h14v-2Zm-15-1v-2l-2-1-5 5h7v-2Zm-21 9-2-1h-2v3h4l1-1-1-1Zm-3 5v-1h-1v1h1Zm3 8h-1v2l1-1-1-1Zm101 11v-1h-1v1h1Zm-102-1v-1h-2l-1-3v5h3v-1Zm2 2v-1h-1v1h1Zm103 0 1-2h-2l-1 3h1l1-1Zm-60-9v-13h-5v25h5v-12Zm-46 10v-1h-2v3l2-1v-1Zm10-30v-1h1v1h-1Zm26 8h1l1 1h-2v-1Zm-4 1v-1h1v1h-1Zm-10-1h2l3 1h-8l3-1Zm3 5h-1l-3 1h5l-1-1Zm9 4h-1v2l1-1-1-1Zm-20 5h1l1 3v-4h-4l-1 5 1 1 1-5h1Zm20 7v-3l-2 3 1 1-6 1h7v-2Zm-20-11-2-1h3l1 2h-1l-1-1Zm6 7-1-3 2-5h6l3 3v4l-2 1v-5l-3-2-4 2v4l4 3h-3l-2-2Zm-7 5v-1h1v1h-1Zm7-1-2-2h-1v4l-2-3 3-3 4 4h5l-1-3 4 1 2-5v-2l-4-4-12-2-5 3 1 3h4l3-5h2l-3 4v5l-6 4-1 3h11l-2-2Zm-10 2-1-2v-15l2-3 23 1v20H80v-1Zm-3-9v-12l1 24h32l-1-30 6-6H78l-3 5v5h2l1-5v6h-3v25h2v-12Zm-7 12v-1h-1v1h1Zm1 1h-1l-2 1h3v-1Zm45 0-1-1-4-1v2l2 2h3v-2Zm54 0 3-2v-4h-2l1 3-3-1-3 7h1l3-3Zm-5 3h-1l-1 1h2l-1-1h1Zm-39 2v-1h-1v1h1Zm-23-3v-1h1v1h-1Zm-15 0v-1h1v1h-1Zm8 2h16v-2h-6l-2-2h-7l1 2-4-2-1 2-3-2H78v4l1 1 2-1h15Zm-24 1-1-1-3 1h4Zm5-1-1-2 1-2-2 1v3l2 2 1-1-1-1Zm78 4 1-1h-5v2h4l1-1Zm-6 0v-1h-4v2h4v-1Zm-9 0v-1h-8l3 2h4l1-1Zm-15 0-1-1v3l1-1v-1Zm-17 2v-1h-1v1h1Zm-15-2h-1v2l1-1-1-1Zm-2 1v-1h-3l1 2h2v-1Zm31-1-1-1-2 1 2 3 2-2-1-1Zm-3 3v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-4-2h-1v2l1-1-1-1Zm-2 0h-1v2l1-1-1-1Zm-17 2h-1l-3 1h5l-1-1Zm-4 1v-1l-4-1v2h4Zm-5-1v-1h-2l1 2h1v-1Zm84-1v-2l-2 4v2l2-1v-3Zm-43 3 1-1h-8l1 2h6v-1Zm-15-1h-1v2l1-1-1-1Zm5 2v-1h-4v2h4v-1Zm9 2 1-1h-4l-1 2h2l2-1Zm4 2v-1h-1v1h1Zm30-6v-1h1v1h-1Zm1 4v2h2l4-3v-7h-8l-1 2h-13v-3l-1 3h-8l-4-3-2 1 1 7-3 1h4l2 3 4-1 1-4v5h20v2l2-7v2Zm-10 4-1-1-3 1h4Zm-16 2h-1l-1 1h2l-1-1h1Zm20 1h1l-4-1v2h3v-1Zm-7 0v-1h-2v2h3l-1-1Zm-5 0v-1l-2 1v-2h-2v3h4v-1Zm-1 2h-9l-8-7h-5l-1-2h-8l-6-6h-4l-2 3H81l-2-3h-3l-1-3h-8v-40h6l-1-2h2l4-4h6l6-6h17l4 6h7l11-11h39l4 2v11h-16l1 2h-3v-2h-4l-1 3-1-3h-4l-1 3-2-3h-3l-1 3-2-3h-4l2 2h-3v-2h-13l-6 7v1h4l2 3 5 1h-5v30l6-1 1-2h3v3h19v-2l-3-1h3l1-2 1 2 5-1v2l-4-1-2 2 2-1 2 2h7l1-2 2 1-1-2-6 1v-2h9l9-10h6v-18l-3-1h3v-4l-2-1-3-4 6 5v24l-10 13-1 12-4 5h-6l-4 3h-12l-2 1-1-1Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M165 123v-1h1v1h-1Zm-41 6v-1h1v1h-1Zm23 5v-1h1v1h-1Zm23 12 2-2h1l-3 4h-1l1-2Zm-4 5 2-2h1l-1 3-4 1 2-2Zm-10 5v-1h1v1h-1Zm-30 0v-1l1 1-1 1v-1Zm45-45v-4l-3-2h-39l-1 3-3-1 2 2-6 4v2h50v-4Zm-61 4v-1h-1v1h1Zm-2-1v-2l-3-2H94v5h14v-1Zm-15-1v-3l-4 1h1l-4 4h7v-2Zm-20 20v-1h-1v1h1Zm0 2v-1l-2 1v-5h2v-4l-2 2-1-4 3 1v-4h-5v9l2 6v1h2l1-2Zm0 4v-1h-1v1h1Zm0 3v-1h-1v1h1Zm0 2v-1h-1v1h1Zm0 2-1-1v3l1-1v-1Zm-2 1v-3h-3l2-1 1-5h-3v12l3-1v-2Zm9-29v-1h1v1h-1Zm-3 6v-3l1 3-1 4v-4Zm27 9-1-1-12-1 8 2 4 4v4l1-8Zm0 9-1-1v6l1-3-1-2Zm-8 3v-1h1v1h-1Zm-6-2-1-3 2-5h6l3 2v5l-2 1 1-6-5-1-3 2v4l3 3h-2l-2-2Zm9 2 2-1 1-6-4-5h-6l-4 3 1-3h2v-2l-10 2v13l2-1v-5h2l1 3v-4h-5l5-1-1-2 3 1v6l4 4h5l2-2Zm-18 4h-1v-20l24 1 1 17-3 1 1-2-2-1-1 3h-9l-4-5h-1l-5 4v2h24l-1 1H80Zm-4-9v-12l1 24h32v-30l5-6H78l-3 4v32h2v-12Zm-4 13v-1h-1v1h1Zm-2 0v-2h-3v3l3 1v-2Zm45-12v-16h-5v27l3 4h2v-15Zm-45 16v-1h-2v2h3l-1-1Zm6-1v-1h1v1h-1Zm26 1h1l1 1h-4l2-1Zm-3 1v-1h1v1h-1Zm-16 0v-1h1v1h-1Zm-3 0v-1h1v1h-1Zm10 0v-1l2 2h17l-4-2h6l-1 2h2l-1-4-1-1-35-1-1 3 2 3h15l-1-1Zm25 2v-1l-3-1 2 2h1Zm-21 2v-1h-3v2h3v-1Zm28 1v-1l1 2 2-1v-3h-8v4h5v-1Zm-30 1h-1l-3 1h5l-1-1Zm-4 0 2-2v-1h-3l-1 3-2-3v2l-4-1v2l1 1h6l1-1Zm21 1v-1h1v1h-1Zm6 2 1-1-1-3h-4l3 2h-3v-3h-6v2l5 4h3l1-1Zm9 1 1-2v-1h-8v3l2 2h4l1-2Zm24-5v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm22 5v-1h1v1h-1Zm5 2v-1h1v1h-1Zm-2 2v-1h1v1h-1Zm-31-1v-1l2 1v1h-1l-1-1Zm6 0v-2l1 4h21v-4l1 4h3l3-1v-11l-9 1v-2h-11v4l-1-4h-2l-1 3h-2l1-3h-7l2 3-3-1v-2l-4 1-1 9 2 3h7v-2Zm-1 4v-1h-2l-3 2h5v-1Zm19 0v-1h-5v2l1 1h3l1-2Zm-7 1 1-2-4 1v2h3v-1Zm-6 0v-2h-4v3h4v-1Zm-14-1-3-4h-6l-1-2h-8l-6-6h-4l-3 3H81l-3-3h-2l-2-3h-7v-40h7l-3-2h3l4-4h6l6-6h16l5 6h7l11-11h39l5 3v10h-17l-1 3-2-3h-3l-1 3-2-3h-3l-1 3-2-3h-3l-2 3-1-3h-4l2 2h-2l-2-2h-13l-6 7v1l6 1v33h29l2-4v4h19l7-9-1-2 2 1 3-3v-24h-1l-1-2-1-3 2 2 2 3v24l-10 13v3h-3v8l2-1v4l-3 3h-6l-4 3h-24l-3-3Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="m165 104 1-1 2 2h-5l2-1Zm-26 0 24 1h-33l9-1Zm32 2v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-65 3 1-1h2v2h-3v-1Zm-4 0h1l1 1h-4l2-1Zm-4 0h1l1 1h-2v-1Zm-2 1v-1h1v1h-1Zm33-3 1-2-3 3v1h1l1-2Zm-3 3v-1l6-6-1 4-5 5v-2Zm-2 1v-1h1v1h-1Zm-14 0h1l1 1h-2v-1Zm63-1v-3l1 3-1 4v-4Zm-78 2v-1l1 1-1 1v-1Zm26 2v-2l2 1-1 2h-1v-1Zm-26 1v-1h1v1h-1Zm19 0v-1h4l1 2h-5v-1Zm-3 0v-2l2 1-1 2h-1v-1Zm-12 1v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-6 0v-1h1v1h-1Zm85 1v-1l2 1v1h-1l-1-1Zm-20 0h1l1 1h-3l1-1Zm-24 0-1-1-7-1h50l-1 1h-22l1 2h-2v-2h-4l-1 3-1-3h-4l-1 3-1-3h-4l-1 2-1-1Zm-60 3v-1h1v1h-1Zm40 1 1-1h1l-1 2h-1v-1Zm-33 1v-1h1v1h-1Zm33 2v-1h1v1h-1Zm-21-12v-1h-1v1h1Zm-16 11v-2l2-4 3-3h6l7-6 1 2h-3v3l-2-1-1 4h-7l-4 2-2 7v-2Zm43 5v-1h1v1h-1Zm-6 4v-1h1v1h-1Zm-33 0v-1l1 1-1 1v-1Zm22 2v-1h1v1h-1Zm11 1v-1l1 1-1 1v-1Zm-21-1 2-2h7l-7 1-4 4 2-3Zm6 2-3-1h6l1 2h-2l-2-1Zm-10 1v-1h1v1h-1Zm19 1v-2l1 2-1 1v-2Zm-21 0h1l1 1h-2v-1Zm27 2v-1h1v1h-1Zm-6 1v-1h1v1h-1Zm-15-1v-2l1-1v4h-1v-1Zm10 0v-2l1 2-1 3v-3Zm-12 0-1-2 2-1v5h-1v-2Zm17 3v-1h1v1h-1Zm-14 0v-1h1v1h-1Zm-10-7v-7l24 1 1 2-11-1H81l-1 13v-8Zm-13-2v-10l1 10-1 10v-10Zm17 9h-1v-3h2l-1 4v-1Zm32 1v-1l1 1-1 1v-1Zm-20 1v-1h1v1h-1Zm-29 0v-1h1v1h-1Zm22 1-1-1v-2l3 3-1 1-1-1Zm-9 0v-2l1 2-1 1v-2Zm96 0 2-1v-23l-3-3 4 1v25l-3 3h-2l2-2Zm-81 1 3-1 4-4-1-6 2 3v3l-6 6h-6l4-1Zm21 1v-2l1 2-1 3v-3Zm-14 1h1l1 1h-4l2-1Zm-5 0h1l2 1h-5l1-1h1Zm-6 1v-1h1v1h-1Zm-10-1h-1 7l3 1h-9v-1Zm-4-7v-8l1 8-1 9v-9Zm-10 7v-2l1 2-1 1v-2Zm100 2v-1h1v1h-1Zm-2 2v-1h1v1h-1Zm-56-1h1l1-9v10h-4l1-1h1Zm-36-13v-14l1 1 1 26 32 1H73v-14Zm-6 15v-3l1 3-1 3v-3Zm102 2v-1l5-6h2l-7 9v-2Zm-56-1-2-1 4 2v1h-1l-1-2Zm-45 4v-1h4v1l-3 1-1-1Zm58 1v-1l-7 1v-2h50l-1 2h-35v1h-7v-1Zm-36 4v-1h1v1h-1Zm30 0h2l3 1h-7l2-1Zm6 1v-1l1 1-1 1v-1Zm-45 1v-1h1v1h-1Zm23-4-1-1-3 1h4Zm-27 0v-1h-1v1h1Zm40 8v-1h-8l-5-6h-4l-4 3-5-3 6 1v-3H85v3l-2-3-3 1 1 3-3-3-1 2-4-5v-5l5 6h38v-2h2v8l-1-4h-11v2l4 4h7l2 2-1 1-1-1Zm41 4h-1l-1 1h2l-1-1h1Zm-3 1v-1h-6v3h5l1-2Zm-7 1v-2l-4 1-1 2h5v-2Zm-7 0 1-2h-11l1-1h31l5-3-2 4-6 1-6 2-13 1v-2Zm-12 0v-3l-3 1-3-4 3 1v-3l3 5 1 3h6l5 2h-11v-2Z" style="fill:';
    string private constant PART_10 = '"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(200, 40%, 47%)";
    string private constant COLOR_3 = "hsl(222, 0%, 63%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(220, 2%, 37%)";
    string private constant COLOR_6 = "hsl(223, 6%, 24%)";
    string private constant COLOR_7 = "hsl(213, 9%, 20%)";
    string private constant COLOR_8 = "hsl(213, 10%, 18%)";
    string private constant COLOR_9 = "hsl(223, 10%, 13%)";

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
            PART_10
        );
        return string.concat(chunk1, chunk2, chunk3);
    }
}
