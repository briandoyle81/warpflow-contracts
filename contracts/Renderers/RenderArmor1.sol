// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderArmor1 {
    string private constant PART_1 = '<path fill="';
    string private constant PART_2 =
        '" d="M132 169v-2l-2-2-3-2h-10l-7-7h-6v1l-1 2H91l-2-3h-5l-1-1h-2v-35l7-6h5l4-5h17l2 2 2 3h4l5-6 6-5h36l5 4 4 4v6l-2 1v30l-5 5v5l-9 10v3h-30v-2Z"/><path fill="';
    string private constant PART_3 = '" d="M97 111h14v11H97z"/><path fill="';
    string private constant PART_4 =
        '" d="M165 106h-1l-3 1h6l-2-1Zm-8 0h-8 11-3Zm-11 0h-8 11-3Zm-9 0-1-1-1 1v1h2v-1Zm-3 2v-1h-1l-1 2h1l1-1Zm4 2h-1v1h1v-1Zm-9 2h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm-10 3v-1h2v2h-2v-1Zm3 0-1-3-1-1-2 3-2 2v1h8l-2-2Zm-14 1h3l6-5h-4l1 1-1 1-1 2h-7l-2 3 1-1 1-1h3Zm36 2-1-1-1 1v1h2v-1Zm-3 0-1-1-1 1v1h2v-1Zm12 0h-7l2 1h5v-1Zm26 1-1 2 3-1h2v-1h6-1v-1h-34l1 1h22l-1 2 3-3v1Zm-21 1h-1v1h1v-1Zm28 1 2-2-2 1-2 2h-5l-5-1-1 2h12l1-2Zm-50 1v-1h-1l-1 2h1l1-1Zm-13 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-17-2h3v2l1-1 1-1h8-1v-1H85l-2 2v2l1-1 1-2h3Zm51 4h-1v1h1v-1Zm-19 0-1-1-1 1v1h2v-1Zm49 1h-1v1h1v-1Zm-13 0h-1v1h1v-1Zm-13 0h-1v1h1v-1Zm-18-1v-1h14l1 1 1 1v-2h15v-2l-8 1h-22l-1-1-2 2-1 1v1h3v-1Zm20 1-1-1v3l1-1v-1Zm10 2h-1v1h1v-1Zm-16 0v-1h-1l-1 2h1l1-1Zm-3 2h-1v1h1v-1Zm-29 0h-1v1h1v-1Zm46 1h-1v1h1v-1Zm-64 0v-1h-1l-1 2h1l1-1Zm80 1h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-43 0h-1v1h1v-1Zm10 1 2-2-2 2-2 1v1h1l1-2Zm30 3h-1v1h1v-1Zm-40 0h-1v1h1v-1Zm46 0-1-1v3l1-1v-1Zm-60 1v-1h-2v2h1l1-1Zm-9-1h-4l-1 1 8-1h-3Zm-7 0 1-1h-2v3h1v-2Zm76 3h-1v1h1v-1Zm-46 0h-1v1h1v-1Zm35 3 1-2h-1l-3 4h1l2-2Zm1 3h-1v1h1v-1Zm-36-1 1-1h-2v3h1v-2Zm43 2h-1v1h1v-1Zm-12 0v-1h-1l-1 2h1l1-1Zm-12-1 1-2h-1l-3 4h1l2-2Zm16 3h-1v1h1v-1Zm-6 0-1-1-1 1v1h2v-1Zm-3 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-3 0-1-1-1 1v1h2v-1Zm-3 0h-1v1h1v-1Zm-2 0h-2l-1 1h3v-1Zm-14 6h-1v1h1v-1Zm-17 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm65 3h-1v1h1v-1Zm-13 0-1-1-1 1v1h2v-1Zm-9 0h-1v1h1v-1Zm16 1v-1h-2v2h1l1-1Zm-12 7h-1v1h1v-1Zm-10 5v-2l-2-2-3-2h-10l-6-7h-7v1l-1 2H91l-2-3h-5l-1-1h-2v-35l7-6h5l4-5h17l2 2 2 3h4l5-6 6-5h37l8 8v6l-2 1v30l-5 5v5l-9 10v3h-30v-2Z"/><path fill="';
    string private constant PART_5 =
        '" d="M165 106h-1l-3 1h6l-2-1Zm-10 0h-17 23-6Zm-18 0-1-1-1 1v1h2v-1Zm-4 2 2-2-2 2-2 1v1h1l1-2Zm5 1-1-1v3l1-1v-1Zm-27 2h-1v1h1v-1Zm2 1h-1v1h1v-1Zm16 1v-1h-1l-1 2h1l1-1Zm-26 2h1v1h-1v-1Zm3-1-1-2h-2l-3 5h8l-2-3Zm-17 3v-1h6l6-5h-4l1 1-1 1-1 2h-6l-4 3h2l1-1Zm27 2h-4l-1 1 8-1h-3Zm-10 3h-1l-3 1h6l-2-1Zm-18-2h3v2l1-1 1-1h8-1v-1H85l-2 2v2l1-1 1-2h3Zm29 3h-1v1h1v-1Zm22 1h-1v1h1v-1Zm30 0-1-1v3l1-1v-1Zm-4 1h-1v1h1v-1Zm-9 0h-1v1h1v-1Zm11 1h-1v1h1v-1Zm-22 0v-1h-3l1 1v1h2v-1Zm16 1h-1v1h1v-1Zm-5 2h-1v1h1v-1Zm-18-1 1-2h-1l-3 4h1l2-2Zm-4 1h-1v1h1v-1Zm13-10h1v1h-1v-1Zm14 1h1v1h-1v-1Zm-11 0-1-1h3l-1 2h-1v-1Zm15 1-1-1h1l2 1v-2l1-1v3l-2 1-1-1Zm-6 0-1-1h-1l-2 1v-1l-1-1 5 1h1v1l-1 1v-1Zm-12 0h1v1h-1v-1Zm-27 2-1-1h1l2 1 1-2v-2h7v2l1-1 2-1 1-1 1 2 2 1v-2l3 1 2 1 1-1 1-1h2v2l-2 1h-12l-3-1h-2l-2-1h-1v2l-1 2h-3v-1Zm4 2 1 1v-3h14l1 1 1 1v-2h8l8-1v1l13-1-1-2h4v-2h-49l-3 2-2 2-1 1v2h4v5l1-2v-3h1Zm30 4 1-2h-1l-2 4h1l1-2Zm-65 0 2-2-2 2-2 1v1h1l1-2Zm77 2h-1v1h1v-1Zm-14 1h-1v1h1v-1Zm-29-1-1-1v3l1-1v-1Zm-16-1-1-2v5l1-1v-2Zm14 3h-1v1h1v-1Zm12 0 1-2h-1l-3 4h1l2-2Zm30 2h-1v1h1v-1Zm-13 0v-1h-1l-1 2h1l1-1Zm-27 0h-1v1h1v-1Zm-37 0h-1v1h1v-1Zm83-3-1-2v7l1-3v-2Zm-60 4v-1h-2v2h1l1-1Zm-9-1h-4l-1 1 8-1h-3Zm-7 0 1-1h-2v3h1v-2Zm35 3v-1h-1l-1 2h1l1-1Zm-5 0h-1v1h1v-1Zm46 0-1-1v3l1-1v-1Zm-43 2h-1v1h1v-1Zm33 4h-1v1h1v-1Zm-34 0h-1v1h1v-1Zm-1-2h-1l-2 1 1 2 2-3Zm-4 2-1-1h-3l4 2v-1Zm49-2-1-2v6l1-1v-3Zm-3 3h-1v1h1v-1Zm-5-8v-1l-4 4v-1l-1-1 1 3-2 1-2 2-1-1v3l5-4 4-5Zm6 10-1-1-1 1v1h2v-1Zm-5 0h-7 10-3Zm-10 0-1-1-1 1v1h2v-1Zm-8 0h-5l3-4 3-3-2 2-2 1v-1l-1-1 1 3-1 1-2 1v2h6l6-1h-6Zm-10 0h-9 12-3Zm-20 6h-1v1h1v-1Zm-14 0h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-2 1v-1h-2l1 2h1v-1Zm65 2h-1v1h1v-1Zm-13 0-1-1-1 1v1h2v-1Zm7 1v-1h-2v2h1l1-1Zm-16-1-1-1v3l1-1v-1Zm17 5h-1v1h1v-1Zm-6 0h-2l-1 1h3v-1Zm10 3h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-4 0h-2l-1 1h3v-1Zm-11 5v-2l-2-2-3-2h-10l-6-7h-7v2H90l-1-2h-5l-1-1h-2v-35l7-6h5l4-5h17l2 2 2 3h4l5-6 6-5h37l8 8v6l-2 1v30l-5 5v5l-9 10v3h-30v-2Z"/><path fill="';
    string private constant PART_6 =
        '" d="M159 106h-24 32-8Zm10 3-1-1-1-1v2l1 1h1v-1Zm-30 1v-1h-2v2h1l1-1Zm-6-1 1-2h-1l-3 4h2l1-2Zm-20 3-1-1h-2l3 2v-1Zm16 0-2 1v4l2-4v-1Zm-21 4v-1l-2-2-2-1h-1l-2 1v2l-1 2h8v-1Zm8 3h-4l-1 1 8-1h-3Zm-6 2h-1v1h1v-1Zm-20 0h-1v1h1v-1Zm16 1h-1l-3 1h6l-2-1Zm-11-8h1v1h-1v-1Zm-7 6h3v2l1-1 1-1h8-1v-1H87l2-3h6l6-5h-4v3l-1-1h-1v1l-1 1h-5l-3 3-3 3v2l1-1 1-2h3Zm21 3h-1v1h1v-1Zm30 1h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-4 1h-1v1h1v-1Zm38 1-1-1h-3l4 2v-1Zm-16 0h-1v1h1v-1Zm-6 0v-1h-3l1 1v2l1-1h1v-1Zm-19 1h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-24 0h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm67 0 1-1h-1l-1 1v2h1v-2Zm5 2h-1v1h1v-1Zm-10 0h-1v1h1v-1Zm-28 0h-1v1h1v-1Zm43 1h-1v1h1v-1Zm-12 0h-1v1h1v-1Zm-3-4v-1l-2 3-2 3 4-4v-1Zm-13 4h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2-4-2 1h-3v1l-1 1 1-1h2l-1 3 2-2 2-2v-1Zm-13 4h-1v1h1v-1Zm-37-1 2-2-2 2-2 1v1h1l1-2Zm77 2h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-52 0h-1v1h1v-1Zm48 1h-1v1h1v-1Zm-8 0h-1v1h1v-1Zm-45-2-1-2v5l1-1v-2Zm36 2-1-1v3l1-1v-1Zm-22 1h-1v1h1v-1Zm-34-1-1-1v3l1-1v-1Zm58 2h-1v1h1v-1Zm-12-1 1-2h-1l-3 4h2l1-2Zm17 0h-1v1l-1 2 2-2v-1Zm-64 2h-1v1h1v-1Zm60 1h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm-20 0v-1h-3v2h2l1-1Zm46 1h-1v1h1v-1Zm-20 0h-1v1h1v-1Zm-35-1 4-1h-8l-3-2-2 1v3l3-4v3l-1 2 1-1 1-1h4Zm32 2v-1h-2v2h1l1-1Zm-5 0v-1h-1l-1 2h1l1-1Zm-8 0h-1v1h1v-1Zm-33 0-1-1v3l1-1v-1Zm74 2h-1v1h1v-1Zm-35 0h-1v1h1v-1Zm23-21h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-22 0h1v1h-1v-1Zm42 1h1v1h-1v-1Zm-22 0v-1h1l-1 2h-1l1-1Zm-8 0h1v1h-1v-1Zm-8 0-1-1h2v2h-1v-1Zm6 0h-1v1h1v-1Zm-2 1-2-1 4-1 1 1v1h-1v1l-2-1Zm8 0h-1v1h1v-1Zm-1 1-1-1 1-1h1v1l1 1h-1l-1 1v-1Zm-19 1 1-1 1 1v1h-2v-1Zm2 9v-7h1l1 1v-3h14l1 1 1 1v-2h27v5l1-3 1-4 3-1v-2h-49l-3 2-3 2 1 1v1l-1-1h-2v1l-1 1h7v16l1-1v-8Zm31 7h-1v1l-1 2 2-2v-1Zm-17 2h-1v1h1v-1Zm-20 0h-1v1h1v-1Zm33 1h-1v1h1v-1Zm-61 0h-1v1h1v-1Zm48 1h-1v1h1v-1Zm-46 0h-1v1h1v-1Zm41 1h-1v1h1v-1Zm37-6v-8l-1 7v9h1v-8Zm-10 7v-1h-2l1 2h1v-1Zm5-12v-1l-6 8-1-1-1-1v1l1 2-2 1-2 2-1-1v3l6-6 6-6v-1Zm-44 11v-1l2 1v1h-2v-1Zm3 1v-1h1l1 1-1-3h-2l-1 1v-3l-1 2v1h-4v1h-1v1h1l7 1v-1Zm43 2h-1l1-1v-1l-1-1h-1v3h-9l13 1-2-1Zm-13 0h-2l-1 1h5l-2-1Zm-9 0h-5l3-4 3-3h1l1 1v-1l-1-1-5 4v-1l-1-1v2l1 1h-3v4h6l6-1h-6Zm-8 0v-1h-12v2h12v-1Zm-22 6h-1v1h1v-1Zm-14 0h-1v1h1v-1Zm-3 0-1-1v3l1-1v-1Zm-2 1v-1h-2v2h2v-1Zm65 2h-1v1h1v-1Zm-5 1v-1h-3v2h2l1-1Zm-7 0v-1h-3v1h3Zm-9 0v-1h-2v2h1l1-1Zm18 4h-1v1h1v-1Zm-4 0h-8 11-3Zm-9 0-1-1-1 1v1h2v-1Zm15 3h-2l-4 1h8l-2-1Zm-7 0h-2l-1 1h3v-1Zm-5 0h-2l-1 1h5l-2-1Zm-4 0h-2l-1 1h3v-1Zm-6 0-1-1-1 1v1h2v-1Zm-5 5v-2l-2-2-3-2h-10l-6-7h-7v2H90l-1-2h-5l-1-1h-2v-35l7-6h5l4-5h17l2 2 2 3h4l5-6 6-5h37l8 8v6l-2 1v30l-5 5v5l-9 10v3h-30v-2Z"/><path fill="';
    string private constant PART_7 =
        '" d="m169 109-1-1-1-1v2l1 1h1v-1Zm-5 0h-2l-1 1h5l-2-1Zm-19 0-1-1-1-1v2l1 1h1v-1Zm8 0-1-1v3l1-1v-1Zm-2 0-1-2v4l1-1v-1Zm-4 1h-1v1h1v-1Zm-8 0v-1h-2v2h1l1-1Zm32 1h-1v1h1v-1Zm-16-2h1v1h-1v-1Zm1 0v-1h-1l-1 1v3l2-1 1-1-1-1Zm7 3v-1h-1l-1 2h1l1-1Zm-23 0h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-21 0-1-1h-2l3 2v-1Zm43 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm5 0v-1h-1l-1 1 1 1v1h1v-2Zm-2 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-8 0v-1h2l3 1v-1l1-1h-4l-2-1h-2l3 2h-3v2h2v-1Zm-35 0h-1v1h1v-1Zm21-5 2-3h14v4l1-2v-2h16l1-1h-31l-4 3-4 4v4l1-2 1-3 3-2Zm-32 5h1v1h-1v-1Zm8 1v-1l-2-1-1-2h-3l-3 3 1 2h8v-1Zm12 3h-1v1h1v-1Zm-4 0h-4l-1 1 8-1h-3Zm-6 2h-1v1h1v-1Zm-20 0h-1v1h1v-1Zm5-7h1v1h-1v-1Zm-7 6h3v2l1-1v-1h8l2 3h3l3-1h-6l-2-3H87l3-3h5l6-5h-4v3l-1-1h-1v1l-1 1h-6l-3 3-3 4h1v1l1-2 1-1h3Zm21 3h-1v1h1v-1Zm-18 0h-1v1h1v-1Zm-3 0v-1h-1l-1 2h1l1-1Zm-3 2h-1v1h1v-1Zm36 2h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-17 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-3-1-1-1v3l1-1v-1Zm-2 1h-1v1h1v-1Zm29 2-1-1-1 1v1h2v-1Zm-29 0h-1v1h1v-1Zm-8 0h-1v1h1v-1Zm88 1-1-1-1 1v1h2v-1Zm-83-1 2-2-2 2-2 1v1h1l1-2Zm51 2h-1v1h1v-1Zm-27 0-1-1-1 1v1h2v-1Zm-12 0h-1v1h1v-1Zm65 0-1-1v3l1-1v-1Zm-40-1 1-1 1 1v1h-2v-1Zm4 1v-1l-2-2h2v2l2-1 2-2-2 2-1 2 1 1 7-8h-7 1l1 1v3l-4-2 1-1v-1h-2l-2 1v1l1 1h-3l1 3v2l1 1h3v-2Zm-45 1v-1h-2v2h1l1-1Zm24 0h2l-2-1-1-1-1-1-1-1v6l1-1v-1h2Zm1 4v-1h-3v2h2l1-1Zm-23-2h1l-1-1v-1l-1 1-1 1v3l1-3h1Zm14 2 4-1h-8l-3-2-2 1v3l3-4v3l-1 2 1-1 1-1h4Zm-14 2-1-1v3l1-1v-1Zm-3 1h-1v1h1v-1Zm45-1-2-2 1-1v-1h-3l1 2 1 2h-1v1l2-1v3h2l-1-3Zm-29 3v-1h-1l-1 2h1l1-1Zm-11 0-1-1v3l1-1v-1Zm2 2h-1v1h1v-1Zm5 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm43-24h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm-8 3h1v1h-1v-1Zm45 2v-1l-4 2-4-3h10l-3 4 1-2Zm-22 2h1v1h-1v-1Zm-3 2h1v1h-1v-1Zm18-1v-1h-1l-2 1v1h2l1-1Zm-3 1-3-1v-1l1-1h-5l-5-1-1 1-1 1v-1l1-1h-2v-2h16v2h-2v1l-1 2 2-1h2l3-1 3 2-4-1v1l2 3h-2l-4-2Zm-1 2h1v1h-1v-1Zm-12 0v-1h2v1h-3 1Zm-22 1h1v1h-1v-1Zm31 0v-2l-1 1-1 1 1-2h-4 2l-1-2-1-2 2 2 3 2 1-1v-1l-1 3h2v1l-1 1 4 1-3-1h-3l1-1Zm-9 1h1v1h-1v-1Zm-10 0h1v1h-1v-1Zm33 2h1v1h-1v-1Zm-23 0 1-1 1 1v1h-2v-1Zm-12 1v-2l1 1v1l-1 1v-1Zm22 0v-1h1v1l1 1h-3l1-1Zm-11 1h1v1h-1v-1Zm-22-1-1-1-1-1v-1h2l2 1v3l-1 1-1-2Zm46 2v-1l2 1v1h-2v-1Zm-27 1v-2l1 1v1l-1 1v-1Zm20 0h-1v1h1v-1Zm-2 0-1-2 2 1v-2l-1-1h1l1 1v-3l1 2 1 1-1 1-1 1 1 2h-1l-1 1-1-2Zm-8 1v-1h4v2l-2-1h-3 1Zm-11 1h1v1h-1v-1Zm27 3-1-1h3l-1-2h2v1l-1 1v2h-2v-1Zm1 2h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-13 0h1v1h-1v-1Zm-12 0-1-1 1-3v-5l1 2 1-1 2-1v4l-2-1v3l-1 1h5l2-2 1-2h-1v-1h3v-2h3l2-5v2l-1 2 1-1h2v3l-1-1-1-1-3 4v-2l-2 2-2 2 1 1 2-1 2-1 2 1 1 2h-3v-2l-2 1-1 2h-2v-2l-3 2 2 2-3-1h-5Zm-7 0v-1l-2 1 1-2 1-2 2 1 1 1-1 2h2l1-2v1l-1 1-4 1v-1Zm23 1-1-1h2l3-3 2-2-1-2h2l1 1-2 2-1 2 4-4 1 1h2v-2l-1-1 2-2 2-1h1v3h-3v2h4l-3 1-2 1v1l3-2-2 2-1 2-1-2-2 1-2 1 1 2h-2v-2l-1-1h-1l-1 1 1 1 2 1-4-1-1 2h17l2-3v-15l-1 2-2 2-1-1h-2v2h-2v-2l-1-1h4v-2h1l1-1 1-2h1l1 1v-5l4-4v-1h-49l-9 6 4 1-1 1-1 1h2l1-2h2v5l-2 1-3 2 1-3v-3l-1 2-1 2 1 2 1 2h-1l-2-1v5l2-4v1l1 3v3l-1-1-1-1-1 3v3l2-1h3l-1-3v-3h2l1 1v1l1-1h1l-1-1v-2l2 2-1-1v-3l-1-1h2l1-1-2-2-1-2h2l-1-2v-2l2 1 2 1-2-2-2-1h1l1-1h14v2l1 3-1-1-2-1-1 1 1 4 1-1h1l1 1v1l-1 1-1 1 1 2h-4v-5l1 2 1 1v-1l1-1-3-1 1-2v-2l-1 1-1 1v3l-2-1-2 3-2 2 1 2v2l1-1h1v3l-3 1-2-3h-3l1 3-2-1-3-1v2l1 2 2 1 2 2h24v-1Zm-64 0h-1v1h1v-1Zm27 3v-1h-1l-1 2h1l1-1Zm-20 0h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm25 3-1-1-1 1v1h2v-1Zm-15 0h-1v1h1v-1Zm-3 0-1-1v3l1-1v-1Zm-2 1v-1h-2v2h2v-1Zm66 3v-1h-2l1 2h1v-1Zm-6 0v-1h-3v2h2l1-1Zm-7 0v-1h-3v1h3Zm-8-1-1-1h-2v3l2-1h1v-1Zm14 5h-12 16-4Zm-21 1-1-1-1-1v2l1 1h1v-1Zm27 2 1-1-8 1h-15l22 1v-1Zm-23 0-1-1-1 1v1h2v-1Zm-5 5v-2l-2-2-3-2h-10l-3-4-3-3h-7v2H90l-1-2h-5l-1-1h-2v-35l7-6h5l4-5h17l2 2 2 3h4l5-6 6-5h37l4 4 4 4v6h-1l-1 1v30l-5 5v5l-9 10v3h-30v-2Z"/><path fill="';
    string private constant PART_8 =
        '" d="M111 113v-1l3 2v1h-3v-2Zm-14 1h1v1h-1v-1Zm-9 4v-2l1 1 1 1v1h-1l-1-1Zm4 2 1-1 1 1v1h-2v-1Zm4 1v-2l1 1v1l-1 1v-1Zm-12 23h1v1h-1v-1Zm1 5-1-1h2v2h-1v-1Zm91-37-7-7 6 8h1v-1Zm-11-1v-2h-4v2l3-2-2 2-1 2h1l2-1 1-1Zm-2 3-1-1-1 1v1h2v-1Zm7-2h1v1h-1v-1Zm2 2 1-1-2-2h-2v5h3v-2Zm-40-5h1v1h-1v-1Zm5 2 1-1 1 1v1h-2v-1Zm-1 4v-2h5v-4h-2l-3 1v-2h8v9h16v-4l1-5 5-1 1 2 2 1-2-2-1-3h-32l1 3-1-1h-1l-3 3 1 1v1h-4v5h4l5-1v-1Zm-10 0-1-2v4l1-1v-1Zm49 6h-1v1h1v-1Zm-74 7h-1v1h1v-1Zm8 5h-1v1h1v-1Zm1-3h1v1h-1v-1Zm-3 0v-2l1 1v1l-1 1v-1Zm2 2h2v1l-1 1h1l2-1v-1h1l-1-2v-2h-7v6l1-1v-1h2Zm64 3h-1v1h1v-1Zm-62 1v-1h-4v2h4v-1Zm-10 0 5-1H96l-1-2-2-2v1l-1 2v3l3-4v3l-1 2 3-2h4Zm72 2h-1v1h1v-1Zm-63 0-1-1-1 1v1h2v-1Zm3 1h-1v1h1v-1Zm-2 1h-1v1h1v-1Zm-14 0-1-1-1 1v1h2v-1Zm10 1-1-2v4l1-1v-1Zm6 2h-2l-1 1h3v-1Zm-4 0h-1v1h1v-1Zm-11 1h-1v1h1v-1Zm-9-2v-2l1 1 1 1v1h-1l-1-1Zm4 1 1-1 1 1v1h-2v-1Zm3 1v-1h4v-3l-1 1-1 1h-7l-3-4v-4l1-4 1 1 2-2 2-1 4 2 4 2-3-2-2-2h3l-2-1-2-1h-2l-3 1-2 2-3 2v3l-1 3 2 3 1 3 2 1 3 1h3v-1Zm39-21h2l2 1h-5l1-1Zm25 1-1-1h9l-3 2h-3l-2-1Zm-29 0h1v1h-1v-1Zm-4 0 1-2 2 3h-4l1-1Zm-3 0h1v1h-1v-1Zm-4 1 1-1 1 1v1h-2v-1Zm45 1h1v1h-1v-1Zm-12 1 1-2h-13v-2h16v1l-2 2-2 2v-1Zm-17 1v-1l4-5v2l-4 4Zm22 1h1v1h-1v-1Zm-20 4h1v1h-1v-1Zm24 1v-1h1v2h-2l1-1Zm-2 2h1v1h-1v-1Zm-3 2 1-1 1 1v1h-2v-1Zm-28-4 6-6v1l-10 11h-1l5-6Zm-7 7 1-1 1 1v1h-2v-1Zm-2 2h1v1h-1v-1Zm45 1 1-1 1 1v1h-2v-1Zm-40 0h1v1h-1v-1Zm28 2h1v1h-1v-1Zm-14-2 3-3h1v3l-1-1-3 2-2 2 2-3Zm13 0 4-4h1l-1 1-1 1 1 1 1 1-3-1-2 2-2 3h18v-2h6l-3-1-2-1v-13h4l-2-1h-3l-1 1h-1v-1l-1 2-1 1v-2l3-2 2-2v-5l1 1v1l2-3 1-2v-1h-50v1l-1 1-2-1h-1l1 1v1l-2 1-3 2v22h8v2h26l3-4Zm21 4h-1v1h1v-1Zm-60 1h-1l-1 1-1 1 2-1 3-1h-2Zm8 2h-1v1h1v-1Zm-21 2-1-1v3l1-1v-1Zm-2 1v-1h-2v2h1l1-1Zm-3 0v-1h-2v2h2v-1Zm19 0 1-1h-2v3h1v-2Zm47 2v-1h-2v3h2v-2Zm-6 1v-1h-3v2h3v-1Zm-15 0-1-2h-2v3h3v-1Zm25 1h-1v1h1v-1Zm-8-1-1-2v4l1-1v-1Zm-10 0 1 1v-1l-1-2h-1l-1 4 1-1v-1h1Zm-11 1-2-1v2h2v-1Zm-11 1h-1v1h1v-1Zm36 5v-1h-1l-2 1v-1l1-2-8-1h-8l-1 1v1h13l1 1h1-21l-5-6-2 1v-3l-2 3v-3l-1 2 2 2 1 2 3-3-1 3 2 2 3 2h25v-1Zm-29 5v-2l-6-5h-10l-5-6h-7v2H90l-1-2h-6l-2-3v-33l7-6h4l-2 1-2 1-2 1-1 2 4 3-3-1-2-1h-1v31h24l1-1v-2l-1 1-1 1v-1l-1-2-1 2-1 1-8-1v-1h-2l1 2h-2v-2l-1-1-3 2 1-1 1-2-5-4-1-5 1-4v-3l3-3 3-3v-1h-1l-1 1 1-2v-3l1 3 1 2 4-1h3l1 1v1l1-1 1-1 3 1h4l1-2 2-2h6v-2h-5l-3 3-2 2-2-1-1-1h-3l-3 1v-2h1l1 1v-1l-1-1-9-1 10-1v2l1 1h4v-2l-1-1 5-1 5-1h2l-1-2-1-2-1 1-1 1v-1l-1-1H99l1 1v1l-2-2-3 2-2 2v-2l2-2 3-2h16l2 2 2 3h4l5-6 6-5h37l3 4 4 3-1 19v20l-3 2-2 2v5l-5 5-4 6v2h-30v-2Z"/><path fill="';
    string private constant PART_9 =
        '" d="M111 113v-2l2 2v1l1 1h-3v-2Zm-23 4h1v1h-1v-1Zm21 2-1-1 2-1h1l-2 3v-1Zm-5 2h-3l-1-2-1-2 1 2 1 1h7v2-1h-4Zm-14 0v-2l1 1v1l-1 1v-1Zm17 4h1v1h-1v-1Zm-23 10h1v1h-1v-1Zm25-2h-1v1h1v-1Zm-1 7-1-1 1-2h3l-3 2h3v-7l-1 2v1h-3l1-3h4v7l-2 1-2 1v-1Zm3 1h1v1h-1v-1Zm-21 1h1v1h-1v-1Zm8 7h1v1h-1v-1Zm66-35-2-1h3v-4h-4v6h5l-2-1Zm-23 0h-1l-3 1h6l-2-1Zm32 1v-2l-5-6 5 4 2 3 1-2-8-8v12h5v-1Zm-10 1h-1v1h1v-1Zm-25-5h1v1h-1v-1Zm-2 4v-2h6v-4h-3l-2-1h6v2l1 3-1 2-1 2h19v-9h6l-1-2-1-2h-30l-8 9v2l-2-3v4l6 1h6l-1-2Zm-22 7h-1v1h1v-1Zm-14 11-1-1-1 1v1h2v-1Zm-9 1h-1v1h1v-1Zm2 1 1-1 1 1v1h-2v-1Zm8 2h4v-2h-9l-1-1v-2l1 1 1 1v-3h-4l-1 3v3l-1 2 3-1 4-1h3Zm-3 2 1-1h-2l-4 3h4l1-2Zm7 4h-1v1h1v-1Zm42 6h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm23 2h-1v1h1v-1Zm-4-1v-1h-1v1l-1 2h3l-1-2Zm-5 1h-1v1h1v-1Zm-3 0h-2l-1 1h3v-1Zm-5 0h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-6 0v-1h-9v2h8l1-1Zm-10 0-2-1v2h2v-1Zm43-30h1v1h-1v-1Zm-2 2h1v1h-1v-1Zm2 1h1v1h-1v-1Zm-9 0h2v1h-3l1-1Zm-35 0 1-1 1 1v1h-2v-1Zm27 2v-1h-13v-2h16v1l-3 3v-1Zm-18 2v-1l4-5v2l-4 4Zm28 3h1v1h-1v-1Zm5 3h1v1h-1v-1Zm-7 0v-1h1l-1 2h-1l1-1Zm-33 0 7-6-6 7h-1v-1Zm31 2h1v1h-1v-1Zm-3 2 1-1 1 1v1h-2v-1Zm-31 0 1-2h1l-3 4h-1l2-2Zm46 2h1v1h-1v-1Zm-16 0h1v1h-1v-1Zm-33 1h1v1h-1v-1Zm18 1v-2l1 1v1l-1 1v-1Zm24 2h1v1h-1v-1Zm-40 0h1v1h-1v-1Zm27 0 2-2h1l-4 5h-1l2-3Zm-15 2 2-1 2-2-2 2-1 2h-1v-1Zm-15 0h1v1h-1v-1Zm-5 0 1-1 1 1v1h-2v-1Zm5 3h1v1h-1v-1Zm2 1 1-2h43v-2h4v1l-1 1-1-1-2 1-1 2 4 1 2-3 2-3v-15h-9l2-2h6v-2l1-2v-2l-1-2-1-1 1-1h-51v1l-1 1-1-1-1-2-1 3-1 3h-3v24l1 1 2 1 1-1-1 1 1 1 1 2h3l1-2Zm-11 0h1l1-1h-4l-2 1-1 2 4-1 1-1Zm-6 3-1-1-1 1v1h2v-1Zm-7 0-1-1v3l1-1v-1Zm-2 1v-1h-2v2h1l1-1Zm-3 0v-1h-2v2h2v-1Zm21 1v-2h-4v4h2l2-1v-1Zm-24 1h-1v1h1v-1Zm69 1v-2h-2v1l-1 1v2h3v-2Zm6 2h-1v1h1v-1Zm-2-1v-1l-2-1v4h2v-2Zm-41 0-2-1 1-1 1-1h-3v2l2 3h4l-3-2Zm38 3-1-1-1 1v1h2v-1Zm3 1h-1v1h1v-1Zm-2 1h-1v1h1v-1Zm-30 1-1-1v3l1-1v-1Zm13 2h-1v1h1v-1Zm7-4h2v1h-3l1-1Zm-6 0h2l2 1h-5l1-1Zm-4 0h1v1h-1v-1Zm2 3h9l1 1 1 1v-2h2l-1 2 2-1 2-2v-1l-2-1h-1l1-1v-1h-2v-4h-2l-1-1h-2v4h3v1l-1 1-3-2v-3h-1l-3-1h-2v4l4-1v2h-4l-1-4h-1l-5-1h-4v4l2 3h6l-3-1h-2v-2l-1-1 1-2v3h4l1-4v7l-3 1h-2l-4-4v-4h-7v3l1-1 1-1v1l-1 2 4 4h1l1-1 1 2 1 3v-1l1-1h9Zm14 4h-1v1h1v-1Zm-27 0v-2l-6-5h-10l-5-6h-7v2H90l-1-2h-6l-2-3v-33l7-6h1l-2 2-2 3 1 2-3-1v30l1 1h22l2-1 2-1v-2l-1-1h-7 1v-1l-3 1-3 2-6-1-5-5-2-5h1l2 3 2 4h4l3 1 5-2-1-1v-2l1 1 1 1 1-1v-1l-1-1h-1l-2 1-2 2h-5l-4-4v-5l2-2 2-2h3l3-1-1 1v1h1l2-1v2h1l2 1v-2l-3-3-4-2-2 1h-3v2h-2l-2 3-2 2v-3l4-3 3-2-1-2h1l1 1h4l5 2v2l3-1h4l-2 1h-1v8l1 7 3 1h4l-1-7v-9h-4l1-2 2-1v-3l-3 2 1-2 2-2h4l1 1 1 1v-4h-5l-1-2h4v-1l1-1-1-2-2-2v3l-2-2H97l-2 3h-2l2-3 3-2h16l2 2 2 3h4l11-11h37l3 3 4 4-1 38-5 5v5l-5 6-5 7h-29v-2Z"/><path fill="';
    string private constant PART_10 =
        '" d="M145 103h2l2 1h-5l1-1Zm-6 10h2v1h-3l1-1Zm-28 0h1v1h-1v-1Zm5 0-1-2h-10l-7-1-4 4h-1l2-3 3-2h17l2 3 2 3h-1l-2-2Zm-3 1h1v1h-1v-1Zm47 0v-3l1-3h3-2l-1 1v6h6l-5-2h4v-3l-1-2h2l-1-2v-2h-9l-8-1h21l7 8v2h-1l-1 1 1-2-4-4-4-4h-1v1l1 2 1 2-2-1v8h-6l-1-2Zm-21 1h3v-6l-5-1h6v7l-6 1 2-1Zm31 2h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-5 0h2v1h-3l1-1Zm-4 0h1v1h-1v-1Zm-21 0h1v1h-1v-1Zm-6 0h2v1h-3l1-1Zm-9 2v-1h1l-1 2h-1l1-1Zm-13 0v-1l1-1h1l-1 1v2h-1v-1Zm3 2v-1h1l-1 2h-1l1-1Zm-7 0h-3l-1-1-1-1 4 1h4v2-1h-3Zm-15 0h1v1h-1v-1Zm72 3h2v1h-3l1-1Zm-34 0h1v1h-1v-1Zm20 1h-7v-2h16v2h-9Zm-10-1 2-1v2l-1 1h-2l1-2Zm-2 3h1v1h-1v-1Zm-46-1 2-2-1-1 3 1v1l-3 1-2 2 1-2Zm15 2h1v1h-1v-1Zm61 2h1v1h-1v-1Zm-2 1h1v1h-1v-1Zm-31 0 1-2h1l-3 4h-1l2-2Zm-48 1v-1l3-4v2l-3 4v-1Zm77 2v-1h1l-1 2h-1l1-1Zm-68 1h1v1h-1v-1Zm66 1h1v1h-1v-1Zm-34 1h1v1h-1v-1Zm-17 0h1v1h-1v-1Zm15 2h1v1h-1v-1Zm-31-1-2-1v-2l1-3v6h5l-2 1-1 1-1-2Zm63 2h1v1h-1v-1Zm-15 2h1v1h-1v-1Zm13 1v-1h1l-1 2h-1l1-1Zm-49 0h1v1h-1v-1Zm20 1h1v1h-1v-1Zm14 1v-1h1l-1 2h-1l1-1Zm29 1h1v1h-1v-1Zm-59-13h-1v1h1v-1Zm-20 11-4-3v-3l3 4 3 3h8l4-4v-3h-1l-5 4h-5l-4-4v-5l2-2 2-2h4l4 2v2h-3v-3h-4l-1 2-2 1v5l2 1 1 2h4l3-2-3-2h8v-2h-9l-1-2h5l4 1v-2l-1-1v-1l-4-3-3-2h3l3 3h2l1 4 2 4 1 3h3v-7l-1 2v1h-3l1-3h4v7l-5 1v-2h-1l-1 1 1 2-2 2-2 2h-2l-2 2h-6l-3-3Zm58 6h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-18 0v-1l1-1h1l-1 1v2h-1v-1Zm-10-3-1-1h-2l1 2h2v-1Zm-7 7v-1h-4l3 2h1v-1Zm-6 0v-1h-2v2h1l1-1Zm-3 0v-1h-2v2h2v-1Zm-3 0v-1h-2v2h2v-1Zm-3 0v-1h-2v2h2v-1Zm24 1v-2h-8v2h4v2l4-1v-1Zm-16 1h-9 13-4Zm61 1v-2h-3v4h3v-2Zm-10 0v-2l1 2v1l-1 1v-2Zm-7 0v-2l1 2v1l-1 1v-2Zm9 2 1-1 1 1v1h-2v-1Zm-7 0 2-1h1v2h-3v-1Zm-3 3h1v1h-1v-1Zm-14 0v-2l1 1v1l-1 1v-1Zm2 1v-1l2 1v1h-2v-1Zm2 2h1v1h-1v-1Zm32-2 4-4v-3l-1-1h-1l-1 2-1 2v-4h-3v4l-3 3h4v-2h2l-1 2-2 2-4-2 1-1v-1l-1-1h-1v-4h-23v4l2 3h5v-1l-1-1h-2l-1 1v-2h4l1 3-1 1h-4l-2-2-2-2v-4h-7v3l-1-1h-1l1-1v-1h-4v2l-1-2-2-2v2l-1 2 1 2h4l5 2v-1l-1-1h2v3l2 2 2 3h30l3-4Zm-33 6v-2l-6-5h-10l-5-6h-7v2H90l-1-2h-6v-2h1l2 1 1-1v-1h-6v-33l4-3 3-4 1 2-4 2v3l-3 1 1 12v19h16l15-1 1-1v-1h-5l-2 2 1-2 2-2-2-2-2-1h7v-16h-2v-5h2l3-2 2-3-1-1 5-1-3-2h2l11-11h11l-7 1-5 1v2l-3 2-2 3h-2v3l1 3h-2l-1-3-3 3-3 4h1l1 1h-2l-1-1-1 12v12l3 3 3 3h12l1-2 1-1h-4l-4-1h40v1h-31l-1 1-1 2h36l2-3 3-3v-16h-7l1-2 3 1h3v-10l-1-1h-2l1-4-2-3-1-2 2 2 2 2v3l3-2-2 2-1 2 1-1h2l-1 16v16l-5 4v5l-4 5-5 5h-26l-1 1h-1l28 1-30 1v-2Z"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(27, 47%, 55%)";
    string private constant COLOR_3 = "hsl(215, 4%, 43%)";
    string private constant COLOR_4 = "hsl(55, 6%, 43%)";
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
