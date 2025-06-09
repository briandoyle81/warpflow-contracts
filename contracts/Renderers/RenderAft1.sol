// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderAft1 {
    string private constant PART_1 =
        '<g id="Image_4_Image"><path d="M227 108h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm-16 0h-2l-1 1h5l-2-1Zm-8 0h-2l-1 1h3v-1Zm-9 0h-1v1h1v-1Zm-3 0-1-1-1 1v1h2v-1Zm-7 0h-1v1h1v-1Zm2 9h-1v1h1v-1Zm7 40h-1v1h1v-1Zm-14 21-1-1-2 1v-2h-3l-3-4-3-3v-2h-7v-11l7-7v-7l-3-2v-9l3-3 3-2v-8h5v-12h2v-4h5v-2h5l-2-2 1-1 1-1h5l1 4h3l1-4h9l2 1 1 2v2h2l1-4h5l1 3 1 2h16l3 3 2 4v4h9l4 1 4 2 1 2 1 2v9l-2 2-1 2h-5v3h5l3 2v9l-2 5-6 1v3h5l3 2v6l-1 6-1 1-1 2h-6l-1 2h-10v-3l-1 2-1 1-3 1-4 1h-15l-2 3h-5l-3-3v3h-5l-3-3-1 2v1h-5l-3-3-2 3h-6l-1-2Z" style="fill:';
    string private constant PART_2 =
        ';"/><path d="m194 98-1-1-1 1v1h2v-1Zm-11 0-1-1-1 1v1h2v-1Zm21 7h-1v1h1v-1Zm-17 0-1-1-1 1v1h2v-1Zm41 3h-2l-1 1h3v-1Zm-5 0h-6l4 1h4l-2-1Zm-19 0h-2l-1 1h5l-2-1Zm-4 0h-1v1h1v-1Zm-4 0h-2l-1 1h5l-2-1Zm-9 0h-1v1h1v-1Zm-2 0h-2l-1 1h3v-1Zm-8 0h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm45 2h-1v1h1v-1Zm7 2h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0v-1h-1l-1 2h2v-1Zm8 3h-2l-1 1h3v-1Zm-5 2-6-1 7-1h-10l1 1 1 1h-4 18-7Zm-12 0v-1h-5l-1 2h6v-1Zm-8-1-1-2v5l3-2-2-1Zm-7 3h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-3 0h-4l-1 1h7l-2-1Zm57 2h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-24 0h-1v1h1v-1Zm-38 0h-1v1h1v-1Zm59 1v-1l-2-1v3h2v-1Zm-47 0v-4l-1 2-1 3 1 3h1v-4Zm2 4h-1v1h1v-1Zm-12 2 1-1 7-2h-6l-5 4h2l1-1Zm-3 3v-1h-1l-1 2h1l1-1Zm-17 0v-1h-2v2h2v-1Zm22 3h-1v1h1v-1Zm-9-11h1v-1h-1l2-2 2-2h21v-2h-21l-4 3-3 3v7l1 6v-12h2Zm38 12h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm28 1h-1v1h1v-1Zm35 4h-1v1h1v-1Zm-45 0h-4l-1 1h7l-2-1Zm-19 1-1-2-1-4v4l3 3-1-1Zm70 1h-1v1h1v-1Zm-2-1-1-1v3l1-1v-1Zm-3 1h-1v1h1v-1Zm-26-3-1-2v6l1-1v-3Zm-32 3v-1h-2v2h1l1-1Zm45 0 2-1-3 1-2 1h-1v1h2l2-2Zm-49 1h-1v1h1v-1Zm2 2h-1v1h1v-1Zm35 1v-1h-2v2h1l1-1Zm-28 0v-1h-3l-1 2 3-1h1Zm19 11h-1v1h1v-1Zm-2 0v-1h-15l-1-1-1 2v1h17v-1Zm-24 0v-1h-6l-3-1-1 2v1h10v-1Zm44 2-1-1v3l1-1v-1Zm-40-1h2v-3l-2 1-2 1v-1l-1-1v6l1-1v-2h2Zm36 3-1-1h-2l1 1v1h2v-1Zm-37 1h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm72 1h-1v1h1v-1Zm-2-1-1-1v3l1-1v-1Zm-4 1h-1v1h1v-1Zm-17-4-1-2v7l1-1v-4Zm-40 10-1-1v3l1-1v-1Zm-10 9-1-1-2-1h-2l-7-7v-2h-7v-10l4-4 3-4v-7l-2-1v-11l3-2 2-2v-8h5v-8l1-3 1-4h5v-3h4l-1-2 1-1 1-1h5v4h4l1-4h9l1 2 1 3h3l1-4h6l1 7h3v-2l7 1h6l3 3 2 3v4h9l7 2 2 2v13l-2 3h-5v3h5l2 2v12l-2 3h-5v3h5l2 2v13l-2 1-2 1h-8l-8 1-3 2-10 1h-10l-1 1-1 2h-6v-1l-1-2-2 3h-4l-3-3-2 3h-4l-3-3-2 3h-6l-1-2Z" style="fill:';
    string private constant PART_3 =
        ';"/><path d="m194 98-1-1-1 1v1h2v-1Zm-11 0-1-1-1 1v1h2v-1Zm21 7h-1v1h1v-1Zm-17 0-1-1-1 1v1h2v-1Zm41 3h-2l-1 1h3v-1Zm-5 0h-6l4 1h4l-2-1Zm-12 0-1-1v3l1-1v-1Zm8 2h-1v1h1v-1Zm7 2h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0v-1h-1l-1 2h2v-1Zm-14-3h1v1h-1v-1Zm-3 1h2v2h-2l-1 1h6v-5h-8v5l2-3h1Zm-4 0v-2h-10 1l1 1v1l-1 1h3l2-1 2-1v4h2v-3Zm-7 2h-2l-1 1h5l-2-1Zm-6-1v-1h1v2h-2l1-1Zm-4 0v-1h2l-1 2h-2l1-1Zm6-1v-2h-8l-1 3v2h9v-3Zm-10 0v-2h-6v1l2 1 1 2 1-2 1-1v2l-1 2h2v-3Zm-5 1-1-1v3l1-1v-1Zm55 4h-2l-1 1h3v-1Zm-5 2-6-1 7-1h-10l1 1 1 1h-4 18-7Zm-12 0v-1h-5l-1 2h6v-1Zm-8-1-1-2v5l3-2-2-1Zm-7 3h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-3 0h-4l-1 1h7l-2-1Zm55 2h-1v1h1v-1Zm-24 0h-1v1h1v-1Zm-38 0h-1v1h1v-1Zm59 1v-1l-2-1v3h2v-1Zm9 1v-3h-3l-2-1 1 3v2l4 1v-2Zm-56-1v-4l-1 2-1 3 1 3h1v-4Zm2 4h-1v1h1v-1Zm-12 2 1-1 7-2h-6l-5 4h2l1-1Zm-3 3v-1h-1l-1 2h1l1-1Zm-17 0v-1h-2v2h2v-1Zm22 3h-1v1h1v-1Zm-9-11h1v-1h-1l2-2 2-2h21v-2h-21l-4 3-3 3v7l1 6v-12h2Zm38 12h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm28 1h-1v1h1v-1Zm35 4h-1v1h1v-1Zm-45 0h-4l-1 1h7l-2-1Zm-19 1-1-2-1-4v4l3 3-1-1Zm68 0-1-1v3l1-1v-1Zm-3 1h-1v1h1v-1Zm-26-3-1-2v6l1-1v-3Zm-32 3v-1h-2v2h1l1-1Zm45 0 2-1-3 1-2 1h-1v1h2l2-2Zm-49 1h-1v1h1v-1Zm2 2h-1v1h1v-1Zm67-3h1v1h-1v-1Zm0 3 2-2v-2l-2-1-3-1v8h1l2-2Zm-32 1v-1h-2v2h1l1-1Zm-28 0v-1h-3l-1 2 3-1h1Zm19 11h-1v1h1v-1Zm-2 0v-1h-15l-1-1-1 2v1h17v-1Zm-24 0v-1h-6l-3-1-1 2v1h10v-1Zm44 2-1-1v3l1-1v-1Zm-40-1h2v-3l-2 1-2 1v-1l-1-1v6l1-1v-2h2Zm36 3-1-1h-2l1 1v1h2v-1Zm-37 1h-1v1h1v-1Zm-10 0h-1v1h1v-1Zm70 0-1-1v3l1-1v-1Zm-4 1h-1v1h1v-1Zm-17-4-1-2v7l1-1v-4Zm-45 4v-1h-1l-1 2h1l1-1Zm52-2-1-1h-3l1 3v2l2-1 1-2v-1Zm20 2v-2l-5-1v4l1 1v1l2-1h2v-2Zm-67 6-1-1v3l1-1v-1Zm-10 9-1-1-2-1h-2l-7-7v-2h-7v-10l4-4 3-4v-7l-2-1v-11l3-2 2-2v-8h5v-8l1-3 1-4h5v-3h4l-1-2 1-1 1-1h5v4h4l1-4h9l1 2 1 3h3l1-4h6l1 7h3v-2l7 1h6l3 3 2 3v4h9l7 2 2 2v13l-2 3h-5v3h5l2 2v12l-2 3h-5v3h5l2 2v13l-2 1-2 1h-8l-8 1-3 2-10 1h-10l-1 1-1 2h-6v-1l-1-2-2 3h-4l-3-3-2 3h-4l-3-3-2 3h-6l-1-2Z" style="fill:';
    string private constant PART_4 =
        ';"/><path d="m194 98-1-1-1 1v1h2v-1Zm-11 0-1-1-1 1v1h2v-1Zm21 7h-1v1h1v-1Zm-17 0-1-1-1 1v1h2v-1Zm36 3h-6l4 1h4l-2-1Zm5 1v-1h-3l1 2h1l1-1Zm-9 1h-1v1h1v-1Zm7 2h-1v1h1v-1Zm-2 0-1-1-1 1v1h2v-1Zm-3 0v-1h-1l-1 2h2v-1Zm-10-3-1-2v6l1-1v-3Zm-2 1v-2h-6l-1-1-1 6h8v-3Zm-9 0v-2l-5-1-5 1v5h10v-3Zm-11 0v-2h-9v5h9v-3Zm-10 0v-2h-2l-3-1-1 1v5h6v-3Zm50 5h-2l-1 1h3v-1Zm-5 2-6-1 7-1h-10l1 1 1 1h-4 18-7Zm-12 0v-1h-5l-1 2h6v-1Zm-8-1-1-2v5l3-2-2-1Zm-7 3h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm-3 0h-4l-1 1h7l-2-1Zm31 2h-1v1h1v-1Zm-38 0h-1v1h1v-1Zm62 0-1-1v3l1-1v-1Zm-3 1v-1l-2-1v3h2v-1Zm-47 0v-4l-1 2-1 3 1 3h1v-4Zm2 4h-1v1h1v-1Zm54 0 1-2-1-2v-3l-2-1h-2v1h-1v7l1 1 2 1h2v-2Zm-66 2 1-1 7-2h-6l-5 4h2l1-1Zm-3 3v-1h-1l-1 2h1l1-1Zm-17 0v-1h-2v2h2v-1Zm27 2v-1h-2v2h2v-1Zm-5 1h-1v1h1v-1Zm-9-11h1v-1h-1l2-2 2-2h21v-2h-10l-5-1h-5l-4 4-4 3v7l1 6v-12h2Zm38 12h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm28 1h-1v1h1v-1Zm35 4h-1v1h1v-1Zm-45 0h-4l-1 1h7l-2-1Zm-19 1-1-2-1-4v4l3 3-1-1Zm68 0-1-2v4l1-1v-1Zm-3 1-1-1-1 1v1h2v-1Zm-26-3-1-2v6l1-1v-3Zm-32 3v-1h-2v2h1l1-1Zm45 0 2-1-3 1-2 1h-1v1h2l2-2Zm-49 1h-1v1h1v-1Zm2 2h-1v1h1v-1Zm35 1v-1h-2v2h1l1-1Zm-28 0v-1h-3l-1 2 3-1h1Zm62-2v-2l-1-2-1-1h-3v9l5-1v-3Zm-43 13h-1v1h1v-1Zm-2 0v-1h-16v-1l-1 3h17v-1Zm-24 0v-1h-6l-3-1-1 2v1h10v-1Zm44 2-1-1v3l1-1v-1Zm-40-1h2v-3l-2 1h-3v5l1-1v-2h2Zm36 3-1-1h-2l1 1v1h2v-1Zm-37 1h-1v1h1v-1Zm-9 0v-1h-1l-1 2h1l1-1Zm65 1h-1v1h1v-1Zm-17-4-1-2v7l1-1v-4Zm-45 4v-1h-2v2h1l1-1Zm66 0-1-2v4l1-1v-1Zm-14 0v-3h-4v2l1 3v2l2-1h1v-3Zm20 1v-4h-2l-1-1h-2v7l1 1v1h4v-4Zm-67 5-1-1v3l1-1v-1Zm-10 9-1-1-2-1h-2l-7-7v-2h-7v-10l4-4 3-4v-7l-2-1v-11l3-2 2-2v-8h5v-8l1-3 1-4h5v-3h4l-1-2 1-1 1-1h5v4h4l1-4h9l1 2 1 3h3l1-4h6l1 7h3v-2l7 1h6l3 3 2 3v4h9l7 2 2 2v13l-2 3h-5v3h5l2 2v12l-2 3h-5v3h5l2 2v13l-2 1-2 1h-8l-8 1-3 2-10 1h-10l-1 1-1 2h-6v-1l-1-2-2 3h-4l-3-3-2 3h-4l-3-3-2 3h-6l-1-2Z" style="fill:';
    string private constant PART_5 =
        ';"/><path d="M195 98h-2l-1 1h3v-1Zm-12 0-1-1-1 1v1h2v-1Zm25 1h-1v1h1v-1Zm-25 4h-2l-1 1h5l-2-1Zm45 2h-2l-1 1h3v-1Zm-6 0h-6 9-3Zm-19 0h-23 31-8Zm-25 0h-6l4 1h4l-2-1Zm-6 4v-1h-2v2h1l1-1Zm57 1v-2h-4v5h2l2-1v-2Zm-11-1h1v1h-1v-1Zm0 2 2-1h1v1l-1 1h-2v-1Zm6-1v-2h-7v5h7v-3Zm-13-1-1-2v6l1-1v-3Zm-2 1v-3h-8v6h8v-3Zm-20 1v-3l1 5h10v-6h-20v6h9v-2Zm-12 2h2v-6h-6v7h2l2-1Zm58 4h-1v1h1v-1Zm-67 2h-4l1 1v1l2-1h1v-1Zm56 2-1-1-1 1v1h2v-1Zm-3 0h-3v2l2-1h1v-1Zm15 0v-2l-2 1v4h2v-3Zm7-1-1-2v7l1-1v-4Zm-76 4h-1v1h1v-1Zm73-2v-4l-1-1-1 9h2v-4Zm-22 3-1-1v3l1-1v-1Zm28 3v-2l1 2 1 1 1-2 1-2v-5l-4-1v-2h-2v12h2v-1Zm-21 0v-2l-2 2-1 1h-1v1h3l1-2Zm-60 3v-1l-3-1-3 3h6v-1Zm2-2-1-3v8l1-1v-4Zm28 6h-2l-4 1h8l-2-1Zm-8 3h-1v1h1v-1Zm-15 0h-1v1h1v-1Zm-5 1h-1v1h1v-1Zm28 2v-1h-6l1 2h5v-1Zm45 0v-2h-2v3l1 1v1h1v-3Zm-4 2v-1h-1l-1 2h2v-1Zm7-3-1-2v7l1-1v-4Zm-4 5h-1v1h1v-1Zm-15-27h2l2 1h-5l1-1Zm-6 0h2v1h-3l1-1Zm10 4h1v1h-1v-1Zm-5 13v-1h1l-1 2h-1l1-1Zm1 6-1-1h3v2h-2v-1Zm-7 4-1-1 1-1h1v3h-1v-1Zm9 0v-2l1-1 1-1v2l-1 1h2v1l-1 1 2-1v-30h-16v1l-1 2v5h3-2l-1 1v2h2l1 1v-6l4-1h7v9l-3 3-4 3 1 1v1h-2l1-5h-3l1-2-3-3h-2v20h14l-1-2Zm-25 0v-2h-2l-1 1 1 3h2v-2Zm4-28h1v1h-1v-1Zm2 1h1v1h-1v-1Zm2 4h1v1h-1v-1Zm-5 2h1v1h-1v-1Zm-11-2v-2h7l-3 1-2 1v3h-2v-3Zm-7 4h1v1h-1v-1Zm-2 2v-1h1v2h-2l1-1Zm20 2 1-1 1 1v1h-2v-1Zm-27-1v-4l6-5h9l-1 3v3h2l-1 2v2l-1 1-2 1 1-2 1-3-2-3h-6l1 2-3 1-2 1 1 1-3 3v-3Zm1 7h1v1h-1v-1Zm31 1v-1h2l-1 2h-1v-1Zm-35 1h1v1h-1v-1Zm20 9h4v-2h-12l-2-3v-4l1-4h14l1 8v-1l1-1v-22h2v29h9v-16l-2 1v-3l-1-1h2l1 1v-14h-9v2l-1-1-2-1h-23v4l-2 1-1 1 1-1 1-2-1-2-2 3-2 2 1 15 1-15v19l7 6h2l1 1h11Zm55-3 1-3-1-1-1-1-2-1h-2v11l2-1 3-1v-3Zm-42 12v-1h-2v3h2v-2Zm21 1v-1h-1v1l-1 1-1 1h4l-1-2Zm8 2h-1v1h1v-1Zm-5-1-1-1v3l1-1v-1Zm-16 1-1-2v5l1-1v-2Zm-2-1-1-1v1l-1 1 1 3 1-3v-1Zm-42 2v-1h-1l-1 1v2h2v-2Zm62-1-1-2v7l1-1v-4Zm-39 3h-4v2l4-1v-1Zm42-1-1-1v1l-1 1 1 3 1-3v-1Zm-66 3v-1l-1-1h-1l1-2 1-2h8l2 2v-6h-5l-4 1-2 2-3 3 1 5h2l1-1Zm73-3-1-3v8l1-1v-4Zm-3 2v-3h-2v6h2v-3Zm-20 0v-2h-2l1-1 1-1v-2l-1-1h-2v10h3v-3Zm-41 1-1-1v3l1-1v-1Zm57 2h-1v1h1v-1Zm-61-5h2v1h-3l1-1Zm-1 3-1-3 1 2 2 1 1-1v-1h1l1 1v-2l-2-1h-2l-1 1-2 1v3l1 1v1h1l-1-3Zm65 3h-1v1h1v-1Zm-10-4v-3h-4v3l1 2 1 3 1-1h1v-4Zm-6-1 1-1v-5h-3v12l1-2v-3l1-1Zm26 4 1-1v-4l-2-1-3-1h-1v10l2-1 3-1v-1Zm-77 2h-1v1h1v-1Zm-3 0-2-1-1-2 1 2 1 2h1v-1Zm29-13h1v1h-1v-1Zm5 8 1-8-2-1-14 1h-1v14l2-10h10l1 2v10h3v-8Zm-7 7h-8 11-3Zm-10-1-1-2v4l1-1v-1Zm-2 1v-1l-2-1 2-1 2-1v-12l-3 1h-2l1 16h1l1-1Zm-4 1-1-1-1 1v1h2v-1Zm-10 6-4-2-3-3-3-3v-2h-7v-10l4-4 3-4v-7l-2-1v-11l3-2 2-2v-8h5v-8l1-3 1-4h5v-2l2-1h2v-1l-1-1 1-1 1-1h5v4h4l1-4h9l1 2 1 3h3l1-4h6v3l1 3h16l2 3 3 3v4h7l5 1 4 1 1 1 1 1v13l-2 3h-5v3h5l2 2v12l-2 3h-5v3h5l2 2v13h-2l-2 1-4 1-12 1-1 1-2 1h-19l-2 2-1 2h-6v-1l-1-2-2 3h-4l-3-3-2 3h-4l-3-3-2 3h-4l-5-3Z" style="fill:';
    string private constant PART_6 =
        ';"/><path d="M198 99v-1h-7v1l7 1v-1Zm-15 0v-1h-3l1 2h2v-1Zm26 1v-1h-3l1 2h2v-1Zm-7 3h-24 33-9Zm26 2h-2l-1 1h3v-1Zm-6 0h-7 10-3Zm-44 0h-6l4 1h4l-2-1Zm53 5h-1v1h1v-1Zm-13 1h1v1h-1v-1Zm6 0v-3l1 5h4v-4l1-1h2-17 1l1 1v4h7v-2Zm-52 0v-3l-2-1v8h2v-4Zm8 2v1h29l1-1 2-1v-1l-1-1 1-1 2-1-4-1h-6l8-2h-32l23 1-1 1h-29v9l7-4v1Zm53 4h-1v1h1v-1Zm-65 3 2-1h-6v5l3-3 1-1Zm68 3 1-2-1-2v-3h-1l-1 1v8h2v-2Zm0 3-1-1-1 1v1h2v-1Zm0 3-1-1-1 1v1h2v-1Zm7-9-1-4v15l1-3v-8Zm7 3v-5l-1-1v-1h-5v16l3-2 3-2v-5Zm-10 1v-8h-2v14l1 2h1v-8Zm-79 9v-1l2 1v1l-1 1h-2l1-2Zm4 2v-6h-4l-1 1-1 1v6l1 1v2h5v-5Zm3-7h2l-2-1-1-1 1-1v-1h1l1 1v-2h-3v20-15h1Zm-1 17-1-2v4l1-1v-1Zm76-5-1-3v11l1-2v-6Zm-3 3v-5h-2v10h2v-5Zm-4 3v-8l-2 1v9h2v-2Zm-35-28h1v1h-1v-1Zm-17 5v-2l1 1v1l-1 1v-1Zm10 1-1-1v-3h6-2l-2 1v4h-1v-1Zm7 1h1v1h-1v-1Zm-17 2h1v1h-1v-1Zm-2 0 1-2-1-1h-2l2-4h9v5l-1-2v-3l-2 4h-2l1-2v-1h-4v2l1 3-2 1-1 1 1-1Zm-5 0v-2l1-1h2l1 1-4 4v-2Zm13 2v-1l2-3v2l-2 3v-1Zm-11 0h1v1h-1v-1Zm33-4v-8l1 4v8l-1 3v-7Zm-11 5v-2l1 2v1l-1 1v-2Zm19-7v-1h2v2h-2v-1Zm5 5 1-2v-5h-8v2l-1 2 1 2v3h6l1-2Zm-7 2-2-2 1-8h10v9l-7 4-2-3Zm-6 4v-2l1 1v1l-1 1v-1Zm0 6v-5l1 3v5l-1 2v-5Zm-24 1v-2h4l5-1v-3h-11v8h2v-2Zm-2 1-1-2 1-6h12v4l1 5-1 1-1 1h-6l2-1 2-1v-3h-6v2h6l-8 3h-1v-3Zm15-2v-7l1 1v12h-1v-6Zm26 6v-1l1-1h1v1l-1 2h-1v-1Zm-3 3v-1h4l1-2 2-1v-30h-54l-3 3-3 2v21l4 4 3 3h1v-1l-3-3-4-3v-1l1-1 4 5 4 4h31v-3l1 2 1 1h9l-1 2h2v-1Zm-6 0h-1v1h1v-1Zm30-10-1-2 1 1 1 1v1h-1v-1Zm1 10h1v-10l-1-1-1-1h-4v15l2-2 1-1h2Zm-12 10-1-1h-2v2h3v-1Zm-78 1h-2l-1 1h3v-1Zm72-3-1-2v7l1-1v-4Zm0 6h-1v1h1v-1Zm-75 1h-1v1h1v-1Zm57-4h1v1h-1v-1Zm0 4v-3l2 5 1-6-1-3v-3l-1 3-1 2v-4h-2v11h2v-2Zm24 1v-3l-1-1h-2v6h2l1-2Zm-8-4v-7h-1l-2 1h-1v13h4v-7Zm-50 5v-5l-2-1h-2l-1 1-2 1v4h1l1 1v-2l-1-2 5 1v2l-1-1-1-1v2l1 1h-1l-1 1h3l1-2Zm61-3v-6h-2v12h2v-6Zm-4 5h-1v1h1v-1Zm-3-8-1-4v13l1-6v-3Zm13-1h1v1h-1v-1Zm-2 9v3h4l2-3v-8l-2-3h-4v7l-2-8v15l2-7v4Zm-15 1-1-1v3l1-1v-1Zm-5-6v-8h-3v16h3v-8Zm-4-1v-7h-2l-1 8v8h1l2-1v-8Zm-5 6-1-2v5l1-1v-2Zm-2 1-1-1h-1v3h2v-2Zm-7-9v-2l1 1v1l-1 1v-1Zm1 9v-1l1-7-2 2 1-2 1-2v-2l-1-3h-2v17h2v-2Zm-41-10v-1l1-1h1v1l-1 2h-1v-1Zm1 6h1v1h-1v-1Zm25-1v-1h1l-1 2h-1l1-1Zm7 1v-4l-6 1h-4v5l1 1v1h9v-4Zm-11 0v-5l2-1h9l1 1v10h-12v-5Zm5 6 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm-11-1v-4l-1 2v1h-6l-1-1-1-2v-2l-1-2 4-3h6v-2l2 4v6l-1 6 1-2h2l2 1 1-15v14h3v2h7l6-1 1-2v-16h-15l-2 1-1 2v-3h-5v2l-1-1v-1h-10l-2 2-3 2 1 4v4l3 3 3 4h8v-3Zm33 4-1-1-1 1v1h2v-1Zm-3 0h-1v1h1v-1Zm-39 3-4-2-4-3-3-4v-1h-7v-11l7-7v-7l-1-1-1-1v-5l1-6 2-1 2-1v-9h5v-8l1-3 1-4h5v-2l2-1h2v-1l-1-1 1-1 1-1h5v4h4l1-4h9l1 2 1 3h3l1-4h6v3l1 3h16l2 3 3 3v4h7l5 1 4 1 1 1 1 1v13l-2 3h-5v3h5l2 2v12l-2 3h-5v3h5l2 2v13l-5 1-3 1-3 1-9-1-1 2-2 1h-19l-2 2-1 2h-4l-3-3-2 3h-4l-3-3-2 3h-4l-3-3-2 3h-4l-4-3Z" style="fill:';
    string private constant PART_7 =
        ';"/><path d="M243 123h1v1h-1v-1Zm7 15h1v1h-1v-1Zm-7 5h1v1h-1v-1Zm-59-44-1-2h-3v3h4v-1Zm26 0v-1h-4l-1 2v1h2l2-1 1-1Zm1 4h-32l-1 1h33v-1Zm17 2h-2l-1 1h3v-1Zm-6 0h-7 10-3Zm7 4h1v1h-1v-1Zm0 2h1v1h-1v-1Zm0 2h2v-5l-2-1h-14v6h1l2 1h9l2-1Zm5 12v2h3l-1-1-1-2 2 2v-11h-3v4l-2-5v14l2-6v3Zm2 7-1-1-1 1v1h2v-1Zm-1-2 1 1 1-1v-1h-5v4l1-1v-2h2Zm0 4h-2l-1 1h5l-2-1Zm-75 6h-1v1h1v-1Zm11 8h-1v1h1v-1Zm-4-13h1v1h-1v-1Zm1 11v-1h3l-2-2-2-1v-1l1-1 1 2 1 1v-16h-3l3-3v-5h-6v5l1-1h1v12l1 13-2-1v2h2l2-1-1-2Zm65 2-1-1v3l1-1v-1Zm-26-42h1v1h-1v-1Zm-10 0h4l2 1h-7l1-1Zm-5 0 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-7 0 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm-3 1 1-2 1 1v1h-2l-1 1 1-1Zm7 7-1-1h33v2h-32v-1Zm43 6h2v1h-3l1-1Zm-4 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-22 0h1v1h-1v-1Zm-8 1-4-1h8v2-1h-4Zm3 2h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-5 1-1-1 2-1h1v1h-2l1 2h-1v-1Zm2 1h1v1h-1v-1Zm-4 0h-1v1h1v-1Zm-2 1 1-2v1h1v1l-2 1v-1Zm39-1v-4l1 5v2l-1 1v-4Zm10 0 1-5v8l-1 1v1-5Zm-7 5h4l2 1h-7l1-1Zm-23 9 1-1 1 1v1h-2v-1Zm-24 1 1-1 1 1v1h-2v-1Zm24 3v-1l2-1v3h-2v-1Zm-8-1v-3l1 2v2l-1 1v-2Zm-2 0-1-1v-3l1-4h12l-6 1h-6l1 9h-1v-2Zm-10 1h1v1h-1v-1Zm51 2h1v1h-1v-1Zm-34 3h1v1h-1v-1Zm8 1v-1h2v3h9v-4l2 3 9 1 8-5v-31h-18l1-8h-1l-2 1-1-1-1-1 5-1-42-1-2 4v7l2 2v-9l1 4v4h2l1-2h3l-4 3-4 3v21l4 4 4 4 3 1h19v-1Zm39-5v-7h-2v15h2v-8Zm-7-5h1v1h-1v-1Zm0 2h1v1h-1v-1Zm0 4v-2l1 1v1l-1 1v-1Zm3 5v-2l1-4v-5l-1-1-1-1h-1l-2 1v9h2v5h2v-2Zm-3 1h-1v1h1v-1Zm-57 0h-2l-4 1h8l-2-1Zm-12 0-1-1-1 2-1 1v2l4-3-1-1Zm-5 6-1-1-1 1v1h2v-1Zm-1 3h-1l-3 1h6l-2-1Zm1 3-1-1v3l1-1v-1Zm-3 0-1-1v3l1-1v-1Zm77-1v-2l1 2v2h-1v-2Zm-1 6v3l2-7v6h1l1 1v-1l1-2v-10l-2-3-2 5v-5l-2 3v-2l-1-2v17l2-7v4Zm-16-9h1v1h-1v-1Zm8 5v-2l1 1v1l-1 1v-1Zm-8-1v-2l1 2v2h-1v-2Zm8 3h1v1h-1v-1Zm-9 0 1-1 1 1v1h-2v-1Zm-2 0h1v1h-1v-1Zm0 3h1v1h-1v-1Zm7 2v-4l1 4v4h4l-2-1h-1v-3l2 1v-5l2 5h3v-19h-3l-1 2-1 1v-3l-4 1v-2l-3 2v4l-1-2-1-2-1-1h-3l-2 1v17h2l-1 2h3v-3l2 3 2-6v6l1-1 2-1-1 2-1 2h2v-4Zm-6 3h-4l-1 1h7l-2-1Zm-48-16h1v1h-1v-1Zm27 1h4l2 1h-4l-4-1h2Zm6 2h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm8 6h1v1h-1v-1Zm-33 0h1v1h-1v-1Zm12 0 2-3v-3l-3-2 3 1 1 1 1 1-1 3-2 3-2 1 1-2Zm-6 1-1-2v-5l3-2h3l-3 1-2 1v4l1 1 1 1 1 1 2 1h-3l-2-1Zm16-3v-5h2l-1 4v5h11l-6 1h-6v-5Zm-8 8v-1l2 2 4 1v-18l1 1v17h17l1-17v17l2-2 1-1v-17l-2-2-9 1h-9l-1 1-1 1v-2h-2l-3-1v2l-1-1v-1h-11l-2 3-2 2v12l2 2 3 3h5l5-1v-1Zm24 5v-1h-1l-1 2h1l1-1Zm-29 1v-2l-1 1-1 1-1-1v-1l-3-1-3-1v-2l-2-1v-15l3-2 3-3h-2l-6 7v6l1 6h-2l-1-4h-7v-11l4-3 3-4v-3l1-3-2-2-1-1 1-1h2l1 1-1 1h-1l2 3 2 2v-4l1-13h-5l-1 2-1 1v-1l1-2 2-1 2-1v-9h5v-7l1-4 1-4h5v-2l2-1h2v-1l-1-1 1-1 1-1h5v4h4v-4l1 3 1 2h6l1-2 1-1-2-1-3-1h-3 8l1 2 1 3h3l1-4h6v3l1 3h15l3 2 2 2 1 6h8l9 3h-6v4l-2-5v8l-2-1v-7h-2v18h2v-9l2 1v8l2-9v8h5l1-2v-3l1-11v14l-2 3h-5v3h5v1h-5v2l-2-2v11l1 5v-9l1 4v4h3l2-1h1v-6l1-6v11l-1 1-1 2h-5v3h4l3 3v11l-3 2 1-1 1-2v-10l-2-2h-4v3l-2-5v9l-2-1v-7h-2v15h2v-6h2v7l2-7v6h3l-3 1-2 2h-6l-5-1-1 2-2 1h-19l-2 2-1 2h-4l-4-3-1 3h-4l-3-3-2 3h-4l-3-3-2 3h-5l1-1Z" style="fill:';
    string private constant PART_8 = ';"/></g>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(25, 26%, 50%)";
    string private constant COLOR_3 = "hsl(21, 26%, 41%)";
    string private constant COLOR_4 = "hsl(220, 2%, 37%)";
    string private constant COLOR_5 = "hsl(223, 6%, 24%)";
    string private constant COLOR_6 = "hsl(213, 10%, 18%)";
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
