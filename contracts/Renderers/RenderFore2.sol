// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderFore2 {
    string private constant PART_1 =
        '<path d="m41 120 2-2-4 2-1 1h2l1-1Zm47 38H60l-2 2-3 2H14l-2-2-2-2 1-4v-2l1-2 3-3 3-2v-4l2-1 2-2v-3l-1-3v-1l-2-2-2-2v-3l1-3 7-6h4l2-3 2-2h37l3 2 2 2h8l2 1 1 1v6l-5 4v2l3 2v3l2 1 1 1 1 5-3 4-2 2 1 3 4 2v7Z" style="fill:';
    string private constant PART_2 =
        '"/><path d="m41 120 2-2-4 2-1 1h2l1-1Zm-17 11h-1v1h1v-1Zm1 3v-1h-1v1h1Zm12 1v-2l-2-1-3-1h-1v1l1 3h3v1l-2 1h-1 5v-2Zm-11 1v-1h-1v1l1 1h1l-1-1Zm17 0v-1l1 1h-1v1-1Zm4 0 3-1v-3l2 1-2-1-1-2h-4v2h4-2l-1 1h-2l-2 1h-2l1 2 1 2h3l2-2Zm-7 2v-1l-2-1v2h2Zm34 4v-1h-1v2l1-1Zm14 16H60l-2 2-3 2H14l-2-2-2-2 1-4v-2l1-2 3-3 3-2v-4l2-1 2-2v-3l-1-3v-1l-2-2-2-2v-3l1-3 7-6h4l2-3 2-2h37l3 2 2 2h8l2 1 1 1v6l-5 4v2l3 2v3l1 1 2 1 1 5-3 4-1 2v3l4 2v7Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M44 113v-1h-1v1h1Zm14 0v-1h-9l-1 1h3l2 1h6l-1-1Zm-24 0h-1v1h1v-1Zm-7 4 1-1-4 2-3 3 3-2 3-1v-1Zm30 0h1l1 1h-3l1-1Zm0 3 5-2h-1l-1-1h19l-1-1H30l1 1h1l-1 1v2l2-2 1-1h7l-2 2-3 2 1 1h7l7-1 6-1Zm-13 5-6-1-1 1-1 1 7-1h7-6Zm-20 6h-1v1h1v-1Zm1 3v-1h-1v1h1Zm12 1v-2l-2-1-3-1h-1v1l1 3h3v1l-2 1h-1 5v-2Zm-11 1v-1h-1v1l1 1h1l-1-1Zm17 0v-1l1 1h-1v1-1Zm4 0 3-1v-3l2 1-2-1-1-2h-4v2h4-2l-1 1h-2l-2 1h-2l1 2 1 2h3l2-2Zm-7 2v-1l-2-1v2h2Zm-18 3v-1h-1v1h1Zm52 1v-1h-2l1 2 1-1Zm-8-2 2-2 2-1v-1h-2l-2 2-2 2v3l1-1 1-1v-1Zm-3 7 2-1v-1l-1-1-2 2-3 2h3l1-1Zm-27 1v-3l3-2 5-1 5-1v-1l5-2 3-2 3-3h-2l-12 7H30l8 1v2h-3l-2 1v6h3v-2Zm6 4v-1h-2v2h2v-1Zm6 1 2-1 3-2 3-1v-2l-2 1-1 1-8 6h2l1-2Zm38 5H60l-2 2-3 2H16l-3-2-3-1v-4l2-2v-1l-1-2 4-3 3-2v-3l5-4-1-4-1-3-4-4v-3l1-3 4-3 5-3h2l5-5h36l2 2 3 2h6l2 1 3 1v6l-1 1-2 1-2 3 2 2 1 2v2l5 3-1 3-5 6 1 3 2 3v7Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="M44 113v-1h-1v1h1Zm14 0v-1h-9l-1 1h3l2 1h6l-1-1Zm-24 0h-1v1h1v-1Zm-7 4 1-1-4 2-3 3 3-2 3-1v-1Zm30 0h1l1 1h-3l1-1Zm0 3 5-2h-1l-1-1h19l-1-1H30l1 1h1l-1 1v2l2-2 1-1h7l-2 2-3 2 1 1h7l7-1 6-1Zm-13 5-6-1-1 1-1 1 7-1h7-6Zm5 11 3-2v-1l-2-3h-7l-3 2v2l1 2 1 2h4l3-2Zm-10-1-2-2-3-1-3-2-1 1-1 2h1l-2 3 1 1v1h11l-1-3Zm-11 3-2-4-2-3h-1v1l1 3 2 4h2v-1Zm-6 3v-1h-1v1h1Zm52 1v-1h-2l1 2 1-1Zm-8-2 2-2 2-1v-1h-2l-2 2-2 2v3l1-1 1-1v-1Zm-3 7 2-1v-1l-1-1-2 2-3 2h3l1-1Zm-27 1v-3l3-2 5-1 5-1v-1l5-2 3-2 3-3h-2l-12 7H30l8 1v2h-3l-2 1v6h3v-2Zm6 4v-1h-2v2h2v-1Zm6 1 2-1 3-2 3-1v-2l-2 1-1 1-8 6h2l1-2Zm38 5H60l-2 2-3 2H16l-3-2-3-1v-4l2-2v-1l-1-2 4-3 3-2v-3l5-4-1-4-1-3-4-4v-3l1-3 4-3 5-3h2l5-5h36l2 2 3 2h6l2 1 3 1v6l-1 1-2 1-2 3 2 2 1 2v2l5 3-1 3-4 6v3l2 3v7Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="M70 114h2l-2-2H60v2l2 1 3-1h5Zm-11-1v-1H34l-1 1-1 1h26l1-1Zm7 8v1-1Zm15-4v1-1Zm-9 0h1l1 1h-3l1-1Zm7 1v-1 1l1 1h-1v1-2Zm-22 3 4-1h9l3-1h3v1h8v-3l-1-1h-1l-27-1H27l-3 3-4 3v1h14l4 1h7l8-1 4-1Zm-29 5h8v1h12v-1l1-1h22l5-3h-2l-1 1-1 1H19v3l1-2h8Zm21 10 3-2v-1l-2-3h-7l-3 2v2l1 2 1 2h4l3-2Zm-10-1-2-2-3-1-3-2-1 1-1 2h1l-2 3 1 1v1h11l-1-3Zm-11 3-4-7-2-1 4 8v1h2v-1Zm46 4v-1h-2v2h3l-1-1Zm3-1v-3l-1 6h-6v-5h-1v6h8v-4Zm-14 7 2-1v-2l1-1v-1l1-2v-1l2-2 5-1h6l-1-1h-5l-3-1-2-1-2 3-4 3v4l-1 1v1h-3v4l1-1 1-1h2Zm-47 1 1-1h-2l-1 1-1 1 1 2 1 1v-3l1-1Zm10 4 1-1h-6l1 1h4Zm16 0 1-1-1-1-1-1h-1v1l-1 3h2l1-1Zm8 0 4-4h3l2-1-2-1h-2l-2 2-2 1-4 3-3 2v1h2l4-3Zm-23 2-1-1-1 1-1 1h4l-1-1Zm-14 0h-1v1h1v-1Zm9 4v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm34-21h1v1h-1v-1Zm-3 1h1-1Zm-14 6v-1h3v-1l6-1-4 2-1 1h-2l-2 1v-1Zm0 11v-4l1-3h4l-3-2 3-1h1v3l2 1v-4l1-2 1-1h5-2l-2 1v1h2l2-1v2l-4 1v2l3-2 2-2v-3l5-2v1l-1 1-2 1v1h4l1-1h1v-4l-1-2h-5l2-1 2-1 2-3v-1l-1-1h-2l1 2-4 3-5 3-6 2H34l-10 1h12l1 1 1 1H21l1-1 1-1v-2l-3 3v7h8v-2h4l-1-1h-1l-4 2h-5v-3h12v7l1 7v1h2l1-4Zm51 2H60l-3 2-2 2H16l-2-1-2-1-2-2v-3l2-2v-4l3-2 3-2v-3l2-2 3-2-1-4-1-3-2-2-2-2v-3l1-2 1-1v-1l4-3 3-2h3l2-3 3-2h18l18 1 3 2 2 1h6l5 2v6l-5 4v2l3 2v3l2 1 3 2-1 3-4 5v5l2 1 2 1v7Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M70 114h2l-2-2H60v2l2 1 3-1h5Zm-11-1v-1H34l-1 1-1 1h26l1-1Zm7 8v1-1Zm15-4v1-1Zm-9 0h1l1 1h-3l1-1Zm7 1v-1 1l1 1h-1v1-2Zm-22 3 4-1h9l3-1h3v1h8v-3l-1-1h-1l-27-1H27l-3 3-4 3v1h14l4 1h7l8-1 4-1Zm-29 5h8v1h12v-1l1-1h22l5-3h-2l-1 1-1 1H19v3l1-2h8Zm27 5v-2l-1 1v1l1 1h1l-1-1Zm-8 7 3-2 3-2-2-2-1-3H39l-1 1 2 4 1 3 1 2h1l4-1Zm-7 0v-1l-2-5h-1l-1-3h-6l-2 2-1 1v2l1 3h-1l-1-3-2-4h-2v1l1 1 1 4 1 3h15v-1Zm34 4v-1h-2v2h3l-1-1Zm3-1v-3l-1 6h-6v-5h-1v6h8v-4Zm-14 7 2-1v-2l1-1v-1l1-2v-1l2-2 5-1h6l-1-1h-5l-3-1-2-1-2 3-4 3v4l-1 1v1h-3v4l1-1 1-1h2Zm-47 1 1-1h-2l-1 1-1 1 1 2 1 1v-3l1-1Zm10 4 1-1h-6l1 1h4Zm16 0 1-1-1-1-1-1h-1v1l-1 3h2l1-1Zm8 0 4-4h3l2-1-2-1h-2l-2 2-2 1-4 3-3 2v1h2l4-3Zm-23 2-1-1-1 1-1 1h4l-1-1Zm-14 0h-1v1h1v-1Zm9 4v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm34-21h1v1h-1v-1Zm-3 1h1-1Zm-14 6v-1h3v-1l6-1-4 2-1 1h-2l-2 1v-1Zm0 11v-4l1-3h4l-3-2 3-1h1v3l2 1v-4l1-2 1-1h5-2l-2 1v1h2l2-1v2l-4 1v2l3-2 2-2v-3l5-2v1l-1 1-2 1v1h4l1-1h1v-4l-1-2h-5l2-1 2-1 2-3v-1l-1-1h-2l1 2-4 3-5 3-6 2H34l-10 1h12l1 1 1 1H21l1-1 1-1v-2l-3 3v7h8v-2h4l-1-1h-1l-4 2h-5v-3h12v7l1 7v1h2l1-4Zm51 2H60l-3 2-2 2H16l-2-1-2-1-2-2v-3l2-2v-4l3-2 3-2v-3l2-2 3-2-1-4-1-3-2-2-2-2v-3l1-2 1-1v-1l4-3 3-2h3l2-3 3-2h18l18 1 3 2 2 1h6l5 2v6l-5 4v2l3 2v3l2 1 2 2v3l-4 5v5l2 1 2 1v7Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="m59 114 1-1v2h13v-2l-1-1H34l-2 2h19l7 1 1-1Zm13 8 1-1h12v-3l-2-3H27l-7 6v2h51l1-1Zm9 4v-1l3-3H73l-1 2H19v1l-1 1v1h42l21 1v-2Zm-5 5h-1v1h1v-1Zm-20 0-1-2-1 1 2 2h1l-1-1Zm25 1-1-1v4l1 1 1-3-1-1Zm5 4v-1 3l1-1-1-1Zm-39 2 3-2 3-2-2-2-1-3H39l-1 1 2 4 1 3 1 2h1l4-1Zm-8-2-1-3-1-1-1-1v-2h-6l-2 2-2 1 1 2 1 3h-1l-1-3-2-4h-2v1l1 1 1 4 1 3h16l-2-3Zm-23 15 1-3v-1l-4 3v3h2l1-2Zm68 2-1-1v1h-1 2Zm-56 0v-1h-2l-2-1h-3v2h7Zm-8-1v-1h-2v2h2v-1Zm51-18h1v1h-1v-1Zm3 1h1l1 1h-3l1-1Zm-3 3v-1h1v1h-1Zm0 5v-1l4 1-1-1v-1h-3v-2h5v5h-5v-1Zm1 3-2-1h5l-1 1h-2Zm0 3h1v1h-1v-1Zm-9 3v-2h1v5-2l1-1h7l3-3 3-2v-7l1 2v3l1-5v-2h-3l-4-1h7v-1l-3-2-3-1h-4l-7 7v3l-1 2v1h-3v8h3l1-2Zm7 3v-1h-2v3l2-1v-1Zm-13 4v-1h-1v1h1Zm-29-2v-3h-9l-1 1v1l4 1h4l1 2h1v-2Zm-3 2v-1h-5v1h5Zm-5 0v-1h-2v2h2v-1Zm27 0 2-2 3-1h3l2-1 1-1 1-7h-5l-5 4-5 3v6h1l2-1Zm13-25v-1h1l-1 2h-1l1-1Zm-7 9 1-1h2l-3 2v-1Zm2 2v-1h1v1h-1Zm-23 3v-1h1v1h-1Zm10 1v-2l1 2v1h-1v-1Zm-4 3v-1l1 1v1l-1 1v-2Zm-2 7v-1h1v1h-1Zm5 0 1-7h3l8-5 4-1 4-1 1-4v-3l2-2 2-3v-2l-5-1h-2l-2-1 2 3-6 4-5 3h-4l-3 1H24l14 2h-9l-8 1 2-2 1-1v-1h-2l-1 2-2 1v4l1 4 6-1 4 3v7l1 1h10v-1Zm-25-2v-2h-4l-1 2 2 2 1 1h2v-3Zm73 1H60l-6 4H22l-1-2h-2l2 2h-5l-1-1h-2l-2-2-2-2 2-2 1-2v-3l6-5v-3l2-2 3-2-1-4-1-3-2-2-2-2v-2l1-3 8-7h4l1-2 2-2h37l3 2v2l8-1 5 2v6l-5 4v2l3 2v3l2 1 2 2v2l-2 3-2 3-1 5 5 2v7Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M54 142h2v1h-2v-1Zm-12 7v-1l1 1h-1v1-1Zm30-27 1-1h12v-4l-1-1-1-1H47h12l1-2v2h13v-2l-1-1H32v2h10l5 1H26l-3 3-3 3v2h52v-1Zm5 9-1-1h-2l1 2h2v-1Zm-6 0h-1v1h2l-1-1Zm-24 7 3-2 3-2-2-2-1-3H39l-1 1 2 4 1 3 1 2h1l4-1Zm-8-2-1-3-1-1-1-1v-2h-6l-2 2-2 1 1 2 1 3h-1l-1-3-2-4h-2v1l1 1 1 4 1 3h16l-2-3Zm48 1v-2h-2v4h2v-2Zm-3 4-1-1v-9h-4v3l3 3v6h2v-2Zm-1 5v-1l-1 1-1 1h2v-1Zm-5 5h-2l-1 1h4l-1-1Zm-62-1 2-2-1-1-2 1-2 2v3h2l1-3Zm5 2v1h7v-1h-2l-1-1h-7v2h2l1-1Zm64 0v-1h-3v3h3v-2Zm-14-8v-2l3 1v-2l-4-1 5-1v5h-4Zm-5 9v-1h6l2-1 2-2 2-3 3-2v-8l-6-3h-6l-3 4-3 3v4l-4 3v7h7v-1Zm18 3h-1v1h1v-1Zm-19 0h-1l-1 1h3l-1-1Zm14 0v-1h-6v2h3l3-1Zm-8 0v-2l-2-1-2 2 2 2h1l1-1Zm-14 2 2-1h-1l-2 2-2 2 2-1 1-2Zm-10 2 1-1 4-2-1 1-1 1h1l7-5v-7h-4l-5 4-5 4v5h3Zm-23-2 1-1v1h1-2Zm-5-1h3l-1 1h-1l-1-1Zm9 0v-3l-10 1v5l4-1h5v1h1v-3Zm-12 0v-3h-4v1l-1 2 1 2 1 1h3v-3Zm71 1H60l-3 2-3 2H26v-1l1-1-2 1-2 1-1-1-2-1-1 2h-3l-1-1h-1l-4-3v-2l2-2v-4l7-5v4l1 1h7l2 1 1 2v7l3 1 9-1v-6l2-1 1-1 2-1 2-1 6-4h3l2-1h1l1-3v-3l5-6v-1l-1-1h-2l-3-1h-2l-2-1 1 2 1 1h-2l-2-1-1-2v1l1 2 1 1-2 2-5 3-4 2H25v1h2l2 1h9-8l-8 1 1-1 1-1v-2h-2l-2 3-2 2v-2l5-4v-3l-2-1v-4h-1l-2-3h20l20 1h11l11 1v-4l2-1 1-2H73l-1 2H19l-2 2 1-4 4-4 4-3h4l4-4h36l3 2v1h10l1 1 2 1v6l-5 4v2l3 2v3l2 1 3 2-1 4-2 2-2 2v5l1 1 2 1v7Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M30 114h2v1h-2v-1Zm42 1 1-1-1-1-1-1H34l-3 1 3-2h36l3 2 1 2h-2Zm-2 0h1-1Zm-11 0v-1l5 1h4-10 1Zm-4 0h3-4 1Zm-3 0h1-1Zm-2 0v-1l1 1h1-3 1Zm-13 0h9-12 3Zm48 3-1-2h-4l-4-1v-1h7l2 2 1 1v1l-1 1v-1Zm-48 13h1v1h-1v-1Zm10 7h1v1h-1v-1Zm-2 1v-1l1 1h-2 1Zm-5 1 1-1v1h1-2Zm33 0h-3 3l2-1v2l-2-1Zm-19 2h2v1h-2v-1Zm-31 0 1-1-1-3v-3l1 3 1 2 1 1 11 1h-8l-7 1 1-1Zm-3-1 2-2-3 4h-2l3-2Zm54 2h1-1Zm-3 0h1-1Zm2-12v-1h-3v1l-1 1h4v-1Zm14 7v-3h-2v5h2v-2Zm-3-2-1-5-4-1v2h-2v-2h-3v1l4 3 4 3v7l2-2v-6Zm-1 10v-1h-2v3h2v-2Zm-4 4v-2 2h-3l-1 2h4v-2Zm-52 3v-1l-4-1h-5v2h10l-1-1Zm59 0v-2h-5v3h5v-1Zm-1 3v-1h-3v2h3v-1Zm-8-1v-1h1v1h-1Zm3 1v-1l-1-1-1-1-2 1h-3v3h7v-1Zm-9-1v-2h-4v3l1 1h3v-2Zm-5 2 1-1h-6v1h5Zm-50 0v-3h-3l-1 2-1 1 1 2 1 1h3v-3Zm72 1H60l-3 2-3 2 2-2 3-3h-1v-1l-3 3-3 2-25 1v-1l1-1v-6H18v6h8l-1 1h-4l-1-1-2 1-2 1-1-1h-1l-4-3v-2l2-2v-4l1-1h1v2l-1 2h2l1-1v-1l1-2 1-1v-1l-2 1h-1l2-2 1-1 1 4 9 1 2 5v5l3 1h2l4-1h3l1-3v-3l6-4-3 2-2 3v3l1 3 3-1h3l4-3 3-3 1-3v-3 7l3-1h4v-2l3 1h2l10-8v-8l-2-2-2-1h-4l-4-1-3 4-3 3v4l-4 3h-5l-2 2-3 2 1-2 2-1 2-1 3-1h1l4-3v-4l3-3 2-2v-3h-2l-3-1h-2l-3-1 2 4-5-5-2 1 2 2 2 2v1l-3 2-3 1 2-1 2-2-2-3-2-2H27l-5 1 1 2v3l-1-1h-1v-3l-1-1-2-1 1-1h50l12 1v-4l1-1 1-2H73l-1 2H19l-2 2 1-4 4-4 4-3h3-2l-1 1-7 6v1h52l4-2h11v1l-5 4v2l3 2v3l2 1 3 2-1 2-1 2-1 2-2 2v5l1 1 3 1v7Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="M44 111v-1l1 1v1h-2l1-1Zm-9 0h6-8 2Zm-4 1h2l-1 1h-1l1-1Zm41 1-1-1-12-1H47h24l1 1 2 2-1 1-1-2Zm-42 1h1v1h-1v-1Zm46 1v-1h1l2 1h-3Zm-17 0v-1l2 1h-2Zm-18 0h4-5 1Zm44 3v-1l-1-1-2-1-2 1 2-2 3 2 1 1v2l-1 1v-2Zm-64 1 6-5-5 5h-1Zm-1 1v1-1Zm64 2 1-1 1 1h-2Zm-3 0v-1l1 1h1-3 1Zm-2 0h1-1Zm-9 2v-1h1v1h-1Zm-52-1v-2 1l1 1h25l25 1H19v-1Zm19 8h1v1h-1v-1Zm-15 3v-1h1v1h-1Zm62-1-1-3h-2l-2-1-3 1-3 1 2 1 2 2h-2l-1-2-2-2h-3v3h-2v-2l-5-1-5-1v1l1 1 1 1-1 1-3-4h-3l4 5-3 2v-1l1-1-2-3-2-2H32l-10 1v2l-3-4h30l31 1 1-5h2l1-1-1 2-1 1 1 2 1 2 1 3 1 1h1l-2 1-1 1v-3Zm-18 3 1-2 1 1-2 1-2 2 2-2Zm15 2v-1l1 1h-1v1-1Zm6 1h1-1Zm-43 0h1-1Zm-21-1v-3l1 3v1l-1 1v-2Zm49 2 1-1 2 1h1-5 1Zm-37 2h1v1h-1v-1Zm-12 0 1-1 11 1h-7l-6 1 1-1Zm-3-1 2-2h1l-5 4h-1l3-2Zm54 2h1-1Zm-12-1v-2l1-1v-1h2l-2 2v2l-1 2v-2Zm-5 4h2l2-1 1-1v2h-2l-3 1h-3l3-1Zm-6 3 1-1 2-1-2 1-1 2h-1v-1Zm-39 1h1-1Zm9 0h1l-1 1h-1l1-1Zm55 3v-1l1 1h-2 1Zm-13 2v-1h1v1h-1Zm20-9v-1h-2v3h2v-2Zm3 6v-1l-1-1h-3v2l-1 2h5v-2Zm0 4v-1h-5v1l3 1h1l1-1Zm1 2H76h2l3-1v-3h-2l-2-1h2l1-2v-3l-1-2 1-1h1v-5 1l1 2v1h1l1-2h2l-1 2v5l1 1 2 2v5l-1 1Zm-16-2v-3h-4v4l-1-1v-3h6l3-3 3-3 1 1-2 2-3 2v1h-2l1 5h-2v-2Zm-14 3h1v1h-1v-1Zm-46 0-1-2h1l1 2 1 1-2-1Zm44 2v-1h1v1h-1Zm-6-1 3-1 3-2 3-2 1-3v-4 7l2-1h1l-1 1-1 1v1l9 1h-5l-6 1 1-2v-1h-1l-3 3-3 2h-5l2-1Zm-10 1 4-1v-6l5-3-2 2-3 2 1 3v3h-8 3Zm-11-3 1-4H18l-1 1v1-2h-5v-1l4 1v-2l1-2v-2l1-2-1 1h-1l1-1h1l1 2v2h-1v3h9v-1l-4-2 3-1 3 3v8h2l1 1h-4v-3Zm-6 2h-1 3l-1 1h-1v-1Zm-7 1-1-1h2v-2l3 2-1 1-2 1-1-1Z" style="fill:';
    string private constant PART_11 = '"/>';
    string private constant COLOR_1 = "hsl(34, 59%, 57%)";
    string private constant COLOR_2 = "hsl(220, 3%, 63%)";
    string private constant COLOR_3 = "hsl(22, 83%, 47%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(18, 76%, 38%)";
    string private constant COLOR_6 = "hsl(223, 6%, 24%)";
    string private constant COLOR_7 = "hsl(213, 9%, 20%)";
    string private constant COLOR_8 = "hsl(213, 10%, 18%)";
    string private constant COLOR_9 = "hsl(223, 10%, 13%)";
    string private constant COLOR_10 = "hsl(225, 17%, 9%)";

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
