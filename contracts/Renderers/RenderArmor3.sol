// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderArmor3 {
    string private constant PART_1 =
        '<path d="M173 140H81v-19l17-3 20-2 8-8 43 2 4 11v19z" style="fill:';
    string private constant PART_2 =
        '"/><path d="M133 107h-1v1h1v-1Zm9 1h-1v1h1v-1Zm10-1h-1l-1 3 2-2v-1Zm-13 1h-1v2l1-1v-1Zm-3 1h-1v1h1v-1Zm-7-1v-1l-2 1v2h1v-2h1Zm-19 1h-1v1h1v-1Zm-8 0h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm70 3v-1h-1l-1 2h2v-1Zm-65 6h-1v1h1v-1Zm18 2h-1v2l1-1v-1Zm-2 1h-1l-1 1h2v-1Zm-6 0h-1v1h1v-1Zm53 3h-1v2l1-1v-1Zm-39-3h-1l-3 2v3l4-5h-1Zm-15 3h-1v2l1-1v-1Zm9 2h-1v1h1v-1Zm-27 1h-1v1h1v-1Zm12 0h-1v2l1-1v-1Zm-5 0h-1v2l1-1v-1Zm-11 3h-1l-3 1h6l-1-1Zm-7-1 1-3-3 3v2h1l1-2Zm6 6h-1v1h1v-1Zm54 4-1-1-1 2h3l-1-1Zm-16 37-4-5-13-1-3-9h-8l-1 6H86l-3-6-4-2-1-40 4-5h8l7-8h13l2 2v6h6l10-11h31l4 5h11v10l4 3v12l-2 1v22l-1 3h-4l-3 1v11h-7l-4 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M159 109v-1l-4-2 3 4h1v-1Zm-5 0h-1v1h1v-1Zm0-2v-1l-4 2v2l4-3v-1Zm-19 0-1-1-2 1 3 1v3l1-3-1-1Zm-7 2v-1h3l-1-2-3 1-1 3h2v-1Zm-28 0h-1l-2 1h3v-1Zm46-2h1v1h-1v-1Zm-1 3 3 1-1-5-5 2-4-2v5l4-2 3 1Zm-35 0v-1h-6l2 2 3-1h1Zm-8-1h-1v2l1-1v-1Zm69 3v-1h-5v2h5v-1Zm-7 1h-1v1h1v-1Zm-39 0h-1v1h1v-1Zm34 3h-1v1h1v-1Zm-13 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-12 0h-1v1h1v-1Zm-12 1h-1v2l1-1v-1Zm-7 1v-1h-6v2h6v-1Zm-11 0v-1l-6 1-8-2 1 2 13 2v-2Zm-15 1h-1l-1 3 2-2v-1Zm90 3h-1v1h1v-1Zm4 3-1-1-8 1-2-3v4h11v-1Zm-25 1h-1l-2 1h5l-1-1Zm-5 0h-1v1h1v-1Zm-2 0-1-1h-2v2h3v-1Zm-6 0-1-1h-2v2h5l-2-1Zm38 1h-1v1h1v-1Zm-21 0h2l-3-2v-3h6v4h-2l1-2-2 1 4 3v-2l-1-5h-7v7l1-2 2 1Zm-21-2v-2l-1 3h-9v-2l4-2h23l1-1h-26l-3 2v4h11v-2Zm-13-5-1-4v12l1-5v-3Zm-8 6h-1v-3l2-1 3 1-1 4h2v-2l1-7-3 3-4-1-1 2-1 6 4-1-1-1Zm60 2h-1v1h1v-1Zm-37 0h-1v1h1v-1Zm-28-1h-1v2l1-1v-1Zm62 1-1-1v3l1-1v-1Zm-36 1h-1v1h1v-1Zm-15 0h-1v1h1v-1Zm49 1v-1l-3 1v1h2l1-1Zm-76-3-1-1h2v2h-1v-1Zm-7 0-1-1h6l7 5-3-6H83l-2 5v1l4-3v-1Zm21 3v-3l-6-1v3l5-1v4h1v-3Zm37 2v-2l-2 1 1 2h1v-1Zm-23 0h-1v1h1v-1Zm-18 1h-1v1h1v-1Zm-13-2h2l3 2-4-4h-3l-3 3v2l2-3h2Zm0 3-1-1v3l1-1v-1Zm32 2h-1v1h1v-1Zm-28 1h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm65 3h-1v1h1v-1Zm-5 0h-4l-3-2-1 2 4 1h8l-4-1Zm-9 0-1-1-1 2h3l-1-1Zm-3 0-1-1-1 2h3l-1-1Zm-3 0-1-1-1 2h3l-1-1Zm-3 0-1-1-1 2h3l-1-1Zm-5 0h-1v1h1v-1Zm-10 0h-1l-3 1h6l-1-1Zm-25 0v-1h-5l1 2h3l1-1Zm-8 1h-1v1h1v-1Zm12 1h-1v1h1v-1Zm23 6h-1v1h1v-1Zm22 2h-1v1h1v-1Zm1 16h-1v1h1v-1Zm-11 1v-1l-2-1v2h2Zm18 0h-1v1h1v-1Zm-21 9-4-5-13-1-3-9h-8l-1 6H86l-3-6-4-2-1-40 4-5h8l8-8h12l2 2v6h6l10-11h31l4 5h11v10l4 3v12l-2 1v22l-1 3h-4l-3 1v11h-7l-4 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="m158 107-1-2h-3v1l5 4v-1l-1-2Zm-5 2 1 1v-4l-2-1-2 4v1l3-2v1Zm-20 0h-1v1h1v-1Zm-5 0v-1h7l1 2v-5l-6 1h-3l-1 4h2v-1Zm-28 1v-1l-2-1-1 2h3v-1Zm10 0v-1l-5-1-2 1 1 2h6v-1Zm-8-1-1-2v4l1-1v-1Zm69 3v-1h-5v3l5-1v-1Zm-46 1h-1v1h1v-1Zm39 0h-1v2l1-1v-1Zm-28 1h-1v2l1-1v-1Zm15 2h-1v1h1v-1Zm-3 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2-10h1l1 1h-2v-1Zm-3 0h1l1 1h-2v-1Zm-1 4v1l2-2 6 2v-6h-10v12l2-8v1Zm-13 6h-1v1h1v-1Zm-2-1h-1v2l1-1v-1Zm35 2v-1h-1l1 1-2 2 2-1v-1Zm-13 1-4-1-3-1 1 2h-2l8 1v-1Zm-12-1h-1v2l1-1v-1Zm-8 1h-1v1h1v-1Zm-19-1v-1h-6v3h6v-2Zm-9 4h-1v1h1v-1Zm-17-1 1-2 14 1-1-3H83l-2 4-2 2h2l1-2Zm94 5v-2h-3v2h-7v-2h6l-1-2h-6v5h10v2h1v-3Zm-55-5-1-4v12l1-5v-3Zm52 8h-1v1h1v-1Zm-65-1-1-2v4l1-1v-1Zm63 2v-1h-2v2h1l1-1Zm-52 0h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm-3-6h1v1h-1v-1Zm1 6-1-2h6l1-6-1-4h-4v2h4l-1 2-4-1-3 3v8h3v-2Zm-7-1v-4l-2 3v-2h-4v5l2-2 3 1v3h1v-4Zm61 3 1-2-3 1v3l2-2Zm-65 2h-1v1h1v-1Zm-15 0h-1v1h1v-1Zm2-2h2l2 2-1-3-4-1-2 1-2-1 3-2h4l5 4h1l-3-4 1-2H84l-2 2-1 4 4-1-1 4 2-3h2Zm85 3-1-1-1 2h3l-1-1Zm-54-1-1-2 1 4 2-1-2-1Zm-31 1-1-1v3l1-1v-1Zm0 3h-1v1h1v-1Zm26 0v-1l4 1v-4l-3-4 1 4-3-1v4l-2 1 1 2h3l-1-2Zm-12 1h-1l-2 1h3v-1Zm-21 0h-1v1h1v-1Zm49-16h1v1h-1v-1Zm-6 1h1v1h-1v-1Zm30 1h1l1 1h-2v-1Zm-12 1-1-1 1-1v2l3-1v1l-3 1v-1Zm-11 0h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm13 2h1v1h-1v-1Zm11 1h1v1h-1v-1Zm-17 0v-1h1l-1 2h-1l1-1Zm-5 0 1-1 1 2h-2v-1Zm30 1h-1v1h1v-1Zm-2 2v-2l3-4 2 3-5 4v-1Zm-4 0v-1l1 1-1 1v-1Zm-14 0v-1l2-1v3h-2v-1Zm-7 0v-1l2 1h-3 1Zm16 0h-1v1h1v-1Zm-2 1v-2l-2 1 1 2h1v-1Zm-1 2-1-1-2-6h7l3-1-5 4h2l1 4-3-1-2 2v-1Zm9 4h1v-9h-2l2-2-1-5h2v16l1-2 3 1-1-2 4-5 1-7-1-2h-36v2l-2 5 4-1-2 3 10 9 1-18v18h5v-2h4v2l-2-1-1 2 9-1 1-1Zm-30-1-1-2v6l1-3v-1Zm-2 2h-1v1h1v-1Zm36 1-1-1-1 2h3l-1-1Zm-25 0h-1l-2 1h5l-1-1Zm-4 0h-1v1h1v-1Zm-10 0h-1l-3 1h6l-1-1Zm-24-1 2-3-5 4-4-2v2l3 1h2l2-2Zm21 3h-1v1h1v-1Zm-18-1-1-1v3l1-1v-1Zm-11 2v-1l-2-1 1 2h1Zm50-1v-2h-2l1 4h1v-2Zm0 4-1-2v4l1-1v-1Zm4 2h-1v1h1v-1Zm-17-4-1-3v10l1-5v-2Zm-2 3v-2l-2-3-1-1-3 3 2 3 2-1 2 2-3-2 2 4h1v-3Zm-4 2h-1v1h1v-1Zm53 1-1-1-1 2h3l-1-1Zm-23-1h1v1h-1v-1Zm7-7v-2h-8l1 3-3 2v-2l-1-3h-6v3l8 7 3 1 6-7v-2Zm-12 8h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm70 1h-1v1h1v-1Zm-28 3h-1v1h1v-1Zm-56 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm42 11h-1v1h1v-1Zm10 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm24 0-1-1v3l1-1v-1Zm-2 1h-1v1h1v-1Zm-8-1-1-1v3l1-1v-1Zm-4 0-1-1v3l1-1v-1Zm-3 0-1-1v3l1-1v-1Zm-11 0-1-1h-2l2 3 1-1v-1Zm-3 10-4-5-13-1-3-9h-8l-1 6H86l-3-6-4-2-1-40 4-5h8l7-7h13l2 1v6h6l10-11h31l4 5h11v10l4 3v12l-2 1v22l-1 3h-4l-3 1v11h-7l-4 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="M130 110v-1h-1l-1 2h1l1-1Zm-23 1 1-1 2 3v-5h-6l-1 2 2 3 2-1 1-1Zm-11 1 2-1 2 2h2v-5h-5l-4 5h1l2-1Zm65 2v-1l-2-1 1 2h1Zm-62-1v-1l-3 1v1h2l1-1Zm74-1-1-1v5l1-3v-1Zm-2 0v-3h-4l-1 6 5-1v-2Zm-7 1-1-2v4l1-1v-1Zm-12-1v-1h1l-1 2h-1l1-1Zm6 2v-1l-4-3v-1l5 1v-5h-8v10h7v-1Zm-31 2h-1v1h1v-1Zm44 0v-2l-2 3v-3l-1 3-2-1v2h5v-2Zm-10 2v-1l-2-2-1 2h3l-1 1-10-2 1 3h10v-1Zm-16-5-1-2-4 1 1 3h4v-2Zm1 3h-1v1h1v-1Zm-6 1h-1v-5l4-4 2 4 2-3v8h-4l-3-2 1 3h-1v-1Zm7 1 2-1-1-12h-10l-1 2 1 10 1 2h7l1-1Zm-13-6v-1l1 1-1 1v-1Zm-5 4v-1l6-1v3h-6v-1Zm7 1v-12h-8l-5 8 1 4 2-2-1-2h2l1-5h4v2l-4 2v6l-3 1h10l1-2Zm-28 2 1-2v-1h-7v5l6-1v-1Zm1 3h-1v1h1v-1Zm-2 0h-1l-2 1h3v-1Zm-4 0h-1v1h1v-1Zm-23 1v-1l3-3h13l4 3-3-2v-4H84l-5 4v5l1-1v-1Zm11 10h-1v1h1v-1Zm2 2h-1v1h1v-1Zm-3 1v-1l-2-1v2h2Zm14-10h1v1h-1v-1Zm2 2h1v1h-1v-1Zm-3 10-2-1v-9h3v11h2v-9h2v-5h-8v14h4l-1-1Zm11-7v-1l3-3 1 1-2 4h-2v-1Zm-3 5h1v1h-1v-1Zm8-2v-17l2 12v-12l-3-1-1 2-4-1v2l6 1h-7l-2 3v9h3l1 2-4-1v6l8 1h1v-6Zm15-10h1v1h-1v-1Zm8 7v-2l2 1v2h-2v-2Zm2 8-1-1-2 1v-2h2l1 2h8v-14l1 14h9l-1-17-1-1-35-1-3 3 1 10v6h11l1-12v12h6l1 2 2-1v-1Zm-52 0 2-3-5 4h-2l-3-4 1-3v4l3 2 2-1-4-3 3-4-4 4 1-3 4-1 3 2-1-3h1l4 2 1-3-3-4H84l-4 3v4l2 3-1-4h3l2-4 6 1v2l-5-1-4 4v5l5 3h2l2-2Zm4 2v-1l-3 2v1h2v-2Zm-13-1-1-2h-2l3 5h1l-1-3Zm25 9h-1v1h1v-1Zm60-26h2l3 1h-6l2-1Zm5 8h1v1h-1v-1Zm-1 2h1v1h-1v-1Zm-4 4v-1l4-3-3 4h-1Zm-2 0h1v1h-1v-1Zm2 9-1-1 1-1 1 3-1 1v-2Zm1 2 2-2-3-4 2 1v-6l6-5v-11h-11v5h10v2h-10l2 2 8-1-5 1v2l2-1-1 2-3-3-2 2 1-2h-3l1 3h2l-3 4 1 11 2 2-3 1h4l1-3Zm-9-7h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm0 3h1v1h-1v-1Zm8 1v-5h-9v11h9v-6Zm-23 3h1v1h-1v-1Zm9 1v-1l2 1h-3 1Zm-10 1-1-2 3 3h12v-11h-8l-2 4-1-4h-6v10l1 1h2l-1-1Zm-6-8h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm3 5-1-1 2 1v1h-1l-1-1Zm7-2v-5h-11v11h11v-6Zm-17 5v-1l2 1v-9l-3-1h-6v9h2l-1 2h6v-1Zm-14 0v-1h-1l-1 2h1l1-1Zm-21 1v-1l-2-1v2h2Zm39-9v-9l-1-1v20l1-1v-9Zm54 11v-1l-4-1 1 2h3Zm-85-1h-1v1h1v-1Zm-6 0v-1h-1l-1 2h1l1-1Zm60 2-2-1-1 2h3v-1Zm-49-1 2-2-3 3-11 1h11l1-2Zm9 2h-1v1h1v-1Zm65 2-1-1-1 2h3l-1-1Zm-82 6h-1v1h1v-1Zm67 1h-1v1h1v-1Zm-13 0h-1v1h1v-1Zm-4 0h-1v1h1v-1Zm-20 0h-1l-2 1h3v-1Zm50 1v-1l-5 1v1h5v-1Zm-41-1-1-1v3l1-1v-1Zm-4 1v-1h-2v2h2v-1Zm45 2-1-1-1 2h3l-1-1Zm-4 0h-1v1h1v-1Zm-5 0v-1h-4l-1 2h5v-1Zm-10 0v-1h-5l1-2h-2v4h6v-1Zm-7 0v-1h-6v2h6v-1Zm-7-1-1-1v3l1-1v-1Zm-3 0v-2l-4 1v2l4 1v-2Zm17 10h-1l-2 1h3v-1Zm-5 0h-2l-3 1h7l-2-1Zm-7 0h-2l-3 1h7l-2-1Zm-9 0-4-5-13-1-3-9h-8l-1 6H86l-3-6-4-2-1-40 4-5h8l7-7h15v7h6l10-11h31l4 5h11v10l4 3v12l-2 1v22l-1 3h-4l-3 1v11h-7l-4 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M102 113v-2h2v2l6 1v-3l1-3H97l-5 5 10 1v-2Zm62 0-1-2v6l1-2v-2Zm7 3v-3l2 6v-9l-2 3v-4h-5v8l1 2h4v-3Zm-15-5-2-2h2l2 2-1 2-1-2Zm2 6h-7v-2l6 1 3-4v3l-2 1 3 2h-3v-1Zm3-4v-5h-2v-3h-9v11l1 3h10v-6Zm-11 5h-1v1h1v-1Zm-7-8-1-1h2l1 3h-1l-1-2Zm2 3h1v1h-1v-1Zm-5 2v-1l1-1v3l5-1-1 2h-6l1-2Zm8 3v-1l1-12h-12l1 12 1 2h8l1-1Zm-18-2-1-1 6 1v1l-5-1Zm-3-1-1-1 4-5-2-1h2l1 2-4 3 1 4h-1v-2Zm9 2v-12h-9l-3 7-1 3 2 4h10v-2Zm-47 4v-1h-1l-1 2h1l1-1Zm20-1-1-2 3 1v-2l-3-1h-6v7h7l-1-3Zm-10 4h-1v1h1v-1Zm-17-2v-1l1-2h13v4h4l-3-7H83l-4 5v6l2-4v-1h1Zm9 11-1-1h-3l-1 1h5-1Zm17 4h-1v1h1v-1Zm-2 3h-1v1h1v-1Zm-5-8h1v1h-1v-1Zm1 9h1v-4l-2 1 1-3 2-2-3-3h3l-3-2h3v11h2v-7l2 5v-12h-8v18l1-3 1 1Zm-5 0v-1l1-11-3-4H83l-4 3 1 10 2 5h2l-3-6 2-5 4-5h4l1 3-4-1-5 3v5l3 4h3l4-3v-7l-2 3 1 4-2-4h-3l4 5-3 1-4-5 4 4 1-1-4-4-1 1 2-4h8v3l2-3v8l-4 5 4-2 1-1Zm-9 4-1-1-1 2h2v-1Zm20 2h-1v1h1v-1Zm0 2h-1v1h1v-1Zm62-20h1v1h-1v-1Zm-2 1v-1h1l-1 2h-1l1-1Zm1 19 1-2v-8l1-3h3l2-4-1-4 2-3-2-4h-10l-1 2-1 5 3-1-1 2-1 4h3l-1 2-2-1v17h4l1-2Zm-68 0h1v1h-1v-1Zm3 0-3-1-1 1 1 2 6-1-3-1Zm38-18h1v1h-1v-1Zm0 6h1v1h-1v-1Zm12 2h2l3 1h-6l2-1Zm-5 0h1v1h-1v-1Zm-22 0h2l4 1h-8l2-1Zm15 2-1-2 1 2 4-2-3 3h-1v-1Zm-8 3h1v1h-1v-1Zm18 1v-3l1 3-1 2v-2Zm-18 2v-1l1 1-1 1v-1Zm18 2v-2l1 5 8-1 1-11h-4l4-1v-18l-4-1h-33l-3 2v14l2 4h-2v7l2 5h28v-2Zm-33-26v-6l1 6-1 5v-5Zm-3 16h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm6 12v-1h3l-1 2 2-1v-18l-3-1 1-3 2 1v-13h-5l1-2h-1l-3 3v1h5l-7 2-2 8 2 3h3l3-4-1 4-6 1v13l1 5 2 1h4v-1Zm-11 0h-1v1h1v-1Zm69 1v-1l-3 1v-2l-1 1 1 2h3v-1Zm-31 2-1-1h-4l1 2h4v-1Zm30 1v-1h-2v2h1l1-1Zm-68 0h-1l-3 1h6l-1-1Zm-22-3h1v1h-1v-1Zm7 2v-1l3-1v2h-3Zm4-1 2-2v-1l-14 1-3-3v3l4 5 10-1 2-2Zm75 4h-1l-2 1h3v-1Zm-84 0h-1v1h1v-1Zm25 2h-1v1h1v-1Zm0 3v-1l-3-1 1 2h2Zm1 1h-1v1h1v-1Zm-16 1v-1h-5l4 2 1-1Zm-7 0v-1h-3v-2l-2 1 5 3v-1Zm34 1v-1h-4v2h3l1-1Zm-6-1v-2h-4l1 2 3 2v-2Zm9 1v-1h-2v3h2v-2Zm-11 1h-1v1h1v-1Zm50 1-2-1h4v-3l-3 1h-3l1 4h6l-3-1Zm-42 0h-1l-2 1h3v-1Zm35-1v-3h-5v4l5 2v-3Zm-9 0-1-3h-13v4l-2-4v5h16v-2Zm-18-1v-2h-3l-1 3 1 3 4-2v-2Zm-1 5-1-1v3l1-1v-1Zm18 7v-1h-17l1 2 15-1h1Zm-21-1-4-5-13-1-3-9h-8l-1 6H86l-3-6-4-2-1-40 4-5h8l7-7h15v7h6l6-7 3-4h32l4 5h11v10l4 3v12l-2 2v21l-1 3h-4l-3 1v11h-8l-3 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="m156 111-2-2h2l2 3v1l-2-2Zm3 3v-1h1v2h-2l1-1Zm-8 1h1v1h-1v-1Zm8 2h1v1h-1v-1Zm8 48h1v1h-1v-1Zm-64-53 1-2v4h6v-2l1-4H97l-5 5v1h10l1-2Zm61 0-1-2v7l1-3v-2Zm-63 4h-1v1h1v-1Zm70-6h1v1h-1v-1Zm0 6v-3l2 6v-9l-7-1v10h5v-3Zm-35-9h1v1h-1v-1Zm-8 1h1v1h-1v-1Zm14 1h1l1 1h-2v-1Zm2 2h1v1h-1v-1Zm-4 3v-1l1 1-1 1v-1Zm2 2h1l1 1h-3l1-1Zm-15-1-1-1 5-5-4 5 1 3h-1v-2Zm10-1v-5 7l2 3h8l1-2 2 2v-2l-2-1 1-11h-22l-2 5h-2v5l2 4h12v-5h-1Zm-40 8-1-1 2 1v1h-1l-1-1Zm-10 0h6v-2H82l1-1h13l-2 2 5 4 1-3-2-6H83l-4 4v6l4-4h4Zm4 11-1-1h-4v1h5-1Zm4 4h-1v1h1v-1Zm13 3-1-1v3l1-1v-1Zm-5-1v-2l-2 1 2-4v-4l-2-2h3v14h2v-7l2 5v-15l-7-1-1 1v17h3v-3Zm-16-3 1-1 1 2h-2v-1Zm8 6h1v1h-1v-1Zm-2 2v-1h2v2l2-2-1-2 2-1v-12l-3-3 3 1-2-1H83l-4 3 1 12 2 2v3l3-1-4-6 2-6 4-5h4l1 3-4-1-5 3v5l3 4h6v-3l-4 2-3-4 3 3 3-1v-3l2 3v-7l-2 3h-7l2-3h8v3l2-3v7l-3 1 1 2-2 4-4-1-4 2h9v-1Zm12 2h-1v1h1v-1Zm3 0-1-1v3l1-1v-1Zm62-17h1v1h-1v-1Zm-4 4h1v1h-1v-1Zm3 16 2-3v-10h3l2-3 1-9-2-3h-10l-1 2-1 5 3-1-3 4 1 20h4l1-2Zm-1 3-1-1-1 2h3l-1-1Zm-61-1 1-2h-6l1 2-2-1 1-3h-2v6l5-1 2-2Zm59 4v-1l-2-1 1 2h1Zm-60 0h-1l-3 1h6l-1-1Zm-13-5h1v1h-1v-1Zm3 3 1-2-2-2H83l1 2h-2l-2-3v3l5 5h9l2-3Zm78 3 1-1-4-3 4 1v-4h-3l-3 4 1 3-3 2h7v-1Zm-80 1-1-1-1 2h2v-1Zm-3 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2 0h-1l-2 1h3v-1Zm43 2v-1h-2l1 2h1v-1Zm12-28h1v1h-1v-1Zm15 8h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-18 0h1v1h-1v-1Zm-4 0h1l1 1h-3l1-1Zm16 2v-1h1l-1 2h-1l1-1Zm9 7h1v1h-1v-1Zm6 4h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm18 1h1v1h-1v-1Zm-8 0v-1h7v1h-7Zm-2 0h1v1h-1v-1Zm-6 1v-1l1 1-1 1v-1Zm15 1h1v1h-1v-1Zm-17 0-1-1 2 1v1h-1v-1Zm29 2-1-1h3l-2-1-2 1 1 2h1v-1Zm-1 1-1-2-1-2h4l1 3-3 2-1-1Zm-19-1 1-2 4 3-3-3 4-1 1 3-1 2-8-1 2-1Zm-11-1-1-2 4 4 1 2 2-1v-8l4 1-3 1v6l3 1h8v-3l2 3 4-1v-5l1-4v10h6l3-4v-36h-35l-5 1v18h3l-3 1v10l3 3v1l-2-1v1l5 4-4-1v2l2-1v3l2-4v-1Zm-11-37h1v1h-1v-1Zm2 4v-6l1 6-1 5v-5Zm-3 5h1v1h-1v-1Zm0 11h1v1h-1v-1Zm1 17v-1h2v2h-2v-1Zm-5 1h1v1h-1v-1Zm6 2h2v-6l-5 1 1 3-4-1 4-4 5-1v-18l-3-1 1-3 2 3v-14l-1-2h-4l-3 1v2l4 1h-6l-1-4h-8v7h7l-1-5h2v3l-1 10 4 1 3-2v2l-3 1h-4l1 22 3 5h3l2-1Zm-22 1h-1v1h1v-1Zm16 4v-1l-2 1v-2l2-2-2-1-2 2 2 4h1l1-1Zm-25-2-1-1 2 1v1h-1l-1-1Zm9 2h1l-1-2-6-1v2l-3-3-3 2 3 2h10Zm27 2-1-3h-3v5h4v-2Zm-6-1v-3h-4v6h4v-3Zm9 1v-3h-2v4l1 3h1v-4Zm30 2h1v1h-1v-1Zm1 4 1-1v-9h-5l-2 5 2 2 3-2-3 4 1 2h2l1-1Zm-21-4h1v1h-1v-1Zm2 1v-1h2l-1 2h-1v-1Zm-3 0 1 1-1 3h6v-4l3-1 1 2-1-1-1 2v2h5l-1-5h2v-5l-4-2 1 2-11-1v5l-2-4v11l1-5 1 1Zm-4 0 1-4-1-3-4 1v8l1 2h3v-4Zm17 8v-1h-17l-1 2h18v-1Zm-21-1-4-5-13-1-3-9h-8l-1 6H86l-3-6-5-2v-40l4-5h8l7-7h15v7h7v-2h3l-1-1 7-8h32l3 5h-4v-3h-9v11l1 3h10v-10l3-1h10v10l4 3v12l-2 2v20l-1 4h-4l-3 1v3h-7v4l6 1 1 3h-8l-3 5h-6l-1 4h-19l-4-5Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M106 107h1v1h-1v-1Zm-4 0h1l3 1h-5l1-1Zm41 2h1v1h-1v-1Zm-32 0v-1l-3-1h3l1 2-1 1v-1Zm44 1v-1l2 1v1h-2v-1Zm-19 1v-1l1 1-1 1v-1Zm21 1h1v1h-1v-1Zm-30 1v-1l4-3-3 4h-1v-1Zm31 1h1v1h-1v-1Zm-18 0v-1l1 1-1 1v-1Zm-13 1-1-1 2 1v1h-1l-1-1Zm14 1h1l1 1h-2v-1Zm25 39-1-2 3 1v3h-1l-1-2Zm-2-42-1-3v8l1-3v-2Zm7 0h1v1h-1v-1Zm0 4v-2l2 4v-9l-7-1-1 5 1 5h5v-2Zm-21 0h-1v2l1-1v-1Zm-62 2h3l6 1H85l3-1Zm-5 1v-1h1l-1 2h-1l1-1Zm7 2 7-1-1 2 3 3 1-4-2-6H82l-3 5v5l4-4h7Zm13 9v-2l-2-1h3v4h-1v-2Zm0 4v-3l1 4-1 2v-3Zm-2 2h1v1h-1v-1Zm2 5v-1l3 1v-4l2 5v-18l-8-1v18l1 1h2v-1Zm71 2h-1v1h1v-1Zm-88-10-1-1 6 1v-2l-5-1h6v3h-6Zm1 2 1-1 1 2h-2v-1Zm-5-1v-3l5-5h4l1 3-4-1-5 3-1 5v-2Zm0 3 1-1 1 2h-2v-1Zm4 0-1-2 3 3 5-3-3 4h-3l-1-2Zm10 7 1-1v-2l-4 3v-2h-8l-1-3 5 2 3-1 1-3v-8l1 6 2-5v7l-2-1-1 6h2l3-4 1-9-3-5 1-1H83l-4 4 1 14 4 4h11l1-1Zm12 1-1-1v3l1-1v-1Zm-2 4h1v1h-1v-1Zm2 1v-2h-6l4-2v-1h-6v7l2-1 1 2 5-1v-2Zm-27 2h-1v1h1v-1Zm25 2h-1l-3 1h6l-1-1Zm-8 0h-1v1h1v-1Zm-3 0h1v-3l2 1v-6l-2 2H82l1 2h-1l-2-5v6h2v3l3 1h8l1-1Zm-1 2-1-1-1 2h2v-1Zm-3 0h-1l-2 1h3v-1Zm-4 1v-1l-4-1 1 2h3Zm32-39v-1l1 1-1 1v-1Zm-5 0h1v1h-1v-1Zm5 8v-1l1 1-1 1v-1Zm-3 1h1v1h-1v-1Zm3 1h1v1h-1v-1Zm-9 3v-1l3 1 4-3-3 4h-4v-1Zm33 9v-1h1l-1 2h-1l1-1Zm2 11h1v1h-1v-1Zm-5 1v-1h2l-1 2h-1v-1Zm-6 0v-3l1 3-1 2v-2Zm-20 1h1v1h-1v-1Zm46 2h1v1h-1v-1Zm-35 0h1v1h-1v-1Zm15 2v-2l2-1-1 3h2v-6l2 3v4h-5v-1Zm-20-2v-3h-3l4-2v-16l1 1v20l4 4h7l2-3v3h17l1-8v8h6l3-3v-36l-35-1-5 1v13l-4-2 3-1v-13l-1-2-4-1-4 2 1 3h-2l-1-4h-10v2l2 1v4l6 1 1-1v-5l2 2-2 4v28l2 6 3 2h6v-4Zm14 5h-1v1h1v-1Zm-24 2h1v1h-1v-1Zm2 0v-3l-2-1-2 2 1 4h3v-2Zm-22 2-1-1h4v2l4-3-1-3H85l-1 2 3 4h3v-1Zm22 2v-1h-1l-1 2h1l1-1Zm11-1v-4h-4v7h4v-3Zm-6-1v-3h-4v7l4-1v-3Zm9 1v-3h-2v7h2v-4Zm9 5v2l14-1v-8l-2-3h-11l-1 3-2-1v10l2-5v3Zm-3-3v-5l-4-2h-1v12l3 1 2-1v-5Zm24 0h1v1h-1v-1Zm2 4 1-1v-10h-5l-3 4 2 7 3 3v-3h2Zm-9 5v-1h-18l-1 2h18l1-1Zm-22-1-4-5-13-1-3-9h-8l-1 6H86l-3-6-5-2v-40h2l-1-1 3-4h7l8-7-5 6v1h17l3-4v4h6l4-1 1-4v6l2 4h12l-1-7 1 4 2 3h8l1-2 1-12h-22v2l-4 2 5-6h33l-3 2h-8v11l1 3h10v-10h3l-5-4h2l2 3h11v10l4 3v11l-3 5h2l-3 2h2v13l-1-3h-3l1-3-1 2-1 1-1 4-3-1 5-7-1-9h3l3-3v-9l-1-3h-12l-1 4 2 32 1 2 8-1 1-3v-1h-3l-1-2 5 1v3l-1 3h-4l-3 1v3h-7l-1 4 3 1 5 1v2h-7l-4 5h-6v4h-20l-4-5Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M128 104v-1h33l-3 1h-31 1Zm31 1h1l1 1h-2v-1Zm-49 2h1v1h-1v-1Zm14 0 2-2 1 2-4 2 1-2Zm19 2h1v1h-1v-1Zm-7 1h1v1h-1v-1Zm-14 1v-1l1 1-1 1v-1Zm-32 3v-1l6-6-4 7h-2Zm74-1v-2l1 3-1 1v-2Zm-15-1v-6l1-1v12l-1 1v-6Zm19 7h1v1h-1v-1Zm-16 0h1v1h-1v-1Zm-7 1v-1l6-1-1 2h-5v-1Zm-3-1h1l1 1h-3l1-1Zm-8 0 2-1 1 1-1-3h1l3 4h-7l1-1Zm-6 0h1l1 1h-3l1-1Zm-9 0v-1l1 1-1 1v-1Zm-19 0-1-1 1-1 1 3h-1v-1Zm-8 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm86 1h-2l2-3 1-4v6l3 1h-4Zm-91 0h1v1h-1v-1Zm95 1h1v1h-1v-1Zm-99 0v-2h2l-1 4h-1v-2Zm22 1v-1l2 1-1 2h-1v-2Zm-7 1h1v1h-1v-1Zm-15 2v-1l1 1-1 1v-1Zm2 1h1v1h-1v-1Zm39 1v-1l1 1-1 1v-1Zm-3 1h1v1h-1v-1Zm-14 0h1l1 1h-3l1-1Zm17 1h1v1h-1v-1Zm-29 0-1-1 3 1v1h-2v-1Zm-2 2 1-1 1 2h-2v-1Zm-2 0h1v1h-1v-1Zm34 1-1-1h2v-16h-10l1 4-2-3H82l-2 2v-2l3-2h36l4-1v3l3 3-3-1-1 3v11l-2 1v-1Zm-9 1v-1l4-1-1 2h-3Zm-20-1h1v1h-1v-1Zm-7-1 2-3 2-1v2l-6 4 2-2Zm4 2 1-1 1 2h-2v-1Zm-2 1-1-1 2 1v1h-1l-1-1Zm35 1h1v1h-1v-1Zm-18 1v-1l1 1-1 1v-1Zm-15 0h1v1h-1v-1Zm85 1-1-1h3l2-5 1-9v10l-3 4 1 2h-3v-1Zm-72 0h1v1h-1v-1Zm-6-2v-4l1 4-1 3v-3Zm-2 1v-2l1 3-1 1v-2Zm-10 2h1v1h-1v-1Zm79-8v-10l-8-1h8l-1-6 2-3-1-3 12 1v5l-2-4h-6l-4 4 1 5 4 1-1 1h-2l-1 19-1 1v-10Zm-70 9h1v1h-1v-1Zm-6-1-1-2 3 3 3 1h-4l-1-2Zm86 1-1-1h2l2 2-2 1-1-2Zm-88 1h1v1h-1v-1Zm91 1h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-29 0h1v1h-1v-1Zm-49 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm83 1h1v1h-1v-1Zm2 2h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm0 3v-1l3-1 3 2h-6Zm-50-4v-5l1 6-1 4v-5Zm51 5 1-1 1 2h-2v-1Zm-77 0v-1h1l-1 2h-1l1-1Zm-4 0h1v1h-1v-1Zm-4 0h1l1 1h-3l1-1Zm82 1h1v1h-1v-1Zm-2 2h1v1h-1v-1Zm-47 0h1v1h-1v-1Zm51 1h1v1h-1v-1Zm-72-3v-22l-3-2v-3l2 4 2-1 1 18-2 10v-4Zm76 4h1v1h-1v-1Zm-32 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-43 0h1v1h-1v-1Zm8 1h1v1h-1v-1Zm-18 2h2l4 1h-8l2-1Zm77 1h1v1h-1v-1Zm-23 1 1-1 1 2h-2v-1Zm-59-2-1-1-1 1 3 4v-2l-1-2Zm-3 4-1-1v-32l2 17 1 3-2-1 1 7 4 5h4l1 2h-3l-5 1-2-1Zm4 2h1v1h-1v-1Zm34 2h1v1h-1v-1Zm0 2h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm23 3 1-1 1 2h-2v-1Zm-7-1-1-3 2 2-1 3v-2Zm58 3v-1l1 1-1 1v-1Zm-8-5v-6l3-3v-16l1 1 1 16h9l3-2-1 3h-5l-2 2h-7l-1 7 2 2-3 2v-6Zm-4 9h2l3-3-3 4h-4l2-1Zm-20 3h5l9 1h-18l4-1Zm-29-19v-1h-3l1 2h2v-1Zm20 8v-5h-2l1 10h1v-5Zm6 0v-6h-5v14l5-1v-7Zm-6 8-3-4v-10h-4v2l-2-2h-4v8h3l-1 1-4-1 2-8-5-4-1 2 2 4h-2v-2h-8l1-2 2 1v-2l-1-1-2 3v5l-1 2-1-8-6-1h3l-1-2 4 2 4-4h2l-1 3 6-1v-11l-3 1v-2l-3 1 2-2 4 1v-21l3-4-2 5v33l4 3h6l3-3 4 3h8l-1 14h16v-13l-14-1h23l-7 1v16l-1-1h-20v3l-3-4Zm23 4h1v1h-1v-1Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="m136 103 25 1h-33l8-1Zm24 2h1v1h-1v-1Zm-50 2h1v1h-1v-1Zm13 2v-1l4-3-3 4h-1v-1Zm-28 0v-1h1l-1 2h-1l1-1Zm78 1-1-1 2 1v1h-1v-1Zm-51 0h1v1h-1v-1Zm-31 6 1-1 6-1-1 2h-6v-1Zm-9-1v-1h7l5-3-4 4-9 1 1-1Zm67-4v-7l1 7-1 6v-6Zm-27 5v-1h-10l2-1 9-1v3l-2 1 1-1Zm-15 0h-5l-2-2 10 1 2 2-5-1Zm16 1h1v1h-1v-1Zm-43 0h1v1h-1v-1Zm93 1v-2l1 1-2 2 1-1Zm-11 0h-1v-6l4-4v3l-3 1 1 5 2 2h-3v-1Zm-12 0h1v1h-1v-1Zm-15 0h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm49 1h1v1h-1v-1Zm-18 0h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-9 0h1v1h-1v-1Zm-50 0h1v1h-1v-1Zm31 2v-1h1l-1 2h-1l1-1Zm-10 2h1v1h-1v-1Zm62 0v-3l1 4-1 2v-3Zm-65 2h1v1h-1v-1Zm24-2v-6l1 6-1 5v-5Zm-5 5h1v1h-1v-1Zm-14 0h1l1 1h-3l1-1Zm19 1h1v1h-1v-1Zm-31 0 1-1 1 2h-2v-1Zm18-2v-4l1 5-1 3v-4Zm-20 4 1-1 1 2h-2v-1Zm-2 0h1v1h-1v-1Zm34 1v-1l1 1-1 1v-1Zm-8 0h1l1 1h-3l1-1Zm-21 0h1v1h-1v-1Zm-7-2 2-2h1l-4 5h-1l2-3Zm5 3h1v1h-1v-1Zm-4 0h1v1h-1v-1Zm-7-1v-3l1 3-1 2v-2Zm97 3v-1l2-1v-8l1 7-3 4v-1Zm-54 0h1v1h-1v-1Zm52 1h1v1h-1v-1Zm-95 0v-1l1 1-1 1v-1Zm17-1v-4l1 4-1 3v-3Zm-2 2h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm86 1h1v1h-1v-1Zm-9-5v-7l1 8-1 6v-7Zm-41 6h1v1h-1v-1Zm-34 0 1-1 1 2h-2v-1Zm86 1v-1l1 1-1 1v-1Zm-89 0h1v1h-1v-1Zm87 1h1v1h-1v-1Zm-50 0h1v1h-1v-1Zm52 1h1v1h-1v-1Zm-95-2v-3l1 4-1 2v-3Zm97 4h1v1h-1v-1Zm-73 0 1-1 1 2h-2v-1Zm19 1h1v1h-1v-1Zm-43 0v-1h2v2h-2v-1Zm97 1h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-78 1h1v1h-1v-1Zm-17 0h1v1h-1v-1Zm94 1 1-1 1 2h-2v-1Zm-3 1h1v1h-1v-1Zm-91 1h1v1h-1v-1Zm22-12v-14 28-14Zm71 14h1v1h-1v-1Zm-74 1h1v1h-1v-1Zm-7 3h1v1h-1v-1Zm-5 0 1-1 1 2h-2v-1Zm-4 0-2-2-1-2h2l3 5-2-1Zm-3 0 1-1 1 2h-2v-1Zm23 1-2-1 2-2 3 4h-1l-2-1Zm73 1v-1l2-1-1 3h-1v-1Zm-32 0h1v1h-1v-1Zm-57 1-1-1h3l-1 2h-1v-1Zm77 1v-2l1-18v19h6l-1 1-6 1v-1Zm-7 0 1-1 1 2h-2v-1Zm-3 0h1l1 1h-3l1-1Zm-10 0h2l3 1h-6l2-1Zm-5 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-19 1v-1l4-1-1 2h-3Zm-2-1h1v1h-1v-1Zm-35-1-1-1h2l3 3h-2l-2-2Zm28 3v-1l-9-1-1 1 1-2-2-1h4l-1 2h7l1-2 2 5h-2v-1Zm-24 0h1v1h-1v-1Zm14 2 1-1 1 2h-2v-1Zm52 0 1-2-2-2h2l1 3v3h-2v-2Zm-17-1v-3h1v6h-1v-3Zm-6 2h1v1h-1v-1Zm-18 0h1v1h-1v-1Zm4 0v-5l-4-3v-25l1 24 4 5-1 8v-4Zm-3 3v-2l1 3-1 1v-2Zm58 2h1v1h-1v-1Zm-8-3v-6l2-1-1 9-1 3v-5Zm-1 7v-1h1l-1 2h-1l1-1Zm-12 0 1-1 1 2h-2v-1Zm-3 0 1-1 1 2h-2v-1Zm-11-2v-3h1l1 6h-3l1-3Zm-3 2h1v1h-1v-1Zm-4-1-2-2 1-11-3-1v-2l5 3h5l-4 1-1 3v-3h-2v11h2l1-6v9h-1l-1-2Zm25 2-1-1v-5l2 1v7h-1v-2Zm-4 3h1v1h-1v-1Zm-5 0 1-1 1 2h-2v-1Zm-2 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-6 0-1-1 1-1 1 3h-1v-1Zm20 1h1v1h-1v-1Z" style="fill:';
    string private constant PART_11 = '"/>';
    string private constant COLOR_1 = "hsl(222, 0%, 100%)";
    string private constant COLOR_2 = "hsl(220, 3%, 52%)";
    string private constant COLOR_3 = "hsl(222, 0%, 63%)";
    string private constant COLOR_4 = "hsl(215, 4%, 43%)";
    string private constant COLOR_5 = "hsl(220, 2%, 37%)";
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
