// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderShield3 {
    string private constant PART_1 =
        '<path d="M169 155h-46v-39h46v39Zm-66-29H91v11h12v-11Z" style="fill:';
    string private constant PART_2 =
        '"/><path d="M149 120v-1h-1v1h1Zm9 1v-1h-1v1h1Zm-3 1v-1h-1v1h1Zm-13 0v-1h-1v1h1Zm9 2v-1h-1v1h1Zm-6 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm5 1h-1l-3 1h4Zm-4 1v-1h-1v1h1Zm-9-1h-1l-2 1h5l-2-1Zm16 3v-1h-1v1h1Zm-2-1h-1l-1 1h2v-1Zm-3 1v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm21 2v-1h-1v1h1Zm-12 0v-1h-1v1h1Zm9 1v-1h-1v1h1Zm-13 1v-1h-1v1h1Zm-40-1v-1h-2l1 2h1v-1Zm60 2v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-4 1v-1h-1v1h1Zm9 0h-1l-3 1h4v-1Zm-12 1v-1l-7-1 1 2h6Zm-14-1h-1l-2 1h5l-2-1Zm16 2v-1h-1v1h1Zm-20 1v-1h-1v1h1Zm27 1 1-1h-1l-1 2h1v-1Zm-14-1v-2l-1 3-4-1 3 2 2-1v-1Zm-5 2v-1h-1v1h1Zm18 2v-1h-1v1h1Zm-20 0v-1h-1v1h1Zm-6 0v-1h-1v1h1Zm31 3v-1h-1v1h1Zm-2 0v-1l-3-1 1 2h2Zm-14-4v-1h1v1h-1Zm2 0 1-1h1l-1 2h-1v-1Zm1 3v-1l2-3-4-1 3-2h-4l-1 2-1 4 2-1 4 2-4-1-1 2h5l-1-1Zm-14 0h-1l-2 1h5l-2-1Zm17 2v-1h1v1h-1Zm3-1 1-2-1-1h-3l-2 5h5v-2Zm-6 3v-1h-1v1h1Zm-10-3v-1l1-1 1 3h-1l-1-1Zm5 1-1 2 2-1-4-4 2-1-4 1v4l-2-1 1 2 5-2h1Zm11 3h-1l-3 1h4v-1Zm-13 0h-1l-2 1h5l-2-1Zm-12 22h-1l-15-16-5 4H97l-5-6h-8l-3-4v-36l7-1v-3h14l2 2 5-6h9l2-3h7l1-3h36l4 5 8-1v13l5 4v34l-17 17-32 1-2-1Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M149 120v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm11 1v-1h-1v1h1Zm-3 0h-1l-3 1h4Zm-13 0h-1l-1 1h2v-1Zm9 3v-1h-1v1h1Zm-8 1v-1h-1v1h1Zm13 1v-1h-1v1h1Zm-8 1v-1l-4-2 1 3h3v-1Zm-13-1h-1l-2 1h5l-2-1Zm0 2h-1l-2 1h5l-2-1Zm23 3v-1h-1v1h1Zm-5-1v-1h1v1h-1Zm2 0-1-1-4-1 2 3h3v-1Zm-17-4h1l1 1h-2v-1Zm2 4v-1h1v1h-1Zm3 0v-2l1-2-1 1-4-2-3 2 3 2h-1l1 2h3l1-1Zm-11 1v-1h-1v1h1Zm28 2v-1h-1v1h1Zm-22 0v-1h-1v1h1Zm-40-1v-1l-2-1v3h2v-1Zm60 2v-1h-1v1h1Zm-23-1-1-2 2-1h-2l-1 4h2v-1Zm44 3v-1h-1v1h1Zm-18-1h-1l-3 1h4v-1Zm-12 0v-2l2-1-3-4h-3l-1 5 1 3h4v-2Zm-13 1v-1l-5-1 1 2h4Zm-5 2v-1h-1v1h1Zm48 0h-1l-1 1h2v-1Zm-23 1v-6l-4 1-2 2 2 4h3v-1h1Zm-16-4v-1h1v1h-1Zm3 2v-2l-3-3-3 4 1 4 5-1v-2Zm16 3v-2h-1l-2 4 2-1v-1Zm-30 3v-1h-1v1h1Zm-22 0v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm63 2v-1l-5-1 1 2h4Zm-15-6v-1h1v1h-1Zm3 4 1-2-2-4h-3l-2 3 1 5h5v-2Zm-17 1v-1h1v1h-1Zm4-1 1-2-3-4 1 3-2-2h-2l-2 4 3-1-1 4h4l1-2Zm-26 3v-1h-1v1h1Zm26 2h-1l-1 1h2v-1Zm-52 1v-1h-1v1h1Zm71-1v-3l-1-3h-3l-2 4 2 4h3v-2Zm-14 1-1-1 4-1-2-5h-4l-2 4 2 4h4l-1-1Zm-23 0h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm-4-1h-2l-4 1h9l-3-1Zm-10 0h-3l-6 1h12l-3-1Zm49 1v-3h-4v3l1 1 3-1v-1Zm-14 1v-1h-1v1h1Zm-50 0v-1h-1v1h1Zm90 5v-1h-1v1h1Zm-6 6v-1h-1v1h1Zm-2 2v-1h-1v1h1Zm-39 1v-1l-5-4 4 5h1Zm2 2v-1h-1v1h1Zm0 4h-1l-15-16-5 4H97l-5-6h-8l-3-4v-36l7-1v-3h14l2 2 5-6h9l2-3h7l1-3h36l4 5 8-1v13l5 4v34l-17 17-32 1-2-1Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="M158 121v-1h-1v1h1Zm-9-2h-3v2l3-1v-1Zm6 2 1-1h-5l1 2h3v-1Zm-13 1v-1l-4-1 1 2h3Zm-5 0v-1h-1v1h1Zm-5 0v-1h-1v1h1Zm19 2v-1h-1v1h1Zm-14 0h-1l-3 1h4Zm24 3v-1l-3-1v2h3v-1Zm-12-2v-3l-2-1 1 2-3-2-1 1 1 5h4v-2Zm-14 1h-1l-2 1h5l-2-1Zm-4 2v-1h-1v1h1Zm25 2 1-2-2-2 3 1-3-3-3 1-2 3 2 3h4v-1Zm-13-1 1-2-1-3-4 1-2 3 2 3h4v-2Zm21 2h-1l-1 1h2v-1Zm-66 0v-1l-2 1-1 2h3v-2Zm31 2h-1l-1 1h2v-1Zm36 2v-1h-1v1h1Zm14 1v-1h-1v1h1Zm-17-3-1-4 2 1-1-2h-3l1 2-2-1-2 3 3 4h3v-4Zm-12 1 1-2-2-4h-3l-3 4 2 4h4l1-2Zm-13 0 1-1-2-5h-4l-2 5 2 3h3l1-2Zm27 3v-1h-1v1h1Zm15 1h-1l-1 1h2v-1Zm-50-1v-1l1 1-1 1v-1Zm1-1-1-1-1 1 1 3 2-2-1-1Zm26 2 1-2-1-3h-4l-2 3 2 4h4v-2Zm-13-1v-2l-3-3-3 4 1 4 5-1v-2Zm-36 6v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm63 0v-2l2 1-1-3-4-2-3 4 2 4h4v-2Zm-32 1v-3l3 4h3l2-4-3-4h-3l-2 5h-3l4 4-1-2Zm-19 2v-1h-1v1h1Zm-26 3v-1h-1v1h1Zm74-1-1-1-3 3 4-1-1-1Zm-3 0 1-2-2-4h-3l-2 2 1-3-2-4h-3l-3 3 2 5h5l2 5h3l1-2Zm-12 0 1-1-2-5h-4l-2 4 2 4h3l1-2Zm-25 1h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm-4-1h-2l-4 1h9l-3-1Zm-10 0h-3l-6 1h12l-3-1Zm-15 2v-1h-1v1h1Zm66 0v1l-2-5-5 1v4l6-2v1Zm-14-1v-3h-1l-4 1v2l5 2h1l-1-2Zm38 6v-1h-1v1h1Zm-6 6v-1h-1v1h1Zm-2 2v-1h-1v1h1Zm-39 1v-1l-5-4 4 5h1Zm2 2v-1h-1v1h1Zm0 4h-1l-15-16-5 4H97l-5-6h-8l-3-4v-36l7-1v-3h14l2 2 5-6h9l2-3h7l1-3h36l4 5 8-1v13l5 4v34l-17 17-32 1-2-1Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="M123 151H82v-9h41v9Zm56-20h-9v14h9v-14Zm-58 29 9 8h35l14-16-14 1-20 9-24-2Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M138 115v-1h-1v1h1Zm19 1v-1h-1v1h1Zm-9 0v-1h2v-1l-6-1v3l1 1h4l-1-1Zm-11 1v-1l-2-1 1 2h1Zm24 0h-1l-3 1h4Zm-26 1v-1h-1v1h1Zm17-1v-1h1v1h-1Zm3 2v-1h1v1h-1Zm1 1 1-2-3-3h-3l-2 3 3 4h3l1-2Zm-13 0 1-2-1-3h-4l-2 4 2 3h4v-2Zm18 6v-1h1v1h-1Zm2-1 1-2-3-4h-3l-2 4 3 4h3l1-2Zm-13 0 1-2-3-4h-2l-3 4 2 4h3l2-2Zm-13 0 1-2-3-4h-3l-2 4 2 4h3l2-2Zm32 4v-1h-1v1h1Zm-71-1h-1l-1 1h2v-1Zm69 0v-3l-2-1-1 2 3-1-2 2-2-1v2l2 3h2v-3Zm-11 1 1-2-3-4h-2l-2 5 2 3h4v-2Zm-26 1 1-2-2-4h-3l3 2h-3l-1 4 1 1h3l1-1Zm-32 1v-1h-3v3l4-1v-1Zm1 4v-1h-1v1h1Zm80 1v-1h-1v1h1Zm-42-2 1-2-2-4h-4l-2 4 2 4h4l1-2Zm42 4h-1l-1 1h2v-1Zm-12-1v-2l2 1-1-3h-3l-2 4 1 3 3-1v-2Zm-37 1 1-1-2-4-5-1 1 8h5v-2Zm-23 5v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm64 0 1-2-2-4h-4l-2 5 2 3h4l1-2Zm-52 3v-1h-1v1h1Zm56-2v-2h-2l-2 2v3l4-1v-2Zm-36 3v-2l-1-3h-4v1l2 5h3v-1Zm-46 2v-1h-1v1h1Zm34 0h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm-4-1h-2l-4 1h9l-3-1Zm-10 0h-3l-6 1h12l-3-1Zm-15 2v-1h-1v1h1Zm76-2v-1h1v1h-1Zm-1 2 3-1-1-3h-3l-3 2v3h2l3-1Zm-16-15v-1l2 1-1 2h-1v-2Zm-1 4v-1h1v1h-1Zm7 4v-1h1v1h-1Zm-7-1v-1l1-1 1 3h-1l-1-1Zm7 9 1-2-4-5-4 5 2-5h4l3 5h3l2-4-2-5-4 1v-2h5l1-4h5l2-3-2-5h-3l-3 4 2 3h-2v-2h-5l-1 3 1 3-2-3 2-4-2-4h-4v2h-2l1-3-2-4h-3l-3 4 3 4h4l1 3-2-2-3 1-3 3 1 2-4-1-3 4 2 4h4l2-4-1-2 5 2-3 2-2 2 3 5h4l1 3h4l1-1Zm-13 0 1-1-1-4h-6v3l4 3h2v-1Zm17 1 1-1h-4l1 2h2v-1Zm-10 1-1-1-4-1v2l1 1h4v-1Zm31 2v-1h-1v1h1Zm-6 6v-1h-1v1h1Zm-2 2v-1h-1v1h1Zm-39 1v-1l-5-4 4 5h1Zm2 2v-1h-1v1h1Zm0 4h-1l-15-16-5 4H97l-5-6h-8l-3-4v-36l7-1v-3h14l2 2 5-6h9l2-3h7l1-3h36l4 5 8-1v13l5 4v34l-17 17-32 1-2-1Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="M145 102v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-4 13v-1h-1v1h1Zm19 1v-1h-1v1h1Zm-9 0v-1h2v-1l-6-1v3l1 1h4l-1-1Zm-11 1v-1l-2-1 1 2h1Zm24 0h-1l-3 1h4Zm-26 1v-1h-1v1h1Zm-21 2v-1h-1v1h1Zm-29-1 1-1h-2v2h1v-1Zm67-2v-1h1v1h-1Zm3 2v-1h1v1h-1Zm1 1 1-2-3-3h-3l-2 3 3 4h3l1-2Zm-13 0 1-2-1-3h-4l-2 4 2 3h4v-2Zm-27 3v-1h-1v1h1Zm45 3v-1h1v1h-1Zm2-1 1-2-3-4h-3l-2 4 3 4h3l1-2Zm-13 0 1-2-3-4h-2l-3 4 2 4h3l2-2Zm-13 0 1-2-3-4h-3l-2 4 2 4h3l2-2Zm-21 2v-1h-1v1h1Zm53 2v-1h-1v1h1Zm-71-1h-1l-1 1h2v-1Zm69 0v-3l-2-1-1 2 3-1-2 2-2-1v2l2 3h2v-3Zm-11 1 1-2-3-4h-2l-2 5 2 3h4v-2Zm-26 1 1-2-2-4h-3l3 2h-3l-1 4 1 1h3l1-1Zm-19 3v-1h-1v1h1Zm-13-2v-1h-3v3l4-1v-1Zm-11-6-1-3v11l1-5v-3Zm12 10v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm83 1v-1h-1v1h1Zm-42-2 1-2-2-4h-4l-2 4 2 4h4l1-2Zm-25 2v-1h-1v1h1Zm-19 0v-1h-1v1h1Zm-6 0v-1h-1v1h1Zm92 2 1-1-3 1v1h2v-1Zm-12-1v-2l2 1-1-3h-3l-2 4 1 3 3-1v-2Zm-37 1 1-1-2-4-5-1 1 8h5v-2Zm-15-1v-1l-4 3v1l4-2v-1Zm-9-10-1-4v18l1-10v-4Zm73 14v-1h-1v1h1Zm-57 2v-1h-1v1h1Zm-15-1H87l-1-5v6h21v-1Zm56 1 1-2-2-4h-4l-2 5 2 3h4l1-2Zm-40 2v-1h-1v1h1Zm-10 1v-1h-1v1h1Zm-2-1-1-1-2-1 1 3h2v-1Zm56-1v-2h-2l-2 2v3l4-1v-2Zm-43 3v-1h-1v1h1Zm-19-1v-1h-2v2h2v-1Zm26 1v-2l-1-3h-4v1l2 5h3v-1Zm-48 2v-1h-1v1h1Zm95 2v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-54-1v-1h-6v2h6v-1Zm-7-1-1-1v3l1-1v-1Zm-2 1v-2l-19 1v-5l-2 1 1 4-6-1v-3l-3-4 1 3v6l28 1v-1Zm49-1v-1h1v1h-1Zm-1 2 3-1-1-3h-3l-3 2v3h2l3-1Zm-16-15v-1l2 1-1 2h-1v-2Zm-1 4v-1h1v1h-1Zm7 4v-1h1v1h-1Zm-7-1v-1l1-1 1 3h-1l-1-1Zm7 9 1-2-4-5-4 5 2-5h4l3 5h3l2-4-2-5-4 1v-2h5l1-4h5l2-3-2-5h-3l-3 4 2 3h-2v-2h-5l-1 3 1 3-2-3 2-4-2-4h-4v2h-2l1-3-2-4h-3l-3 4 3 4h4l1 3-2-2-3 1-3 3 1 2-4-1-3 4 2 4h4l2-4-1-2 5 2-3 2-2 2 3 5h4l1 3h4l1-1Zm-13 0 1-1-1-4h-6v3l4 3h2v-1Zm-11-2-2-3 4 6v-1l-2-2Zm28 3 1-1h-4l1 2h2v-1Zm11 0 1-2-3 3v1h1l1-2Zm-21 1-1-1-4-1v2l1 1h4v-1Zm-42 1v-1h-1v1h1Zm45 1v-1h-1v1h1Zm-39 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm70-2 1-1h-1l-3 4 3-1v-1Zm-15 3v-1h-1v1h1Zm-29-1-1-2h-3l4 3h1l-1-1Zm-12 0v-1l-5-2 4 4h1v-1Zm15 2v-1h-1v1h1Zm2 1v-1h-1v1h1Zm-15 0v-1h-1v1h1Zm7 4v-1h-1v1h1Zm2 2v-1h-1v1h1Zm35 0 1-1h1l-1 2h-1v-1Zm-15 4v-1l2 1h10l1-1 4-3v-3h3l1-3-4 2-5 6-32 1-7-7 3 5-1 2 2-2 2 4h22l-1-1Zm-26-2-4-5 1-1-2 1-7-7-4 4H97l-5-6h-8l-3-4v-37h7v-3h13l2 2 6-6h9l2-3h7l1-3h36l4 5 8-1v13l5 3v35l-16 17h-36l-4-5Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M145 102v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm13 10v-1l-4-1-1 2 2-1v2h3v-1Zm5 5v-1h1v1h-1Zm1 0 1-1-4-4-2 1v3l2 2h3v-1Zm-12-1 1-2-2-3h-3l-1 2 1 5h3l1-2Zm-12 0 1-2-2-2v2l-4 1v3h4l1-2Zm26 3v-1h-1v1h1Zm2 1v-1h-1v1h1Zm-51 0v-1h-1v1h1Zm-29-1 1-1h-2v2h1v-1Zm81 2h-1l-1 1h2v-1Zm-10-1 1-2-3-3h-3l-2 3 2 4h4l1-2Zm-26 1 1-3-1-1v2h-5l3 2h-2l1 2h2l1-2Zm-14 2v-1h-1v1h1Zm47 2 1-2-3-4h-3l-2 3 2 5h4l1-2Zm-47 2v-1h-1v1h1Zm-17 2v-1h-5l6 2-1-1Zm70 0 1-2-2-3h-4l-1 4 2 3h3l1-2Zm-13 0 1-2-3-4h-2l-2 2v4l2 2h4v-2Zm-26 1 1-2-2-4h-4l-1 3 1 4h4l1-1Zm40 3v-1h-1v1h1Zm-59 0v-1h-1v1h1Zm-24-8-1-3v11l1-5v-3Zm9 8h1l2 1h-5l2-1Zm3 1h1l-2-4h-3l-1 4 1 1h3l1-1Zm80 2v-1h-1v1h1Zm-67 0v-1h-1v1h1Zm-19 0v-1h-1v1h1Zm-6 0v-1h-1v1h1Zm92 2 1-1-3 1v1h2v-1Zm-64-1v-1l-4 3v1l4-2v-1Zm-9-10-1-4v18l1-10v-4Zm73 14v-1h-1v1h1Zm-9 0v-1h-1v1h1Zm-45 1v-1h-1v1h1Zm-3 1v-1h-1v1h1Zm-15-1H87l-1-5v6h21v-1Zm16 3v-1h-1v1h1Zm-10 1v-1h-1v1h1Zm-2-1-1-1-2-1 1 3h2v-1Zm13 2v-1h-1v1h1Zm-19-1v-1h-2v2h2v-1Zm63-3v-1h-3l-2 3 1 4 4-4v-2Zm-85 6v-1h-1v1h1Zm95 2v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-54-1v-1h-6v2h6v-1Zm-7-1-1-1v3l1-1v-1Zm-2 1v-2l-19 1v-5l-2 1 1 4-6-1v-3l-3-4 1 3v6l28 1v-1Zm14 0-2-3 4 6v-1l-2-2Zm11-18v-2l6 1v2l-4-1-2 2v-2Zm7 6v-1h1v1h-1Zm-13-1v-1l6-1v3h-6v-1Zm19 0-1-1 2-2v5h-1v-2Zm6 3v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm8 2v-1h1v1h-1Zm-8 0v-1h1v1h-1Zm-6-1v-2l2 2-2 2v-2Zm7 3v-1h1v1h-1Zm1 1h1l1 1h-2v-1Zm4 2-1-1 1-1 2 3h-1l-1-1Zm-6 1 1-1h1l-1 2h-1v-1Zm-5 2v-3l1 3h4l3 4h3l2-5h4l2 4h3l3-3-1-3-5 1-1-7 2 4h4l2-4-1-2 4 1 3-3-2-4h-3l-3 5h-5l1-2h4l2-3-2-5h-4l-2 4 2 3h-2l-1-2-4-1-3-5 3-4-3-4h-2l-1 2h-2l2-2-3-4h-3l-2 4 2 3h3l3 4v4l-2-5-3-2-3 3h-1l2-3-2-4h-4l-2 4 2 4h4l1 2-5-1-2 4 1 2-6-1-3-3 3 3v2l-2-1 2 6 3 1 2-1 1 3-5-1v4l3 3 2-1v-4h6v3l-2-1-4 2v3l4 3 3-2v-2Zm27 3 1-2-3 3v1h1l1-2Zm-63 2v-1h-1v1h1Zm53 0 1-1-1-3h-4l-2 5 5-1h1Zm-8 1v-1h-1v1h1Zm-3-1h1l-2-4h-4l-2 4 2 1h5Zm-36 1v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm70-2 1-1h-1l-3 4 3-1v-1Zm-15 3v-1h-1v1h1Zm-29-1-1-2h-3l4 3h1l-1-1Zm-12 0v-1l-5-2 4 4h1v-1Zm15 2v-1h-1v1h1Zm2 1v-1h-1v1h1Zm-15 0v-1h-1v1h1Zm7 4v-1h-1v1h1Zm2 2v-1h-1v1h1Zm35 0 1-1h1l-1 2h-1v-1Zm-15 4v-1l2 1h10l1-1 4-3v-3h3l1-3-4 2-5 6-32 1-7-7 3 5-1 2 2-2 2 4h22l-1-1Zm-26-2-4-5 1-1-2 1-7-7-4 4H97l-5-6h-8l-3-4v-37h7v-3h13l2 2 6-6h9l2-3h7l1-3h36l4 5 8-1v13l6 3v35l-17 17h-36l-4-5Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M170 160v-1h1v1h-1Zm-6 2v-1h1v1h-1Zm-36 0v-1h1v1h-1Zm-4-2-2-2 4 3v1h-1l-1-2Zm5 4v-1h1v1h-1Zm2 1v-1h1v1h-1Zm31 2v-1h1v1h-1Zm-32 0v-1h1v1h-1Zm25-65v-1h-17v2h17v-1Zm-18 0v-1h-4v2h4v-1Zm-5 1v-1l-3-1v2h3v-1Zm-4 0h-1l-1 1h2v-1Zm-1 2h-1l-1 1h2v-1Zm24 1-4-1-8 2h15l-3-1Zm-29 1 1-1-1-1-3 3h1l2-1Zm53 2v-3h-3v5h3v-2Zm-52 1v-1h-3v2h3v-1Zm-9 1 2-1h-5l-1-3v5h2l2-1Zm-5 0v-1l-1-1-2 3h2l1-1Zm-15 1v-1h-1v1h1Zm61 0v-1l-4-1-1 2 2-1v2h3v-1Zm-37-1-1-2v4l1-1v-1Zm-9 3h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm17 0v-1h-9l1 2h8v-1Zm39 2v-1h1v1h-1Zm1 0 1-1-4-4-2 1v3l2 2h3v-1Zm-12-1 1-2-2-3h-3l-1 2 1 5h3l1-2Zm-12 0 1-2-2-2v2l-4 1v3h4l1-2Zm26 3v-1h-1v1h1Zm2 1v-1h-1v1h1Zm1 1h-1l-1 1h2v-1Zm-10-1 1-2-3-3h-3l-2 3 2 4h4l1-2Zm-26 1 1-3-1-1v2h-5l3 2h-2l1 2h2l1-2Zm40-3-3-5-7-5 1-1h-6l7 4 7 6 3 8 1-2-3-5Zm-51 8h-1v2l1-1-1-1Zm50 3 1-2-2-3h-4l-1 4 2 3h3l1-2Zm-13 0 1-2-3-4h-2l-2 2v4l2 2h4v-2Zm-26 1 1-2-2-4h-4l-1 3 1 4h4l1-1Zm40 3v-1h-1v1h1Zm5-1v-4l-2-3v14l2-2v-5Zm-5 9v-1h-1v1h1Zm-63-23v-1h1v1h-1Zm5 8v-1h1v1h-1Zm4 8v-8l4-9h-8l-4 2 3-3H99v4h9v21h8v-7Zm9 8v-1h-1v1h1Zm-4 2h-1v2l1-1-1-1Zm47-1v-1h-3l-2 3 1 4 4-4v-2Zm-47-23v-1l2-1v2l-2 1v-1Zm2 24-2-3v-14l5-12 7-5 7-3h-4l-9 6-1 2-2-1v4l-2-1-2 3 1 2-2 9-1 10 5 5-2 1 2 3 2-2-2-4Zm56 4v-3h-2v6h2v-3Zm-3 0v-2l-3 4v1h3v-3Zm-82-18v-1h-1v1h1Zm-2 1h-1v2l1-1-1-1Zm-2-1-1-2v7l1-3v-2Zm2 7v-1h-3v3l4-1v-1Zm3 3h-2l-4 1h8l-2-1Zm-6 1h-1v-17h2l-1 3 2 1 3-3 7-1-1 2 2 1 2-3 1 12-2-7-3-2h-1v3l3-1-1 6 2 2-3-2v3l-5-1-2-2h6l-1-3v-4h-2l3-2h-3l-1 3v-3l-3 1 5 3h-2v3l3 1-5-1-2 2 4 3-1 1 8-1 3-1-1 3-7 1 7 1H89l-1-1Zm8 2h3l6 1H93l4-1Zm-10 0h2l5 1h-9l2-1Zm34 7-1-2-10-1-1-1 10 1v-1l-4-4h-6l-2 2v-22H86l-1 20v-20l2-2 10-1 1-3H84l1-1 12-1H85l-3 3v31l3 4h36v-2Zm38-23h1l1 1h-2v-1Zm-22 5v-2l6 1v2l-4-1-2 2v-2Zm7 6v-1h1v1h-1Zm-13-1v-1l6-1-1 2-5 1v-1Zm19 0-1-1 2-2v5h-1v-2Zm6 3v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm8 2v-1h1v1h-1Zm-8 0v-1h1v1h-1Zm-6-1v-2l2 2-2 2v-2Zm7 3v-1h1v1h-1Zm2 2v-1h1v1h-1Zm3 1-1-1 1-1 2 3h-1l-1-1Zm-6 1 1-1h1l-1 2h-1v-1Zm-5 2v-3l1 3h4l3 4h2l3-4 5-1 1 4h2l4-3-1-3-6 1v-7l2 4h4l2-4-1-2 4 1 3-3-2-4h-3l-3 5-5-2h5l3-4-3-3v-2l2-4-3-4h-3l-3 3 3 4v3l-2 3 2 3h-2l-1-2-4-1-2-5 2-4-3-4h-2l-1 2h-2l2-3-3-3h-3l-2 4 2 3h3l3 3v4l-2-4-3-3-3 4h-1l2-3-2-4h-3l-3 4 3 4h3l1 2-5-1-2 4 1 2-5-2-3-2 2 3v2l-2-1 2 6 3 1 2-1 1 2h-5v3l3 4 2-1v-4h6v3l-1-1-5 2v3l4 3 3-2v-2Zm17 5 1-1-1-3h-4v2l-3 3 6-1 1-1Zm-8 1v-1h-1v1h1Zm-7 0h2l3-1-2-4h-3l-4 5v2l1-3 2 1Zm-31 0h2l-3-3h-3l1 2h-2v-2h-4v4h7l2-1Zm-10-3h-1l-3 1 3 3 1-3v-1Zm78 4 2-3-1-1-4 2-1-2-3 1 3 5h1l3-2Zm-43 0-3-2 1-3-2 2-5-5-1 2 4 4-2-2 3 1v3h4l-1 2h5l-3-2Zm-11-3v-1h-8v1l4 5 4-5Zm18 5h-1l-3 1h4v-1Zm17 1h1l-1-2 3 1-1-2h5v-3l4-1-1-2h2l-1-2h2l3-9h-2l-2 8-3 2v3l-2-1-3 4-10 4v1l5-2 1 1Zm-9 0h-2l-5 1h10l-3-1Zm9 4v-2h-23v3h23v-1Zm-32 4-3-4v-1l7 7h33l10-10-2-4h-3l-7 5-3 1 2 2 4-1-1 2h-4v2h-25v-5l-10-7-5 5 3 4-9-9-4 3H97l-5-5h-8l-3-4v-36l3-1h4v-3h14l1 3 6-6h7l4-4h7l1-3h35l5 5 8-1v13l-3-2 1 3h3l2 2-4-1 1 2 5-1v13h-5l4 3-1 3v-4h-2v5l3-1v3l-3-1v2h3l1 12-17 17h-35l-3-3Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="M170 160v-1h1v1h-1Zm-6 2v-1h1v1h-1Zm-36 0v-1h1v1h-1Zm-4-2-2-2 4 3v1h-1l-1-2Zm5 4v-1h1v1h-1Zm2 1v-1h1v1h-1Zm31 2v-1h1v1h-1Zm-32 0v-1h1v1h-1Zm25-65v-1h-17v2h17v-1Zm-18 0v-1h-4v2h4v-1Zm-5 1v-1l-3-1v2h3v-1Zm-4 0h-1l-1 1h2v-1Zm-1 2h-1l-1 1h2v-1Zm24 1-4-1-8 2h15l-3-1Zm-29 1 1-1-1-1-3 3h1l2-1Zm27 2 1-1h-5v2h4v-1Zm26 0v-3h-3v5h3v-2Zm-52 1v-1h-3v2h3v-1Zm-9 1 2-1h-5l-1-3v5h2l2-1Zm-5 0v-1l-1-1-2 3h2l1-1Zm-15 1v-1h-1v1h1Zm50 0 1-1-1-3h-2l-5 2 2 3h4l1-1Zm-26-1-1-2v4l1-1v-1Zm-9 3h-1l-3 1h6l-2-1Zm-5 1v-1h-1v1h1Zm17 0v-1h-9l1 2h8v-1Zm50 9v-1h1v1h-1Zm0 2v-1h2v-2l-6-9-7-5 1-1-6-1 7 4 6 6 3 5h-2v3l2 2h1l-1-1Zm-46-4h-2l-1 5 3-4v-1Zm-6 4h-1v2l1-1-1-1Zm56 6v-4l-2-3v14l2-2v-5Zm-68-14v-1h1v1h-1Zm5 8v-1h1v1h-1Zm4 8v-8l4-9h-8l-4 2 3-3H99v4h9v21h8v-7Zm5 10h-1v2l1-1-1-1Zm0-24v-1l2-1v2l-2 1v-1Zm2 24-2-3v-14l5-12 7-5 7-3h-4l-9 6-1 2-2-1v4l-2-1-2 3 1 2-2 9-1 10 5 5-2 1 2 3 2-2-2-4Zm56 4v-3h-2v6h2v-3Zm-3 0v-2l-3 4v1h3v-3Zm-82-17v-1l1 2-1 1v-2Zm7 5-1-1v-2h2l1 4h-1l-1-1Zm-6-9v-1h-1l-1 2h2v-1Zm-3 4h-1v2l1-1-1-1Zm-2-1-1-2v7l1-3v-2Zm2 7v-1h-3v3l4-1v-1Zm3 3h-2l-4 1h8l-2-1Zm-6 1h-1v-17h2l-1 3 2 1 3-3 7-1-1 2 2 1 2-3 1 12-2-7-3-2h-2l4 3v2l-5-5 2-1h-2l-4 4v4l7 1v3l-5-1-3-3v2l3 1-1 1h8l3-1-1 2-7 2h7l-15 1-1-1Zm8 2h3l6 1H93l4-1Zm-10 0h2l5 1h-9l2-1Zm34 7-1-2-10-1-1-1 10 1v-1l-4-4h-6l-2 2v-22H86l-1 20v-20l2-2 10-1 1-3H84l1-1 12-1H85l-3 3v31l3 4h36v-2Zm38 6v-1h-1v1h1Zm-50 0h2l-3-3h-3l1 2h-2v-2h-4v4h7l2-1Zm-10-3h-1l-3 1 3 3 1-3v-1Zm50 4h-1l-3 1h4v-1Zm0-40v-1h1v1h-1Zm-2 2-3-1h5l1 2-3-1Zm15 1v-1h-5l-1-3 2 2h4l2 3h-1v-1Zm-19 1v-1h1v1h-1Zm10 1h1l2 1h-5l2-1Zm-15 0v-1l5 1v1h-5v-1Zm-9 2v-1l1-1 1 3h-1l-1-1Zm20 2v-1h1v1h-1Zm13 1v-1l1 1-1 1v-1Zm-18 1v-1h1v1h-1Zm-13-1v-1l1 1-1 1v-1Zm5 2v-1h1v1h-1Zm20 1v-1h1v1h-1Zm-6 0v-1h1v1h-1Zm-20 0v-1h1v1h-1Zm22 2v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm-14 1v-2h4l1 2-3-1-3 2v-1Zm38 2v-1h1v1h-1Zm-5 2v-1h1v1h-1Zm-27 0v-1h1v1h-1Zm-8-1v-1l1 2-1 1v-2Zm1 4v-1h1v1h-1Zm1 2v-1h1v1h-1Zm43 0-1-1 2-1v3h-1l-1-1Zm-5 0 1-1h1l-1 2h-1v-1Zm-33 1v-1h1v1h-1Zm27 2v-1h1v1h-1Zm3 1-2-1h4l1 2h-2l-1-1Zm-3 1v-1h1v1h-1Zm-8 0v-1h1v1h-1Zm-18-1v-1h2l-1 2h-1v-1Zm32 3v-1h1v1h-1Zm-21 2v-1h1v1h-1Zm12 0-2-1h3l1 2h-1l-1-1Zm-4 0 1-1h1l-1 2h-1v-1Zm-12 0 2-1 1 1-5 2 2-2Zm-7 2v-1h1v1h-1Zm13 4 1-2-1-3 5 2-4 2h5v2l6-2v-3l4 1 3-4 4-2 4-6v-5l-2 2 1-4 2 1v-8l-3 2 1 4-3-2-3 1v-3h4l2-3-3-3h-4l1-2 3 1 2-3-4-4h-3l1-3-5-3-2 2-2-4h-3l-2 2 2 3h3l2 2-5-1-3-3h-3l-2 3-5 1-2-4h-2l-4 2v4l4 1 4-3-3 4h-3l-3 2 2-2-2-4-5 4v2l3 2-4 1v5l-2-1-1 4 3 11h1v2l6 6v2l7 1-3 2h5l1 2h2l1-2Zm33 0 2-3-1-1-4 2-1-2-3 1 3 5h1l3-2Zm-42 1-2-1-8-8-1 2 4 5-1-3 2 1v3h4l-1 2h5l-2-1Zm-12-4v-1h-8v1l4 5 4-5Zm18 5h-1l-3 1h4v-1Zm17 1h1l-1-2 3 1-1-2h5v-3l4-1-1-2h2l-1-2h2l3-9h-2l-2 8-3 2v3l-2-1-3 4-10 4v1l5-2 1 1Zm-9 0h-2l-5 1h10l-3-1Zm9 4v-2h-23v3h23v-1Zm-32 4-3-4v-1l7 7h33l10-10-2-4h-3l-7 5-3 1 2 2 4-1-1 2h-4v2h-25v-5l-10-7-5 5 3 4-9-9-4 3H97l-5-5h-8l-3-4v-36l3-1h4v-3h14l1 3 6-6h7l4-4h7l1-3h35l5 5 8-1v13l-3-2 1 3h3l2 2-4-1 1 2 5-1v13h-5l4 3-1 3v-4h-2v5l3-1v3l-3-1v2h3l1 12-17 17h-35l-3-3Z" style="fill:';
    string private constant PART_11 =
        '"/><path d="M146 100v-1h1v1h-1Zm6 0v-1h4l-3 2h-1v-1Zm-9 0h1l1 1h-2v-1Zm-20 6v-2h2l-1 3h-1v-1Zm-12 11v-2l1 1-2 3v-2h1Zm-4 4v-1l1 1-1 1v-1Zm0 3v-1l1 1-1 1v-1Zm-19 1v-1h1v1h-1Zm-3-1v-2l14-2 8 2H86l-1 3v-2Zm27 2v-1h1v1h-1Zm-5 1v-1h1v1h-1Zm-9 1v-1h1v1h-1Zm9 1v-1h1v1h-1Zm-19-1v-1l1 1-1 1v-1Zm-3-1v-1l1 2-1 1v-2Zm16 1-1-2h-4v3l-2-3 1-2 4 1 3 2 2-1v4h-1l-2-2Zm-13 3v-1h1v1h-1Zm16 2v-1h1v1h-1Zm-19 0v-1h1v1h-1Zm3 1v-1h1v1h-1Zm-3 1v-1h1v1h-1Zm94 0-1-2 2 2-1 2v-2Zm-86-6v-1h-1v1h1Zm-1 2-1-2v6l1-3v-1Zm0 6-2-2v-5l2-3 2 1-2 7 1 2h2l-1-2 4 1 3-3h1v3l-3-1 1 2h-8Zm-7 2v-3l1 3-1 3v-3Zm7 2 4-1h-8v-5l1 4 16-1-1 2h-7l7 2H88l4-1Zm6 2h1l1 1h-4l2-1Zm-3 1v-1h1v1h-1Zm-7-1h1l1 1h-4l2-1Zm-3 1v-1h1v1h-1Zm19 10h1l1 1h-2v-1Zm16 4v-1h1v1h-1Zm50 2v-1h1v1h-1Zm-46 1v-1l2 1v1h-1l-1-1Zm39 3v-1h1v1h-1Zm-34 0v-1h1v1h-1Zm-6 0v-1h1v1h-1Zm12 2h-1v-4l2 3h22v-1h2l-2 3h-23l-1-1h1Zm-11 0v-1l2 1v1h-1l-1-1Zm40-64-2-2-3 4 5 3 2-3-2-1v-1Zm7 5v-2h-2v3h2v-1Zm-3-1v-2l-2 2-1 2 4 3-1-5Zm-50 2v-1h-1v1h1Zm53 2-1-2v4l1-1v-1Zm-62 0v-1l-3 2v1h3v-2Zm14 2 1-1v-2h-7v4h4l2-1Zm-7-1v-2l-2 1-4-1 6-2h-6v5h6v-1Zm-16 1v-1h-3l1 2h3l-1-1Zm-4-1h-5l1 2 4-1v-1Zm-6 0h-1v2l1-1-1-1Zm90 11-1-1-4-1 1 3h4v-1Zm-1 3v-1l-2 1v3l3 2-1-5Zm0 23v-3h-2v6h2v-3Zm-3 0v-4l-4 7h4v-3Zm-24-43h1l1 1h-4l2-1Zm6 3v-1h1v1h-1Zm-17-1h2l3 1h-6l1-1Zm-5 0 1-1 2 1-4 1 1-1Zm27 4v-1h1v1h-1Zm-29-1v-1l5-1-5 3h-1v-1Zm14 1v-1l2 1v1h-1l-1-1Zm-5 2v-1h1v1h-1Zm-18 2v-1h1v1h-1Zm38 1 1-2-5-4-2 1-2-3h-6v-1l8-1-2 2 5 2 8 6 1-2v2l-2 1-3-2-3 3 2-2Zm-7 1v-1h1v1h-1Zm-29-1v-2l4-2-3-2h3l1 2-3 2-3 3v-2Zm-3 3v-1h1v1h-1Zm47 1v-1h1v1h-1Zm-22 0v-1h1v1h-1Zm-27 0v-1l2 1v1h-3l1-1Zm46 0v-2h1l2 4h-3v-2Zm-43 3v-1h1v1h-1Zm46 1v-1h1v1h-1Zm-7 0v-1h1v1h-1Zm-42-1v-1l1 1-1 1v-1Zm-2 0v-1l1 1-1 1v-1Zm49 3v-1h1v1h-1Zm-48 0v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm55 2v-1h1v1h-1Zm-53-1h1l1 1h-2v-1Zm51 1h-1l2-4-1-4 2 3-2 6v-1Zm-3 2v-1h1v1h-1Zm-13 0v-1h1v1h-1Zm16 1v-1l1 2-1 1v-2Zm-3 3v-1h1v1h-1Zm-46 4v-1h1v1h-1Zm-2 0h-1v-10l2 10-1 1-1-1Zm51 0v-3l1 3-1 3v-3Zm-4 3v-1h1v1h-1Zm3 1v-1l1 1-1 1v-1Zm-36 13v-1h1v1h-1Zm29-2v-1h-1v1h1Zm-3 2v-1h-1v1h1Zm-2 0-2-1h6l-1-2h2l5-5v-3l2 1-2 4-8 7h-1l-1-1Zm-11 2v-1h1v1h-1Zm-3 0v-1h1v1h-1Zm-14-4v-1l-2-1 1 2h1Zm9 6h-2l-6-3-7-7-4-9h1l4 8 6 4-1 3 3-1-1 2 8 2 11 1 6-3 1 1-7 3h-11l-1-1Zm20 0 4-2 6-5 5-9v-10l1-1-3-4 3 2v-5l-4-9-4-4-2 1 1-2-6-4-8-3h-11v2l-5-1-5 2 1 2-3-1-9 9-3 10v16l7 11 8 6 9 2 14-1 4-2Zm-32 11v-1l1-1v2h35l14-15 1-2h-8l-1 1 2 3-3-2-10 6-1 2h-20l-7-3-9-7h-7v2l5 4v2l-6-6-3 2h-1l1-3v-3l10 1-1-4-10-1-1-1 10 1v-2l-3-3h-7l-2 2v-15l1 12h8v-14l2-5 2-5-5-1h6v-2H99l-1 2v-2H84l-2 4v31l3 2 7 1 5 5h2v-4l-4-1h15l-10 1v4l9 1H97l-5-5h-8l-3-4v-36l3-1h4v-3h14l1 3 6-6h7l4-4h7l1-3h3l-3 4h-5l-5 5h9l-3-2h4l-2-2 6 1v-6l1 5h4v-5l1 4h20l-1-4h6l5 5 5-1 3 1v12l-3-3 2-1-1-6-2-1v9l4 6h4l1 12-4-1v8l3-1v3l-4-1v2h3l1 7-1 3h2v2l-18 17h-34l-1-1Z" style="fill:';
    string private constant PART_12 = '"/>';
    string private constant COLOR_1 = "hsl(187, 76%, 57%)";
    string private constant COLOR_2 = "hsl(187, 75%, 47%)";
    string private constant COLOR_3 = "hsl(195, 78%, 40%)";
    string private constant COLOR_4 = "hsl(205, 80%, 30%)";
    string private constant COLOR_5 = "hsl(220, 3%, 73%)";
    string private constant COLOR_6 = "hsl(215, 4%, 43%)";
    string private constant COLOR_7 = "hsl(206, 47%, 30%)";
    string private constant COLOR_8 = "hsl(213, 9%, 20%)";
    string private constant COLOR_9 = "hsl(213, 10%, 18%)";
    string private constant COLOR_10 = "hsl(223, 10%, 13%)";
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
