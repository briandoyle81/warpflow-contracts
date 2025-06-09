// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderForePerfect {
    string private constant PART_1 =
        '<path d="m30 125-7 5 58 23 5-5 1-4 4-3v-17l-1-3-2-9-34 1-24 12z" style="fill:';
    string private constant PART_2 =
        '"/><path d="M59 117h-1l-1 1h2v-1Zm-3 1v1-1Zm-1 1h-1v1h1v-1Zm-4 1Zm-5 3v-1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-10 5v-1h-1v1h1v-1Zm-3 1 1-1-3 1v1h1l1-1Zm-3 1h-1 1Zm54 2v-1h-2v2h2v-1Zm-33 4-1-1-1 1h2Zm-38 46 2-4 11-20 4-5 1 5h3l4-4 1 1v-3l-1-2-2 3v-5l-3 3-1-5-2 1-2 4-1-3-2-12-6-4v-2l3-3 2-1 23-21-1 7 15-14h1v1l-2 4-2 6-1 2 31 1h1l3 13v16l-4 3v3l-3 3-4 3-6 1-2 2v5h-5l-4 5v1l-4 3h-5l-2 2-24 5-10 3h-3l-3 3v-1Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M54 106h-1 1Zm28 6h-1l-4 1h6l-1-1Zm-6 0h-1l-3 1h5l-1-1Zm-5 1h-1l-1 1h3l-1-1Zm-3 2 1-1h-2l-4 1h5Zm-3 2v-1h-1v1h1Zm21 1v-1h-1v1h1v-1Zm-2 0h-2l-3 1h6l-2-1Zm-6 0h-1l-3 1h5l-1-1Zm-30 0h-1v1h1v-1Zm25 1 1-1-4 2h-1 2l1-1Zm-36 3-1-1-1 1h2v-1Zm22-5v-1h1v1h-1Zm-7 5h1l-1-1h4v-1l3-2-2 3 6-3-2-1 2-1h-4l-9 3-2 1h-4l3 1h2l1 1h-2l-1 2 3-1 1-1Zm17 1h-1v2l1-1-1-1Zm12 1 7-1H74l-2 3 2-2h7Zm-20 4v-1h-1v1h1v-1Zm4-6v-1h1v1h-1Zm-16 5v-1l2 2 3-1 4-4-1 2h3l-1-1h4l6-3-1-2-1 2-2-1-1 2-2-1v2h-1l1-3h-3l-10 4-1 2h-3v2h5l-1-1Zm-5 1v-1h-1v1h1v-1Zm25 0-2 1h3l-1-1Zm-3 1v-1l-1 2 1-1Zm-34-3v-1h1v1h-1Zm-1 4 3-2 3 1-1-2h3l3-3h3l1-3h-1l-1 2h-2l2-2h-1l-2 1 1 1-3 2 1-3-5 2-3-3 1 3-2-1-1 5-1-2h-3l4-2v-1h-2v2l-2-1-2 1v2l-2-1v2h-2l-1 3h6v-2h2l-1 1 1 1 4-1Zm31 1 2-1h-3l-2 2h1l2-1Zm-21 1v-1l-2 1h3-1Zm39 0v2h2v-1l1-2h-4v3l1-3v2Zm-22 2v-1l-4 1v1h3v-1Zm-7 1h2-7v1h2v2l1-2 2-1h1Zm-9 3 3-1-1-1-9 2h7Zm46 2 1-1h-1l-1 1h1Zm-8 0h-1 1Zm-32 0-1-1v3l1-1v-1Zm-12 2v-1h-1v1h1Zm10 11v-1 4l1-2-1-1Zm-10 4h-1v1h1v-1Zm-10 1h-1v1h1v-1Zm19 0v-2 4l1-1-1-1Zm-1 3v-1h-1v1h1Zm-9 0v-1h-1v1h1Zm6 1 2-1h-3l-2 2h1l2-1Zm-29 19 7-14 1-1 3-8 5-5v5h4l4-4 1 1v-5h-1v2h-2v-4l-2-1-1 5-1-6h-3l-1 5-1-2-2-13-6-4v-2l10-9 2 1-1-2 2 1v-2l15-14-1 10-1-1-3 2v1l3-3v2l-5 5 2-1 8-9-3 1v-1l5-4 10-9v1l-4 12h30l2 2 1 5h-2l1 1 3 6v15l-5 4v4l-7 5-5 1-3 1 1 5-7 2-6 8h-6l-1 2-22 4-15 5-2 1h-1Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="m54 106 1-1h-1l-1 1h1Zm-3 2v-1 1Zm33 4h-3l-4 1h9-3 1Zm-8 0h-1l-3 1h5l-1-1Zm-5 2 1-1-5 1-4 1h6l1-1Zm0 3v-1h-1v1h1Zm-36 1v-1h-1v1h1v-1Zm-1 1-2-1 1 1h1Zm8-4h1-1Zm3 0 5-5v-2l-2 3-2 1-6 4v1l1-1-1 3-2-1v1l1 1h1l5-5Zm36 9 7-1H74l-2 3 2-2h7Zm-12 1 1 1-1-3h-1l-2 4 2-2h1Zm-7 2h-1l-1 1h2v-1Zm-1-10v-1h1v1h-1Zm-4 6h1v1h-1v-1Zm-8 4v-1l2 2 14-5h1l-1-1h5l-3-3 2-1-4 2 2-2h-2l-4 3v-1l-10 4h-1v-3l2 1 6-2 7-3-2-1h-7v1l-2-1v2l-2-1v2l-4-1-3 2 4 2-2 2h2l-6 4h7l-1-1Zm31 1h-1v1h1v-1Zm-24 1v-1 3l1-2h-1Zm-24 1h-1 1Zm8-7h1v1h-1v-1Zm-12 2 3-1v1h-3Zm8 3v-1 1-1Zm-3 0h1v1h-1v-1Zm-3 2 2-2v2l6-2h3v-4l1 3 5-3v-3l-3 1v-2l-9 4 4-3-2-2-1 1-4 1v-2l-4 3v2l-1-1-6 5h-1l-1 3 7-1 1 1h1l2-1Zm33 0 3-1h5l-3-1-7 2-2 2 4-2Zm-7 2v-1 1Zm-15 0v-1l-2 1h3-1Zm39 0v-1l1-1 1 1-2 2v-1Zm3 0v-2h-2l-3 2 3 3 1-1v-2Zm5 8 1-1h-1l-1 1h1Zm-4 0h-9 12-4 1Zm-49 0h1-1Zm1-1h-1l2-1v1l8-1v-3l1 3 2-2-1 7 2-6 2-1 6-2 1-1-5 2h-9l-9 3-1 2 1 2 1-2Zm13 4h-1v1h1v-1Zm-14 0v-1 3l1-1-1-1Zm32 2h-1 1Zm-31 1v-1h-1v1h1Zm10 7v-1 5l1-2-1-2Zm-10 4v-1h-1l-1 2h2v-1Zm-10 1 1-1h-1l-1 2h1v-1Zm25 2 1-1h-1l-1 1h1Zm-7 1 2-1v-3l-2 3-5 1-1 2 6-2Zm-9-1-1-1-1 4 2-2v-1Zm-3 2h-1v1-1h1Zm5 2h-1 1Zm-3 1h1-2v1h1v-1Zm-22 16 7-14 2-1v-3l1 1-1-2 3-5 4-4v7l2-2 2 1 4-5 1 1v-5h-1v2h-2v-4l-2-1-1 5-1-6h-3l-1 5-1-2-2-13-6-4v-2l28-25-1 7 15-14v1l-4 12 31 1 2 1v3h-3v2H72l-1 2-2-3v4l3-2h12l4-2 1 1h-3l2 1 3 6v15l-5 4v4l-4 2-3 3h-5l-4 2 1 5-6 2-7 8h-5l-1 2-23 4-15 5-1 1h-2v-1Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="m18 174-4 4-1 3 6-3 15-13h-3l-13 9zM38 130l-4 3 3 1h4l3-4h-6z" style="fill:';
    string private constant PART_6 =
        '"/><path d="m83 112 2-1 2 1h-5 1Zm-4 0v-1h1v1h-1Zm-5 0 2-1 2 1h-5 1Zm-35 1v-1l-5 5 1 2 4-4v-2Zm32 7h1-1Zm-2 4h1v1h-1v-1Zm-1 2v-1h3l-1-2h2l1-2h7l5-2h1l-4-3H71l-3 2 3 2-1 2-3 4v1h2v-1Zm-6 1h-1l-1 1h2v-1Zm18 1h-1v1h1v-1Zm3 1v-1h-2l2 1h1-1Zm-29 1h1-3l1 1h1v-1Zm14 2v-1h-1v1h1Zm-45 0-1-1-2 1h3Zm62 1h-1v1h1v-1Zm-14-2v-3h-5l-4 2-4-2 3 3 5-1-1 2 5-4-1 5 1 1h1v-3Zm-18 2v-1l-3-5v4h1v3h2v-1Zm-12-1 1-2h-2l-4 2 1 2h3l1-2Zm42 0v-2l-2-1-3 3 2 3 2-1v-2Zm-14 2h-3 3c0 1 0 0 0 0Zm-26 0h-1 1Zm41 1h-1 1Zm-3-11 7-1H74l-2 2 1 12v-13h8Zm7 16 1-1-14 1h13Zm-15-2-1-1v4l1-2v-1Zm-3 2 1-1-4-1-1 1h3l-2 2h2l1-1Zm-37-1v-1h-1v4l1-3v-1Zm18 3v-1 1Zm1 2h-1 1Zm29 3v-1h-1v1h1Zm-6-1-2-1-4 2h9l-2-1Zm-9 0v-1h1v1h-1Zm2 0-1-1-2-1-3 3h6v-1Zm-17 0 1-1h-1l-1 2h1v-1Zm10-29v-1h1v1h-1Zm3 1h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm16 4v-1l5-2h1l-6 3Zm-2 0v-1h1v1h-1Zm-2 0 1 1h-2l1-1Zm-14 0v-1h1l-1 2h-1l1-1Zm9 2v-3h2l-2 3v1l-1 1 1-2Zm-19 1h1-1Zm13 0v-1l1 1-1 2v-2Zm2 2v-1h1v1h-1Zm14 4v-1l1 1h-2 1Zm-1 4h1-1Zm-10 0h1-1Zm5 1v-1 1h-1 1Zm-2 2v-1h1l-1 2h-1l1-1Zm-7 0h1v1h-1v-1Zm3 1-1-1h3v2l-2-1Zm-10 1 1-1h1l-1 1h-1Zm14 3h1v1h-1v-1Zm-13 3v-1h2v-3l1 1 2-3h3l5 2v4l1-3-1-2 2-3h3v2l3-4h3l-1-2h4l-2 2 3-1-1-3-4-1-4-3 1-2 11-4 2-1-6-6-8 1-11 3 1 2-2 1 2-2-4 1v-2l16-17h-1l-7 7-12 9-1 1-4 2h-1l3-2-2-1-14 12 6 1 3 1 4 4-2-3 2-3h3l6-2h7l2 2v-4l4 3 2-1v2l-2 2 1 1 5-2 1 2-2-1-2 2-8 1v-2h-2l-3 3-8 1h-1v10h2v-1Zm15 8Zm-2 2v-1h-1v1h1Zm17 1h-1v1h1v-1Zm-8 1h4l-4-1-6 1 2 1 1-1h3Zm-31-2h-1l-2 3v2l3-4v-1Zm24 4 1-2-3 3v1l2-2Zm0 2v1-1Zm-6 2 1-1h-1l-1 1h1Zm-21 0v-2l-1-1v1l-2 3h2l1-2Zm17 2v-1h-1v1h1Zm-9-2v-1h2l-1 1h-1Zm6 0 5-3 2 1v-2h2v-2h-1v-7 6h-2l-1 3-5 1-3 3h-1l1-4 1-5-3 3v2h-2l1 1-2 3 3 2 5-2Zm1 3v-1h-1v1h1Zm-17 1 4-2-2 3h-2v-1Zm1 2 4-2v-2l4-4-2-2-3 2v-1l-3 5h-2l-4 7h2l4-3Zm-2 4 7-4 4-4h-1l-17 12v2l4-4 3-2Zm-9 7v-1l5-9-1-1 3-2v-2h1l3-8 5-5v7l1-2 3 1 4-6 1 1 1-2-2-2-1 2h-1v-4l-2-1-1 5-1-6h-3l-1 4-1-1-2-13-6-4v-2l28-25-1 7 16-14v1l-5 12 5-1v2h12l-8 3-2-1 4 3 2-1-2-1h4v-1l6-1h12v3h-4l3 5 4 3v16l-5 4v4l-6 5h-6l-3 3v4l-6 2-7 8h-5l-1 2-23 4-15 5-1 1h-2v-1Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="M71 113v-1 1h-1v-1h1Zm-20 0v-1l1 1-1 1v-1Zm9 2 1-1 1 1h-2Zm10 1 1-1h13l2-1 2 2h-1l-18 1 1-1Zm-5 1-1-1 3 2 1-1-1 2-1-2Zm-29 1v1-1Zm23-18h-1 1Zm-17 10-1 1v1l1-1Zm-12 9 15-14-1 7 15-14 1 1-4 12v1-1l7 2 1-1-1 2h-3l-4-2 3 3h-1l-13 4 3-2v-6l1 5h2l2-2h-1l3-3 3-10v-1l-12 12-7 5v-5l-6 6-3 2v-1Zm14 1-2 1 1-2h2l1 2h-1l-1-1Zm24 1v-1h2v1l-2 1v-1Zm-21 1v-1l1 1-1 1v-1Zm20 1h1v1h-1v-1Zm-21 1h1v1h-1v-1Zm20 2v-1 1h-1 1Zm-9 0v-1l1 1h-2 1Zm-33-1 2-3 3-2-8 8 3-3Zm35 2v-1l2 1v1h-1l-1-1Zm-42 4v-1l4-3-3 5h-1v-1Zm51 1v-1h-1v1h1Zm-2 0v-2h3v4h-3v-2Zm-14 2h1-1Zm-4 10-1-1 2 1h-1v-1Zm16 3h1l1 1h-2v-1Zm-13 10-1-1 1-1 1 3h-1v-1Zm7 1h1l1 1h-3l1-1Zm3 1h1-1Zm-7 3h1l1 1h-2v-1Zm-32 0v-1l1 1-1 1v-1Zm22 1h1v1h-1v-1Zm-16 2 3-3-2 3h-1Zm-7-1v-1l1 1-1 2v-2Zm13 5 1-1h1l-1 1h-1Zm-12 3v-1h1v1h-1Zm-6 1 1-2h-1l3-3v-2l1 2-3 5-2 1 1-1Zm25-41 1-2h-2l-4 2 1 2h3l1-2Zm21 9-1-1-1 1h2v-1Zm11-18h1v1h-1v-1Zm14 8-1-2v5l1-2v-1Zm-4 2v-2l-3-2-2 3v-2l3-2 4 4-2 2v-2Zm-5 0h1v1h-1v-1Zm4 2h1-1Zm-3 0 1-1 1 1h-2Zm6-2 1-2-3-3h-4l-2 3 1 4 4 2 3-2v-2Zm-1 7-4-1 4-1 3 1v-2l-2 1v-2l-2 2h-3v2h-5v-14h13l1 14h-1l-4-1Zm5 1 1-1v-13l-3-3 4 1-2-1H76h13l1-2H73l-1 2 2 1v14l2 2-3-1v-16h-1l-1 15 3 3h14l1-1Zm-61-3h1v1h-1v-1Zm2 2v-2l-3-1 1-2-2 1v2l2 4h2v-2Zm37 2-1-1 5 1-1-4h-5l4 1-4 1 1 3h1v-1Zm-9 5h1l-1-4 2-1v3h1l1-2 2 1-1-2h-3v-2l-3 3v3l-3 3 4-3v1Zm-17 0v-1l-1 1v2l1-2Zm18 2-2-1v1h2Zm-13 0Zm-3-1v-2h-1v3h2l-1-1Zm0 3-1-1-1 1h2v-1Zm1 1h-1v1h1v-1Zm-4-2v-1 4l1-2-1-1Zm31 3v-1l-1 1v1h1v-1Zm-2 1v-1h-3l-1 1h4Zm-10 2v-1h-1v1h1Zm-19 1 1-2 1 1 1-1-1-3-2 5h-2l1-2-2 1 1 2h2v-2Zm1 2Zm7 2h-1l-2 1h3v-1Zm16 1h-1v1h1v-1Zm-2 2h-1v1l1-1Zm-11 6v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm8 1v-1h-1v1h1Zm-37 10 3-6h2l2-2h2l-7 5v1l12-8-1-1 2-2-2 2h3l-1-2 3-2-2 3h1l2-2 1 1-6 5 7-1 5-2v-1l-3-3 4 3 6-1 1-2h4l-1-3-4-1-1-2h3l4-3-2 4 2 3v2h6l2 2 1-1h-2l1-3 3-4h2v-1h6v-2H52l4-2 2-4-1-1-3 3-1-2-2 2 1 1h-3l-3-3-4 9-3 2-3-2v-3l-1-1-5 7v-2h-4l-2 3 1-3 2-1v-5l-5 6 2-3 4-4v6l2-2 1 2 5-6 2 1v-4h-3v1h-1v-3l-1-2-2 5v-3l-1-3 1 3v-3h-4l-2-8-1 1 2 7 1 1-1 4-1-2-2-12-4-4 7-1 5 6 1-2-1-4 14-3 2 1 5 5-4-3-2 2h-1l1-2h-2l-1 2-7 2h6l2-2 1 1-2 1-7 1h-2l-3 1 1 3v2l3-5-1 6 1 6 4-5 2-5 4 2 5 9 2 1-1-2h1l1-7 3-5 3-1 11-1v-8l-8 2-5 4h-4l4-1 4-4 10-2-1-4 1 1 2-2h13l-1-4h1v4h2l3 3v16l-5 3H67l-4 1-4 7v1h5l4-6h17l1-2v3l-3 1-1 3-4 1h-4l-3 3v5l-6 1-5 6-2 2h-5l-1 2h-4l-10 3-3-1v1h-3l-18 6-1 1h-2Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M71 113v-1 1h-1v-1h1Zm-23-1v-1l1 1-1 1v-1Zm13 1h1v1h-1v-1Zm-10 0v1h-1v-1h1Zm9 2 1-1 1 1h-2Zm-12 0v-2l1 2-1 1v-1Zm25 1 1-1h10l3-1 1 2H73Zm-3 0v-1l3 1-4 1 1-1Zm-5 1-1-1 3 2 1-1-1 2-1-2Zm-6-17h-1 1Zm-17 11 1-3-3 4 1 1 1-3Zm-12 8 15-14-1 8 16-15-1 3-4 10h2l2 1h-3l-1 2 2 1 2-2h2l-3 2-12 4 2-3 1 1 5-3h-1l4-10 1-4-10 10-10 7 1-5-6 6-4 2 1-1Zm13 1 1-1h1l-3 2 1-1Zm25 0h2v1h-1Zm-21 2v-1l1 1-1 1v-1Zm20 1h1v1h-1v-1Zm9 1h5-7 2Zm-30 0h1v1h-1v-1Zm20 2v-1 1h-1 1Zm-42-1 2-3 3-2-8 8 3-3Zm35 5h2l-1 1h-1v-1Zm-42 1v-1l4-3-4 5v-1Zm51 1-1-1v2l1-1v-1Zm-2 0v-2h3v4h-3v-2Zm-12 1 4-1-1 2h-3v-1Zm-2 1h1-1Zm-30 1Zm20 0 1-1 2 1-2 1h-2l1-1Zm40 4h4-6 2Zm-7 2v-1 1Zm-33-9 1-2h-5c1 1-3 2-3 2v2h5l2-2Zm-12 8v-3h-2l1-2-3 1h-2l1 1 3 5h2v-3Zm1 4-1-1-1 1 2 4 1-3-1-1Zm3 6v-2l-2-1-1 5-1-6h-3l-1 4-1-1v-6l1 3h1v-5l-3-4 1 6-2-2v-7l-3 1-1-3h7l5 5 2-2-1-4 6-1 9-1 2 3-5 2 1-2h-1l-4 3h-4v1l5-1-1 1-6 1-3 1v5l2-1v-2l1-1v9l2 4h-2v-2Zm20 2h1v1h-1v-1Zm-3 5-1-1 2 1v1h-1v-1Zm7 1 1-1 1 2h-2v-1Zm-13 3v-1l1 1-1 1v-1Zm-23 1v-1 1Zm27 1-1-1v-2l3-3-2 4 2 2h-1l-1-1Zm-5 0h1v1h-1v-1Zm29-40h-1v1h1v-1Zm4 6-1-1 7-2-7 1-1 3h3l-1-1Zm4 1-2-1h3l2 2h-1l-2-1Zm-3 2v-1h1v1h-1Zm4 3h1-1Zm-3 0 1-1 1 1h-2Zm5 1 1-2v-3l-2-3h-4l-3 3 2 5 2 1h3l1-1Zm-27 5v-1h-1v1h1Zm6 0v-1h-4v2l4-1Zm4 0h1l1 1h-3l1-1Zm3-1 1-2h-5l-1 1 1 4 4-1v-2Zm-15 5v-1 2l1-1h-1Zm-10 1v-1l-2-1 1 2h1Zm-4 1v-3l-1 1v4h1v-3Zm-3 2h-1 1Zm10 0-1-1-1 1v1l1-1v2l1-1v-1Zm-7 2v-2l-2 3v3l2-3v-1Zm1 8v-1l-2 1h2Zm-4-2v-1h1v1h-1Zm5-3 2-3v-1l-2 1v-2h2l-2-1 1-1-2-1v2l-1 7-3 1-1 3 5-2 1-3Zm-18 8 1-2 1-1v-4l-5 6 2-4 4-4v6h2l-1-1h2v2l5-6 2 1v-4l-2-1 2-4 1 1-1-2 3-6 4 3 1 2 5 7v-1l3-9 3-3 10-1 3-1v-8h-4l-3 2-2-2 9-1v-4l1 1 2-3h12v-4l1 1v3h2l3 3v16l-2 2-2-4v-10h-3l3-2h-2l-1 2 2 2v7l-1-1-1 2h-4l-1 2v-2l-3-4-1 6v-14h13l1 14 1 1v-15l-2-2 3 1-2-1-3 1 3-3H73v17-14l-2-2v17l3 2h14l-1 2H65v-2h-5v2l-2-2h-3v2l2-1-1 4 2-1-1 2-1-1-1 2 1 3-3-1-4 4-3-4-4 9-3 1-3-2v-3l-1-1-4 7v-2h-4l-3 4 1-2Zm-4 2Zm30 1h-1 1Zm-22-1h1l-1 1h-1l1-1Zm8 4-1-1 2 1h-1v-1Zm-3 1 1-1h1l-1 1h-1Zm-7 3v-1l5-5-1 3-4 3Zm0 1h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm-3 0 1-2h-1l3-3v-2l1 2-3 5-2 1 1-1Zm56-25-1-1-1 2h2v-1Zm7 1h-1 1Zm-3 0h-1 1Zm-7 1h-1 1Zm5 0h-1l-1 1h2v-1Zm-2 3v-1h-2v2l-2-2-3 1v2h6l1-2Zm-12 1h-2 3-1Zm1 2-1-1-2 1h4-1Zm-9 14v-1h-2v2l2-1Zm-3 0v-1h-3v2h3v-1Zm-11 4 1-1 4-3-3-1 10-3h2l-1 3 4-1-1-2h4l-3 2h4l1-1h-2l3-5 4-3 6 1v-3H53l4-1 2-9 3-2-3 1-1-2 2 1 3-1v1l-4 7 4 2 5-7h19l-5 2h1l-3 4h-5l-4 3v5h-5l-5 5v-2l3-2h-2l-2 2 1 4-3 2h-5l-1 2h-4l-10 2h-2 1Zm-23 1v-1h1v1h-1Zm11 0 1-1h-3l-3 3h5v-1Zm-14 6 2-5h2l-3 3 1 1 6-4v1l4-3 3-3-1 2 1 2h4l-2-1v-1h2l1 2 2-2-2-1h2l4-1-4 2 1 2h-3l-18 5-1 2h-2v-1Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M55 103v-1l3-2-3 3Zm2 2v-2l2-3-1-1 1 1-2 7-1 1 1-3Zm-7 2v-1l3-2-2 3h-1Zm-6 1v-1h-1v1h1Zm-1 0h-1l1-2h2v3h-2v-1Zm12 1 1-1 1 1-2 2v-2Zm-15 1 1-1v1h-1Zm18 2v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-2 1v-2l1 2-1 1v-1Zm29 3 4-1 1 1h-5Zm-3 0 1-1 1 1h-4 1Zm-41-2v-2l-3 2 2-3 3 3v-1l3-4-1 3h1l4-4h2l-11 8v-2Zm30 2 1-1 1 1-3 1 1-1Zm-37 2 4-4-3 4h-2Zm34 0h1v1h-1v-1Zm-20 0 8-3h5l-13 4v-1Zm-16 1h1v1h-1v-1Zm38 1v-1l2 1v1h-1l-1-1Zm-21 2v-1h1v1h-1Zm-20 0v-1h2l-1 1h-1Zm62 1v-1H73l12-1v-4l1 1v3h3l1 2-1 1v-1Zm-43 1h1v1h-1v-1Zm-23 1 2-2h1v1l-5 3 2-2Zm66 1v-1h-1v1h1Zm-1 1-1-1H75l13-1-1-2 3 3-1 2h-1v-1Zm-8 1v-1h1v1h-1v-1Zm3 0h1v1h-1v-1Zm-6 0 3-1-1 2h-2v-1Zm-58 0 1-1h1l-1 2h-1v-1Zm62 1h1-1Zm-18 0 1-1 6-1-5 2-3 1 1-1Zm-4 1h2l-1 1h-1v-1Zm7 1v-1h3v1l-3 1v-1Zm-49 0v-2l1 2-1 1v-1Zm73-1v-2l1-4v9l-1-3Zm-23 3h1l1 1h-3l1-1Zm-11 0h1v1h-1v-1Zm-1 0h1v1h-1v-1Zm-33 0 1 1h-2l1-1Zm-3 0v-1l2 1v1h-1l-1-1Zm67 0v-2l-2-3 2 3v4-2Zm-34 1h1-1Zm38 1v-2l2 2-2 1v-2Zm-47 0h1-1Zm-2 1v-1h1v1h-1Zm-1 0v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm-7-1-1-1 2 1v1h-1l-1-1Zm-3 0 1-1h-2v-2l2 1v3h-2l1-1Zm-4 0-1-1 2 1v1h-1v-1Zm69 2v-1 2l-1 1v-2Zm-56-4h1v1h-1v-1Zm7-1 2-2-8 1-2 2 1 1h6l1-2Zm-12 6v-1h2v-2h3l-2-1-1-3 8-1 6-1 2 1v2l-4-1v1l-4 2h-4l-6 5v-1Zm58-4v-5h1v10l-2 1 1-6Zm-8 5h1-1Zm-5-6v-6l1 3h1l-1 2 2 4 4 1 2-2h2l-3 3h-4l-3-4-1 6v-7Zm-2 5v-2l1 2-1 2v-2Zm-39 1h1-1Zm25 1h1-1Zm-36-1v-2h2l1 2-2-1 1 3h-2v-2Zm66 2 1-1h1l-2 2v-1Zm-32 0v-1l1 1-1 1v-1Zm2 1h1v1h-1v-1Zm-35 0h1v1h-1v-1Zm49-19h-1v1h1v-1Zm-8 20v-1h-5l4-1v-2h-8v3h-1v-2l2-2h8v-1h5v-14l1 1 1-2 1 1v12-10l-2-2v17l2 2h14v2H70v-2l1-1-1-3h-5v4l4 1-3 1-1-1Zm-37 0-1-1 2 1v1h-1v-1Zm34 2h1l-1 1h-1l1-1Zm-34 1 1-1 1 1h-3 1Zm25-1v-2h1v3l-2 1 1-2Zm-10-2h-1v1h1v-1Zm-1 3v-1l-1-1-3 2v-1l3-4v1l2-2 4 5-3-1-3 4 1-2Zm-9 1h-1v-3l-3-2 1-2v3h2l2-3v8l-2-1Zm26 3v-1l1-2 2 1-3 3v-1Zm-18 0h1-1Zm-2-1v-2l1 2-1 2v-2Zm-14 1v-7l1 7h-1Zm12 1-1-1 1-2 1 3h-1Zm-7-2v-2l2 1v1l-1 2-1-2Zm22 2v-1l2-3 2-1-2 3h-2l-1 3v-1h1Zm-18 0v-2h1v3l-1-1Zm24 1h1v1h-1v-1Zm-14 1 1-1v-7h2l4 8-2 1-2-3 2 1v-3h-2v-2l-1-1v6l-2 3v-2Zm-6 0v-1l1 2-1 1v-2Zm-11 1h1-1Zm44 1h1-1Zm10-6h-1 1Zm-10 2 1-3h-3l-2 3h4Zm6-1v-1l1 1h-2 1Zm3 1-1-1 1-2h-4v2l3 2 3-1h-2Zm-5-1v-2h-2l-1 2v2h3v-2Zm-7 6-1-1-2 1h3Zm-10 0h5l-6-1v-1l3 1v-2l3 2 2-3 4-5h17l-1 2-3-1v3l-2 1H66l-1 3h5v2H53l5-1Zm-31 0v-1l1 1-1 1v-1Zm15 2 1-2 1-1v2l-2 3v-2Zm-15 1v-2l1 2-1 1v-1Zm21 1h1-1Zm-11 0v-1l-2-6 2 2v5l3-1v1h-3Zm-8-1v-1l2 2 4-5-1 3-3 2h-2v-1Zm-6 0 1-2 2-2v1l-4 5 1-2Zm46 2 1-1 1-3v4h-4 1Zm-5 0-1-1 2-1v3h-1l-1-1Zm-33 1v-1 1Zm18 0h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm19 1h1v1h-1v-1Zm19 1v-1h2l-1 1h-2 1Zm-42 0Zm30 1h-1 1Zm10 1v-1h1v1h-1Zm-2 0v-1l3-4v1l-3 4Zm-10 1v-1h1l2 2h-2l-1-1Zm-30 0v-1l1 1-1 1v-1Zm26 1h1v1h-1v-1Zm-28 3v-1h1v1h-1Zm35-1v-1h-2v2h1l1-1Zm-3 1v-1l-2-2 1-2v2h6l4 1 2-2h2l-4 3h-5l-1 2h-4l1-1Zm-33 2h1v1h-1v-1Zm24 0 2-1h1v-3h-3l4-1v5h-3l-3 1 2-1Zm-5 2v-1h1v1h-1Zm-20 0v-1h1v1h-1Zm14 1v-1h1v1h-1Zm-4 1 3-2v2l-3 1v-1Zm-2 0h1v1h-1v-1Zm-4 2h1-1Zm-2 0v-1l3-2v1l6-4-5 4v2l-2-1-2 2v-1Zm-5 3v-1l1-4 3-1-3 3v1l3-1v1l-2 1-3 1h1Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="m39 132 2-1v2l-2-1z" style="fill:';
    string private constant PART_11 = '"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(222, 0%, 63%)";
    string private constant COLOR_3 = "hsl(50, 3%, 49%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(13, 67%, 40%)";
    string private constant COLOR_6 = "hsl(223, 6%, 24%)";
    string private constant COLOR_7 = "hsl(213, 9%, 20%)";
    string private constant COLOR_8 = "hsl(213, 10%, 18%)";
    string private constant COLOR_9 = "hsl(223, 10%, 13%)";
    string private constant COLOR_10 = "hsl(10, 46%, 58%)";

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
            PART_11
        );
        return string.concat(chunk1, chunk2, chunk3);
    }
}
