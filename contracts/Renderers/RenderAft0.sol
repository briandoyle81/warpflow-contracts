// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderAft0 {
    string private constant PART_1 =
        '<g id="Image_3_Image"><path d="M193 114h-1v1h1v-1Zm-10 39h-1v1h1v-1Zm46 0-1-1v3l1-1h1l-1-1Zm-45 19v-1h-7l-1-1-2-1-2-2-2-1v-7l-1-8 3-3 3-3v-32l-1-1h-8v-5h12v-3h4l3-4h3v-4h5l1 4h2l1-4h8v4h3l1 2v2l3-1h3l6-1h6l4 4 1 2v2h10v2h5v10l2 3 1 2-3 2v7l-1 1-2 2h-2v2h-6l-6 2v2h-4v2h9v18h-3l-8 3h-9v1l-1 2h-6l-1 2h-4v-3l-2 3h-3l-1-2-2 1-2 1-3-2-1 1-1 1h-4v-1Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="M203 103v-1h-14l14 1v1-1Zm25 4v-1h-4v2h4v-1Zm-6 0v-1h-1l-2 1v-2h-1v3h4v-1Zm20 7-1-1h-2l-3 1 1-1v-1h-3l3 3h5v-1Zm-11 0-1-1v1l-1 1h3l-1-1Zm-6 0h-11 15-4Zm-13 0h-2l-1 1h4l-1-1Zm-1 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm37 0-2-2v2l1 1 1 1v-1h1l-1-1Zm-28 1h-1v1h1v-1Zm24 4-1-1h-1v1l-1 1h3v-1Zm-31 0h-1v1h1v-1Zm-13 2-1-1v1l-1 1h3l-1-1Zm14 1h-1v1h1v-1Zm-17-4v-1l-4 4v2l4-5Zm10 6h-1v1h1v-1Zm-12 2h-1v1h1v-1Zm12 1h-1v1h1v-1Zm-6 0v-1h-1l-2 1v1h2l1-1Zm12 2h-1v1h1v-1Zm8 2h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm33 1h-1v1h1v-1Zm-13 0v-1h-2l1 2h1v-1Zm-22 0h-1v1h1v-1Zm-6-6v-6l3-3 2-2v-2l20-1h-19l-2 1-2 2v3l-4 1v14h1v-1l1-6Zm44 7-1-1-1 1v1h2v-1Zm-5 1h-1v1h1v-1Zm4 2-1-1v1l-1 1h3l-1-1Zm0 2-1-1v1l-1 1h3l-1-1Zm-13 12-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0-2-1v2h2v-1Zm-32 0v-1h-1l-1 2h1l1-1Zm47-1-1-2v5l1-1v-2Zm-34 2h-1v1h1v-1Zm40 0-1-1v3l1-1h1l-1-1Zm-44 1v-1h-3l3 2v-1Zm40 1h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm-10-2h1v1h-1v-1Zm-1 2v-1h1l1 1 1-1v-1l-1-1-2 2-2 2h2v-1Zm21-2h6v-1l-1-1h-10l-2 2v4l1 3v-3l1-4h5Zm-15 19v-1h-7l-3-3h-2l-1-2-2-1v-14l6-6v-32l-1-1h-8v-5h12v-3h5l1-4h4v-3h5v3h3l1-4h8v4h3l1 2v2l9-1 8-1 3 2 2 1 1 2v3h10v2h5v7l1 6v6l-1 6-2 1-3 1v2h-6l-6 2v2h-4v1l3 2 2 1 1-2h2v17l-5 2-6 2h-8v1l-1 2h-5l-1 1-2 1-2-1-2-1-1 2h-4v-2l-2 1-3 1-1-1-2-2-1 3h-4v-1Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="M203 103v-1h-14l14 1v1-1Zm25 4v-1h-4v2h4v-1Zm-6 0v-1h-1l-2 1v-2h-1v3h4v-1Zm-10 1h-1v1h1v-1Zm-3-1-1-1v3l1-1h1l-1-1Zm-3 1v-1h-4v2h3l1-1Zm-5 0v-1h-6v2h6v-1Zm-7 0v-1h-5v2h4l1-1Zm-6 0v-1h-2v2h2v-1Zm-3 0v-1h-4v2h4v-1Zm57 6-1-1h-2l-3 1 1-1v-1h-3l3 3h5v-1Zm-11 0-1-1v1l-1 1h3l-1-1Zm-6 0h-11 15-4Zm-13 0h-2l-1 1h4l-1-1Zm-1 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm37 0-2-2v2l1 1 1 1v-1h1l-1-1Zm-28 1h-1v1h1v-1Zm24 4-1-1h-1v1l-1 1h3v-1Zm-31 0h-1v1h1v-1Zm-13 2-1-1v1l-1 1h3l-1-1Zm14 1h-1v1h1v-1Zm-17-4v-1l-4 4v2l4-5Zm46 5h-1v1h1v-1Zm-36 1h-1v1h1v-1Zm-12 2h-1v1h1v-1Zm12 1h-1v1h1v-1Zm-6 0v-1h-1l-2 1v1h2l1-1Zm12 2h-1v1h1v-1Zm8 2h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm33 1h-1v1h1v-1Zm-13 0v-1h-2l1 2h1v-1Zm-22 0h-1v1h1v-1Zm-6-6v-6l3-3 2-2v-2l20-1h-19l-2 1-2 2v3l-4 1v14h1v-1l1-6Zm44 7-1-1-1 1v1h2v-1Zm-5 1h-1v1h1v-1Zm4 2-1-1v1l-1 1h3l-1-1Zm0 2-1-1v1l-1 1h3l-1-1Zm-13 12-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0-2-1v2h2v-1Zm-32 0v-1h-1l-1 2h1l1-1Zm47-1-1-2v5l1-1v-2Zm-34 2h-1v1h1v-1Zm0 2h-1v1h1v-1Zm-4-1v-1h-3l3 2h-2l-2 1 2-1h2v-1Zm-6-1h1v1h-1v-1Zm-1 2v-1h1l1 1 1-1v-1l-1-1-2 2-2 2h2v-1Zm53 0v-2l-5-2-1 2v2l2 2 2 1 2-1v-2Zm-32-2h6v-1l-1-1h-10l-2 2v4l1 3v-3l1-4h5Zm-15 19v-1h-7l-3-3h-2l-1-2-2-1v-14l6-6v-32l-1-1h-8v-5h12v-3h5l1-4h4v-3h5v3h3l1-4h8v4h3l1 2v2l9-1 8-1 3 2 2 1 1 2v3h10v2h5v7l1 6v6l-1 6-2 1-3 1v2h-6l-6 2v2h-4v1l3 2 2 1 1-2h2v17l-5 2-6 2h-8v1l-1 2h-5l-1 1-2 1-2-1-2-1-1 2h-4v-2l-2 1-3 1-1-1-2-2-1 3h-4v-1Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="M203 103v-1h-14l14 1v1-1Zm25 4v-1h-4v2h4v-1Zm-6 0v-1h-1l-2 1v-2h-1v3h4v-1Zm-10 3 1-2 1-1h-6l1 4h3v-1Zm-14 1h8v-4h-20l1 1v4l3-1h8Zm-15 1v-2l1 2 1 1h1l1-1-1-3-1-2h-5l1 5v1h2v-1Zm59 2-1-1h-2l-3 1 1-1v-1h-3l3 3h5v-1Zm-11 0-1-1v1l-1 1h3l-1-1Zm-6 0h-11 15-4Zm-13 0h-2l-1 1h4l-1-1Zm-1 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm37 0-2-2v2l1 1 1 1v-1h1l-1-1Zm-28 1h-1v1h1v-1Zm24 4-1-1h-1v1l-1 1h3v-1Zm-31 0h-1v1h1v-1Zm-13 2-1-1v1l-1 1h3l-1-1Zm14 1h-1v1h1v-1Zm-17-4v-1l-4 4v2l4-5Zm48 4h-2l-2 1 1 1 2 1 2-2-1-1Zm-38 2h-1v1h1v-1Zm-12 2h-1v1h1v-1Zm12 1h-1v1h1v-1Zm-6 0v-1h-1l-2 1v1h2l1-1Zm12 2h-1v1h1v-1Zm8 2h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm33 1h-1v1h1v-1Zm-13 0v-1h-2l1 2h1v-1Zm-22 0h-1v1h1v-1Zm-6-6v-6l3-3 2-2v-2l20-1h-19l-2 1-2 2v3l-4 1v14h1v-1l1-6Zm44 7-1-1-1 1v1h2v-1Zm-5 1h-1v1h1v-1Zm4 2-1-1v1l-1 1h3l-1-1Zm0 2-1-1v1l-1 1h3l-1-1Zm-13 12-1-1v1l-1 1h3l-1-1Zm-3 0-1-1v1l-1 1h3l-1-1Zm-3 0-2-1v2h2v-1Zm-32 0v-1h-1l-1 2h1l1-1Zm47-1-1-2v5l1-1v-2Zm-34 2h-1v1h1v-1Zm0 2h-1v1h1v-1Zm-4-1v-1h-3l3 2h-2l-2 1 2-1h2v-1Zm-6-1h1v1h-1v-1Zm-1 2v-1h1l1 1 1-1v-1l-1-1-2 2-2 2h2v-1Zm21-2h6v-1l-1-1h-10l-2 2v4l1 3v-3l1-4h5Zm-15 6h-2l-1 1h4l-1-1Zm46 2 1 1v-10l-5-3h-1v8l2 7v-1l1-2h2Zm-46 11v-1h-7l-3-3h-2l-1-2-2-1v-14l6-6v-32l-1-1h-8v-5h12v-3h5l1-4h4v-3h5v3h3l1-4h8v4h3l1 2v2l9-1 8-1 3 2 2 1 1 2v3h10v2h5v7l1 6v6l-1 6-2 1-3 1v2h-6l-6 2v2h-4v1l3 2 2 1 1-2h2v17l-5 2-6 2h-8v1l-1 2h-5l-1 1-2 1-2-1-2-1-1 2h-4v-2l-2 1-3 1-1-1-2-2-1 3h-4v-1Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="m201 97-1-1v1l-1 1h3l-1-1Zm-9 2v-1h-3v2h2l1-1Zm12 4v-1h-19v2l1-1 3 1 3 1h11l1-2Zm25 4-1-2h-4v3h5v-2Zm-6-1v-1h-6v3h6v-2Zm-55 3h-1v1h1v-1Zm44 1 1-2 1-1h-6l1 4h3v-1Zm-29 2v-2l1 2v1h2v-4l1 2 1 1 1-1h17v-4h-20v2-1l-1-1h-5l1 5v1h2v-1Zm-6 0h-1v1h1v-1Zm55 3v-1h-3v3h3v-2Zm-48 1h-1v1h1v-1Zm-7-1-1-1v3l1-1h1l-1-1Zm68 1v-1h-2l-3-3h-6v4h2l1 1v-1l-1-1h3l3 1 3 2v-2Zm-10 1h-1v1h1v-1Zm-19 0-1-1h-1v3h2v-2Zm-37 4-1-1v1l-1 1h3l-1-1Zm58 1v-3l-1 2-2 2 1 1v1l1-1h1v-2Zm-9 1-1-2v4h1l1-1-1-1Zm-4-7v-1l1 1 1 1h-3l1-1Zm-5 1v-1h1l-1 2h-1l1-1Zm2 0 1-1v3h-2l1-2Zm5 2v-2l1 1 1 1h-1l-1 1v-1Zm1 2 1-2v-5h-14l2 2 1 3-1 1-2 2v3l1-1 1-1 2 2h6l2-2 1-2Zm17 3h1l-2-2-2-2h-3v6l3 1 3-3Zm-24 2h-1v1h1v-1Zm8 1h-1v1h1v-1Zm-10 2-1-1h-1v1h-1 3Zm-40 2h-1v1h1v-1Zm54-2v-11h-2l-1 18 2 4h1v-11Zm-37-14h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm20 6h1v1h-1v-1Zm0 4h1v1h-1v-1Zm-17 2h1v1h-1v-1Zm-5 2 1-2h-3l-1 2-1 1v-9l2-1h2v1l1 1 3-3h4l4-4h5l1 1 1 1v3l-1 3h-2v-4l-5 1 3-2h-2l-4 3v1l2-1v4-1l-1-1h-3l1 1 1 1h-1l-1 1-1-1h-2l2-2 3-2-1-1-1-1-4 5 3 3-1-1h-2v1l-1 1h2v3h-2l-1-1v-1Zm0 4h1v1h-1v-1Zm17 1h-1v1h1v-1Zm-2 1v-1h-7v2l4 1h3v-2Zm-2 3h-6v-7l6-6h2l1-1 1 1 1 1-2-1h-1l-6 6 5 1h5v7-1h-6Zm-9-2v-3h-2l4-3h1l-1 2-1 2 1 3v3l14-1v-12l3 4v2l-2-3v10h3v-21h-1l-1 1 1-1 1-2v-3h-3v7l1 1 1 1-1 2-2 1v-12h-18l-4 3-4 3v15l3-4v4l3 2 3 3 1-1v-3Zm32-3-1-2 2 2 1 1v1l-2-2Zm-3 2v-1h2l1 2h-3v-1Zm5 4-2-1h1l2 1v-1l1-2v-7l-2-1-2 1-1 1h2l-3 2h-2l1-2 1-1h-3l1 1v1l-2 1-3 1v6l3-1v1l-1 1h4v-3h2v1l-1 1 2 1 2 1h2l-2-2Zm-23 8h-1v1h1v-1Zm-24 0h-1v1h1v-1Zm14 2h-1v1h1v-1Zm24 2-1-1v3l1-1h1l-1-1Zm-38 4 1 1v-2l-1-1-1 1-2 1 1 1 1 1v-2h1Zm44-2v-6l-1 4-2-1h-2v3h2l1 1 1-2v-1 7h1v-5Zm-15 1v-4h-3l1 3v2l1 2v1h1v-4Zm6 1v-4l-1-1h-1v10h2v-5Zm-39-3h1v1h-1v-1Zm8 7h-2v-2l3 1 2-2 1-3v-1h-7l-5-2-1 2-1 2 2 2 4-4 1 1v1h4l1 1v1l-2-1h-1l-1 1-1 2 1 2h4l-2-1Zm18-4h1v1h-1v-1Zm-1 2h5v-6h-12v4l-1 3 1 2 1 1v-4h6Zm11-1v-6h-2l1 13h1v-7Zm-22-1v-4 12-8Zm41 6 1 1 1-4v-5l-5-4h-1l-1 4v5l1 3v3l1-1 1-2h2Zm-17 2-1-2v5l1-1v-2Zm-2 1-1-1v3l1-1h1l-1-1Zm-3 1h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm-2 1v-1l-1-1-1 1v1h2Zm-8 0h-1v1h1v-1Zm-2 0-1-1v1l-1 1h3l-1-1Zm4 6v-1h-7l-3-3h-2l-1-2-2-1v-14l6-6v-32l-1-1h-8v-5h12v-3h5l1-4h4v-3h5v3h3l1-4h8v4h3l1 2v2l9-1 8-1 3 2 2 1 1 2v3h10v2h5v7l1 6v6l-1 6-2 1-3 1v2h-7l-2 1-2 1-1 2h-5l3 2 3 2v-2h3v17l-5 2-6 2h-8v1l-1 2h-5l-1 1-1 1-5-2v1l-1 1h-4v-3l-3 2-2 1-3-3-1 3h-4v-1Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M237 115h1v1h-1v-1Zm-62 0h1v1h-1v-1Zm29-17-1-1h-4v1l-1 1 3 1h3v-2Zm22 11v-2l1 1 1 1h-1l-1 1v-1Zm4 0v-2h-2l1-3h-5v5l1 1 1 1h4v-2Zm-7-1 1-2-1-1-3-1h-4v7h6l1-3Zm-45 2-1-1h-10v1l6 1h5v-1Zm-1 2h-1v1h1v-1Zm8 3h1-4l1-2 1-1v1l1 1 1-2 1-2v2l6-2v2l4-1h16l1-2v-3l-14 1h-20v10l2-1h2l1-1Zm-5 6-2-2-2 3h5l-1-1Zm61 7h-1v1h1v-1Zm-61 4v-1h-4v2h3l1-1Zm57 2v-1l-1-1h-2v3h2l1 1v-2Zm6 0h1v1h-1v-1Zm-2 2 2-1h2v-3h-3l-1 4-1-2-2-2v6h2l1-2Zm-4 1h-1v1h1v-1Zm-5-10v-13h-3v26h2v1l-1 1 1-1h1v-14Zm-6-4 1-1v3h-2l1-2Zm-9 3-1-3 3 4h6l-3 1h-4l-1-2Zm-1 3h1v1h-1v-1Zm-1 11h1v1h-1v-1Zm11 1h2v-27h-14v28h6l5-1h1Zm-18-18v-5l1-3v9l-1-1Zm-11 0h1v1h-1v-1Zm-4 1v-2l1 2 1 1-1 1h-1v-2Zm-5 2v-4l2-1 1-1 6-1 1-2v-1h8v7l-1-6h-4l-3 2-2 1h-2l-2 2-3 1v7l-1-4Zm2 4h1v1h-1v-1Zm2 4v-2h1v4l-1-2Zm13 0h-1v1h1v-1Zm0 2h-1v1h1v-1Zm-10 0v-2l1 2v1h7v-3h-7l-1-2-1-2h1l1 1 2-2 3-3-4 4v2h10v6h-12v-2Zm-3 1h1v1h-1v-1Zm14 3h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm-3 1-1-1h2l1 1v1h9v-6l2 4v1h-1 3v-27h-23l-3 3-4 3v14l8 7 2-1 3-1-1 2-1 1h4v-1Zm24 7h-3l-1 1h5l-1-1Zm-34 2h3v-3h-12l1 2 3 2h2l3-1Zm36 4v-7 2l-1 1h-4v2l-2-3v4h2v4h2l1 1v-1l-1-1 2-3v8h1v-7Zm8 8 1-3v-3h1l-2-5-2-1-1-2h-2l-2 6 1 5 1 5 2-1h3v-1Zm-26-5v-6h-12v6l-1 6 6-1 5-1 1-2v2l-2 3h1l2-1v-6Zm-4 6h-1v1h1v-1Zm-19-5v-1h1l1 1h-3 1Zm4 5v-1h2l1 1v-11h-9l-2 1-1 2v6h1l1-1v-2l1-2 2-2h2l4 4-1 3h-1l-1-1v-5h-4l-1 4h2l2 1v1l-1 1 1-1h1v2h-1l-2 1h4v-1Zm-5-1-1-2-2 1v2h3v-1Zm1 4v-1h-4l-1-2-2-1v-7l2-2 3-2h-3v-5l-2 3-2 4v8l4 6v-1l2 1 2 1h1v-2Zm17 2h-1v1h1v-1Zm-7-20h1v1h-1v-1Zm19 6v-2l1 2 1 1-1 1h-1v-2Zm-20 13-1-1 4 1h14v-14h1v-1 15h2l1-5v-6 11h2v-17l1-2 1-1h-2l-1 2-2 2v-4h-2v5l-1-6-8 1h-8v1l-1 2h14l1 1v12l-2 3h-9l-3-2h-4l-4 1v1h-1l3 1h3v2l2-1v-1Zm8 3h-1v1h1v-1Zm-14 2-1-1h-7l-3-3h-1l-1-1-3-2v-14l6-6v-28h2l1-2v-1h-1l-1 1-1-2-2-1h-7v-5h12v-3h5v-2h2l-1 2h3l2 1h14l2-1h1v-2h-18l-3-2h3l1-2v-2 4h3l1-2v-2 4h3l1-4h8v4h3l1 4 19-1 2 1 1 2 1 2v2h10v2h-9l1 1v6h5l-5 1v9h2l2-5 1 4 2-1 3 2h-2l-2 1-1-1-1-2v1l-1 1-2 1-1 1 4-1 2 2 1 2 1-3 2-2 1-2v-3l-5-5h2l2 2 1 2v-8l-4-2 2-1h3l1 1 1 7v12l-1 5h-2l-4 4h-6l-2 1-2 1-1 2h-5l3 2 3 2 1-1 1-1h1v17l-5 2-6 2h-8v1l-1 2h-5l-1 1-2 1-3-3-1 2-1 1h-4v-3l-2 2-2 1-2-1-2-2-1 3h-3v-1Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="m185 100 4-1v2h-4v-1Zm6 1v-1l2-4v4h3v-2l1-1 2 2 1 3h-4l-5-1Zm7 4h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm-15 8-2-1h-7v-5h12v-3h5v-2h2l-1 2h3v2h-8l1 9h-2v-6h-11v2h8l2 4h-1l-1-2Zm0 8h1v1h-1v-1Zm3 1h1v1h-1v-1Zm-1 28v-2l1 1 1 1h-1l-1 1v-1Zm6 1h1v1h-1v-1Zm-2 0-1-2 1 1 1 1v1h-1v-1Zm51-2h-1v1h1v-1Zm0 3-1-3 2-2h1v8h-1l-1-3Zm-48 3-1-2 1 1 1 1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-1 3h1v1h-1v-1Zm6 1 1-1 1-1v-2 5h-3l1-1Zm-4 2v-1h1v2h-2l1-1Zm-5-2v-4 7-3Zm35 4h1v1h-1v-1Zm-12 1h6v-13h-12l-1 12h-3v-11h-2v-2h18l1 4v10h-13 6Zm-17 0h3l3-1v1l-1 1h-5v-1Zm-4 0-1-1h2l2 1v1h-3v-1Zm-7 2-2-1v-13l2-1 2 3v10l1 1 1 2h-3l-1-1Zm52-57 1-2v4h6v-5l-2-2h-12v7h7v-2Zm-44 16-1-1v1l-1 1h3l-1-1Zm68 0-1-2v4h1l1-1-1-1Zm-68 3v-1h-2v2h2v-1Zm1 4v-1h-4v3h4v-2Zm3 5h-2l-1 1h4l-1-1Zm53-18h1v1h-1v-1Zm6 9h1v1h-1v-1Zm-3 0-1-2 1 2 2 1h-1v1l-1-2Zm-2 7 1-4v5l1 2v1l4-2 3-2v-1l-1-2v-18l-6-3-2 1h-3v24l1 3h2v-4Zm-58 2v-1h-2v3h1l1-2Zm49-20v-2l1 2 1 1-1 1h-1v-2Zm0 5v-2l1 1 1 1h-1l-1 1v-1Zm-2 0h1v1h-1v-1Zm2 2h1v1h-1v-1Zm-2 0v-1l1 1 1 1h-3l1-1Zm-9 1-1-2 1 1 1 1v1h-1v-1Zm3 2h3l1 1h-6l2-1Zm9 7v-8 16h3v-29h-17l-1 29h14l1-8Zm-36-11h1v1h-1v-1Zm0 2h1v1h-1v-1Zm-5 2h1v1h-1v-1Zm8 3h1v1h-1v-1Zm6 7h3v-3h-10v-2l6 1h5v5l-7-1h3Zm-6 0h2l1 1h-4l1-1Zm6 5h10v-28l-2-1h-20l-4 3-4 4v14l4 4 4 5 2-1h10Zm-21 0v-1h2v1l-1 1h2v-3h-7v3h2l1 1h2l-1-2Zm36 18h1v1h-1v-1Zm3 4h-3v-2l4 1v-2l1-2 1 6v-18h-6v19l3-1 2-1h-2Zm-26 6h-2l-1 1h4l-1-1Zm-9 2-1-1h-7l-1-2-2-1 2-1h2v2h30l1-2v-2 4h5v-8l1-8v-7h-6v3l-1-1v-2h-32l-2 6h-1l-2-3 2-2 2-2v-22l5 1v-1l1-2v-1h-6l1-3h7l3-2h-3l2-2 2-1 13-1h14v-5h-10l3-3v-2h-3l1-4-7-1h7v4h3l1 4 19-1 2 1 1 2 1 2v2h10v2h4l1 1v1l1 15v-1h-1v4l1 5h-3l-4 4h-5l-6 2v2h-5v2h3l1 1v1l-1-1-2-1-1 2-1 1v12l1 2 1 1 3-2 3-1v-6h2v8l-5 2-6 2h-8v1l-1 1-5 1-4 1 2-2h-9l2 1h1v2h-2l-1-1-1-1-2 1-2 1-3-2-3-1h-1l-1 1h3v1h-3Z" style="fill:';
    string private constant PART_8 = ';"/></g>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(27, 30%, 50%)";
    string private constant COLOR_3 = "hsl(18, 40%, 39%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(223, 6%, 24%)";
    string private constant COLOR_6 = "hsl(213, 10%, 18%)";
    string private constant COLOR_7 = "hsl(223, 10%, 13%)";

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
