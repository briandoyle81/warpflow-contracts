// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderBaseBody {
    string private constant PART_1 =
        '<path d="M107 135h-3v1h3v-1Zm-15 0h-1v1h1v-1Zm50 20h-1v1h1v-1Zm-9 16h-1v-2l-4-5h-12l-7-7v-2h-6l-2 4H87l-1-4h-4l1-42h9l7-7h15l3 7h5l9-9h32l4 3v6h7l3 3v30l-8 7v11h-4l-5 4h-5l-2 4h-3l-1-3h-2v3h-7l-3-2v2h-2l-1-1Z" style="fill:';
    string private constant PART_2 =
        '"/><path d="m163 107-1-1-1 1h3-1Zm-4-1 2-1h-18v3l14-1 2-1Zm-17 0v-1h-9v2h9v-1Zm-7 3v-1h-1v1h1Zm-4-1-1-1v3l2-2h-1Zm-19 1v-1h-1v1h1Zm-4 0-1-1-4 1h6-1Zm-7-1 1-1h-3v2h1l1-1Zm29 2v-1h-1v1h1Zm-1 3-1-1-1 1h3-1Zm29 2-1-1-1 1h3-1Zm-7 0-1-1-1 1h3-1Zm-15 0-1-1-1 1h3-1Zm-17 0-1-1-4 1h6-1Zm-5 0v-1h-1v1h1Zm-6 0v-1h-1v1h1Zm14 1-1-1-1 1h3-1Zm-10-1v-1h-2v2h2v-1Zm-14 0 1-1H86v2l12-1Zm72 4-1-1-1 1h3-1Zm-56 0v-1h-1v1h1Zm-12 0v-1h-1v1h1Zm-7 0v-1h-1v1h1Zm72 0 1-1h-35l-3 2 36 1 1-1Zm-37 0v-1h-13v2h13v-1Zm-16 2v-1h-1v1h1Zm33 1v-1h-1v1h1Zm10 1-1-1-1 1h3-1Zm-5 0v-1l-3 1h4-1Zm-14 2v-1h-1v1h1Zm32 1-1-1-1 1h3-1Zm-23 1v-1h-1v1h1Zm18 1v-1h-1v1h1Zm-34 0v-1h-1v1h1Zm26 1-1-1-1 1h3-1Zm-28 0v-1h-1v1h1Zm45 1v-1h-1v1h1Zm-70 0v-1h-1v1h1Zm47 1v-1h-1v1h1Zm-56-1v-1h-2l-1 2h2v-1h1Zm80 2v-1h-1v1h1Zm-19 1v-1h-1v1h1Zm-48 1v-1h-3v2h3v-1Zm-13 1-1-1h-3l4 2h1l-1-1Zm69 3v-1h-1v1h1Zm-2 1v-1h-1v1h1Zm-63 1v-1h-1v1h1Zm63 1v-1h-1v1h1Zm-4 1v-1h-1v1h1Zm-8 0v-1h-1v1h1Zm-14 0v-1h-1v1h1Zm-20-9v-11H87l-2 2 3 2-2-3 28 1v18H87v1h28v-10Zm52 11v-1h-1v1h1Zm-36 0v-1h-1v1h1Zm-11 0-1-1v3l2-2h-1Zm33 11v-1h-1v1h1Zm-12 0-1-1v3l2-2h-1Zm-8 16-2-1v-2l-6-6h-10l-6-6v-2h-6l-3 4H87l-1-4h-4v-38l2-4h9l6-7 15 1 3 6h6l8-9h32l4 4v5h8l2 3v29l-7 8v10l-6 2-3 3h-5l-2 4h-3l-2-3h-1v3h-8l-2-2v2h-4Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="m103 135 1 3 4-1v-5h-4l-1 3Zm2-2h3v2h-3v-2Zm-1-3v-1 1Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="M163 107h-1l-1 1h3l-1-1Zm-4 0 2-1h-19v2h15l2-1Zm-18 0v-1h-9v1l9 1v-1Zm-7 2h-1v1h1v-1Zm-3-1h-1v2l1-1v-1Zm-20 1h-1v1h1v-1Zm-4 0h-1l-3 1h6l-1-1Zm-6 0v-1h-2v2h1l1-1Zm28 1h-1v1h1v-1Zm0 3h-1l-1 1h3l-1-1Zm29 2h-1l-1 1h3l-1-1Zm-7 0h-1l-1 1h3l-1-1Zm-15 0h-1l-1 1h3l-1-1Zm-18 0h-1l-3 1h6l-1-1Zm-5 0h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm15 1h-1l-1 1h2v-1Zm-11 0v-1h-2v2h2v-1Zm-13-1H86v2l13-1v-1Zm72 4h-1l-1 1h3l-1-1Zm-57 0h-1v1h1v-1Zm-12 0h-1v1h1v-1Zm-7 0h-1v1h1v-1Zm73 1v-1h-34l-3 2h36l1-1Zm-38 0v-1h-13v2l13-1Zm-16 1h-1v1h1v-1Zm33 1h-1v1h1v-1Zm11 1h-1l-1 1h3l-1-1Zm-5 0h-1l-2 1h4l-1-1Zm-15 2h-1v1h1v-1Zm33 1h-1l-1 1h3l-1-1Zm-24 1h-1v1h1v-1Zm18 1h-1v1h1v-1Zm-34 0h-1v1h1v-1Zm27 1-1-1-1 2h3l-1-1Zm-29 0h-1v1h1v-1Zm45 1h-1v1h1v-1Zm-70 0h-1v1h1v-1Zm47 1h-1v1h1v-1Zm-56 0v-1h-2l-1 2h3v-1Zm80 1h-1v1h1v-1Zm-19 1h-1v1h1v-1Zm-60 3-1-1h-3l4 2v-1Zm13-1v-2l-3-1-2 1v4l2 1 3-1v-2Zm55 3h-1v1h1v-1Zm-2 1h-1v1h1v-1Zm-63 1h-1v1h1v-1Zm63 1h-1v1h1v-1Zm-4 1h-1v1h1v-1Zm-8 0h-1v1h1v-1Zm-14 0h-1v1h1v-1Zm-20-9v-10H86l-1 2 2 1-1-2h28v19l-28-1 1 2h28v-11Zm52 11h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm-10 0-1-1v3l1-1v-1Zm32 11h-1v1h1v-1Zm-11 0-1-1v3l1-1v-1Zm-9 16h-1v-2l-6-6h-10l-7-6v-2h-6l-2 4H87l-1-4h-4v-39l1-3h9l6-7h16l3 7h5l9-9h31l5 3v6h7l3 3v29l-8 8v10l-5 1-3 4h-6l-2 4h-3l-1-3h-2v3l-7-1-3-1v2h-2l-1-1Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="M163 108v-1l-2-1v2h2Zm-1 1h-1v1h1v-1Zm-22 0h-1v1h1v-1Zm-27 0h-1v1h1v-1Zm-2 0v-1h-7l-1 2h8v-1Zm45 1v-1h-4l-1 1 4 1 1-1Zm-9 0h-1v1h1v-1Zm-9-1h-1v2l1-1v-1Zm-2 1h-1v1h1v-1Zm3-2 3-1 4 3-2-2h16v-2h-28v2l1 3 3-3h3Zm-38 1v-1h-2l-1 3 3-1v-1Zm57 1-1-2v4l1-1v-1Zm-15 0h-1v2l1-1v-1Zm-12-1v-1l-4 2v2l4-3Zm-2 4h-1l-1 1h3l-1-1Zm29 2h-1l-2 1h4l-1-1Zm-5 0h-1l-3 1h6l-1-1Zm-5 0h-1l-1 1h3l-1-1Zm-4 0h-1l-2 1h4l-1-1Zm-4 0h-1l-1 1h3l-1-1Zm-4 0h-1l-1 1h3l-1-1Zm-36 0h-1v1h1v-1Zm70 1h-1v1h1v-1Zm-47 0h-1l-2 1h4l-1-1Zm-21 0h-1v1h1v-1Zm-2 1h-1v1h1v-1Zm-8 0 5-1 2-1H85l-1 3 2-1 6-1Zm12 1h-1v1h1v-1Zm6 1h-1v1h1v-1Zm-15 0v-1l-3 1v1h2l1-1Zm11 1h-1v1h1v-1Zm-4 1v-1l-2-1 1 2h1Zm-13-1h-1v1h1v-1Zm18-4h1v1h-1v-1Zm6 5-1-1 2-1-1-3 5 1 1-2h-13l-1 2h7l-1 5h2v-1Zm-28 1h-1v1h1v-1Zm72 1h-1l-1 1h3l-1-1Zm-26-1h-1v2l1-1v-1Zm11 2h-1v1h1v-1Zm-24 0-1-2 6-2 4 1-1 2h2l-1 2 2-1v-5h-4v-5l-1 5h-8v3l-2-1 3 4h1l-1-2Zm56 1h-1v1h1v-1Zm-9 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm0-1 1-1h-4v3l2-2h1Zm-5-1-1-1h1l25-1-1-2h-40l-1 2 4-1 3 3 1-2 2 2v-2h6l-1 2 2 1-1 2 2-1-1-1Zm-9 3v-1h-2v2h1l1-1Zm32 1v-1h-2v2h1l1-1Zm-15 0h-1l1-2h-2v3h4l-2-1Zm-15 0v-1h-1l-1 2h1l1-1Zm-13 0h-1v1h1v-1Zm37 2v-1l-2-1 1 2h1Zm-31-1h-1v1h1v-1Zm-10 0h-1v1h1v-1Zm24 0h1v1h-1v-1Zm2 0-1-1-2 1-1-2-2 1v2l2-2 2 3 2-1-1-1h1Zm15 2-1-1-1 2h3l-1-1Zm-5 0h-1v1h1v-1Zm-14 0-1-1-1 2h3l-1-1Zm-24 0h-1v1h1v-1Zm52 1-1-2 2 4 1-1-2-1Zm-31 1h-1v1h1v-1Zm12-2h1v1h-1v-1Zm-2 3-1-1h6v-3l-7 1-1 2 3 2h2l-2-1Zm-5 0v-1h-3l-1 2h4v-1Zm-7 0v-1h-3l-1-2 6 1-1-1-6-1 1 4-2-1 1 1 5 1v-1Zm-13-3h1v1h-1v-1Zm3 3 1 1v-2l-2-1 1-3-2-1 1 3-2-1v5l2-2 1 1Zm21 2h-1v1h1v-1Zm-19 0h-1v1h1v-1Zm23 2v-1l-2-1v2h2Zm-33 0h-1v1h1v-1Zm43 1h-1v1h1v-1Zm-17-1v-1l-2-1-1 4h3v-2Zm-13-1h1v1h-1v-1Zm2 1 1-2h-4v1l3 3 1-2Zm-4 1h-1v1h1v-1Zm19 0-1-1v3l1-1v-1Zm-2 0-1-1v3l1-1v-1Zm-27 1h-1v1h1v-1Zm10 1h-1v1h1v-1Zm35 1h-1v1h1v-1Zm-22 0h-1v1h1v-1Zm-43-11h-1v1h1v-1Zm-9 1v-1h-3v3h3v-2Zm1 5-1-1h-3l-1 2 5-1h-1Zm13-1v-2l-3-1-2 1v4l2 1 3-1v-2Zm-14 3h-1v1h1v-1Zm17 1-1-1v3l1-1v-1Zm-13 0-1-1v3l1-1v-1Zm-6 0-1-1v3l1-1v-1Zm-5-5v-10h26v19H87v-10Zm28-1v-10H87l-1 1v20h29v-11Zm58 11h-1v1h1v-1Zm-5 0-3-1-1 2h4Zm-11-1 1-2 3 3 3-2-3 1v-3h2l2 2-2-4h-3v4l-2-1 1-3-1-3v-2h-4l4 2h-2l3 3h-3l-3 3 4-2v3h-4l1 3h2l1-2Zm-9 1 1-2v3h2l-1-2 3-1h-6v2l-3-1-1 1h5v-1Zm-13-1-1-2 2 4 1-1-2-1Zm-4 1-1-1-1 2h3l-1-1Zm-6-3-1-2v6l1-2v-2Zm-4 0-2-2h-1l2 3-3-1 1 1h3l-1 4 2-2-1-3Zm23 8h-1v1h1v-1Zm9 6-1-1v3l1-1v-1Zm-11 0-1-1v3l1-1v-1Zm-10 5h-1v1h1v-1Zm1 11h-1v-2l-6-6h-10l-7-6v-2h-6l-2 4H87l-1-4h-4v-39l1-3h9l7-7h15l3 7h5l9-9h31l5 3v6h7l3 3v29l-8 8v10l-5 1-3 4h-6l-2 4h-3l-1-3h-2v3l-7-1-3-1v2h-2l-1-1Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M160 109v-1h1l-1 2h-1l1-1Zm-18 1 2-2-3 4h22v-6h-31l-7 6h15l2-2Zm-29-1v-1h-11v2h8v2l3-3Zm-12 0v-1h-2l-2 4 4-3Zm55 6h-2l-5 1h10l-2-1Zm-11 0h-4l-8 1h16l-4-1Zm-14 0h-2v-2h-2l1 2h-2v2l3-1v2l3-3h-1Zm-39 5h1v1h-1v-1Zm-6 0-1-1h2l1 3h10v-7H84v8l2-1v-2Zm87 11-1-2 1-1h-4l-1 4 1 1v-2h4l-1 3 3-2-2-1Zm-2 2h-1v1h1v-1Zm-64-4h-1l-2 1h4l-1-1Zm-4 1h-1v1h1v-1Zm7 2v-1l-2-1 1 2h1Zm-15-1v-1l-4-1-1 2 1 2 4-1v-1Zm13 4v-2l-3-1-2 1v4l2 1 3-1v-2Zm3 5v-1h-1l-1 2h2v-1Zm-17 0h-1v1h1v-1Zm-1-4 1-1-1 4 2-3-2-1-3 1 2 5v-4l1-1Zm5 4-1-2v4l1-1v-1Zm-11-6v-9h26v18H87v-9Zm28-1v-10l-29 1v20h29v-10Zm50 11h1v1h-1v-1Zm2 1h1l-1-2 2-3v5l1-1 3 2 2-10-1-3v4l-7-1v5l-3 2v3h1l2-1Zm-44-27v-1l2 1-2 1v-1Zm44 3h1v1h-1v-1Zm-22 0h1v1h-1v-1Zm11 1 1 1h-2l1-1Zm-6 0h1l2 1h-4l1-1Zm19 1v-1h1v2h-2l1-1Zm-21 2h1v1h-1v-1Zm-17-1v-3l3-1 1 1v5h-4v-2Zm21 1v-2l1 3-1 1v-2Zm-9 1h1v1h-1v-1Zm13 2v-1l1 2h-2l1-1Zm-9 0h1v1h-1v-1Zm-17 0-1-1h2l1 2-2-1Zm20 1-1-1 1-1 2 3-2-1Zm-2 2v-1l1 1-1 1v-1Zm8 1h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm4 2v-1l1 2h-2l1-1Zm-5 0-1-2 2 2v1h-1v-1Zm12 3-1-1h2v2h-1v-1Zm-4 2h1v1h-1v-1Zm-6 0v-1l-4 1 1-4 5 3 1-2h2v2l-2-1-1 3h-2v-1Zm-7 1h1v1h-1v-1Zm10 1v-1h2v2h-2v-1Zm-6 0 1-1 1 1-3 1 1-1Zm10 2h1v1h-1v-1Zm-6 0v-1l1 2h-2l1-1Zm3 1h1v1h-1v-1Zm-23 0h1v1h-1v-1Zm31 0v-2h-3l-1-2 5 2 1-2-1-3 2-1-1-5 5-5h-4l-1 2v-4h7v2l-2 1h4v-2l-3-3-1 3v-3l4-2v-4l-13-1-3 1h8l2 2 4 1h-6v-3l-1 3h-36v4l-1-4h-4v-4l-4 1-1 1 3 2h-7l-1 3v-3l4-2v-2H99v4l2 1 2-5v4l-3 2-1-2 1 3h9v-2l2 2h2l-2-4 5 5v3h6l3-2 1-4v11l3-2-4 4 6 1v-3l2 3 14 1h-21l-1 3 1 2 4-1 4 4-4 1-4-3v5h37v-2Zm-41-3h1v1h-1v-1Zm-2-1v-2l1 3-1 1v-2Zm-4 2h1v1h-1v-1Zm3 2 1-2-1 4h5l-1-8v-10h-8v12h4l-4 2v4l3-1 1-1Zm24 3h-1v1h1v-1Zm1 2-1-1-1 2h3l-1-1Zm-38 0h-1v1h1v-1Zm51 7-1-1-1 2h3l-1-1Zm-3 0h-1v1h1v-1Zm-2 0v-1l-4 1v1h4v-1Zm-6 0h-1l-2 1h5l-1-1Zm-5-1-1-1v3l1-1v-1Zm-16 4h-1l-2 1h4l-1-1Zm29 2-1-2 3 3h1v-3h-15l3 2-4 1h13v-1Zm-14-1-1-1-2 1 1 2h2l-1-2h1Zm-8-1-1-1-2 1 3 3 1-1-1-2Zm0 12h-1v-2l-6-6h-10l-7-6v-2h-6l-2 4H87l-1-4h-4v-39l1-3h10l5-7h15l4 7h6l7-9h32l5 3v6h3v2h4l1-3v4h2v29l-8 8v10l-5 1-4 4h-5l-2 4h-3l-1-3h-2v3l-7-1-3-1v2h-2l-2-1Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="M163 108v-1l1 1-1 1v-1Zm-37 2v-1l5-5h32v2h-31l-6 4v-1Zm0 8 1-1 1 1-3 1 1-1Zm-3 0v-1l2 1-2 1v-1Zm-37 1h1v1h-1v-1Zm70 3 1 1h-2l1-1Zm-27-1v-2l3-3h5l-1 3h-6l-1 4v-2Zm44 1v-3l1 3-1 2v-2Zm-3 6v-1h2l-1 2h-1v-1Zm-15 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-26 1h1v1h-1v-1Zm49 1h1v1h-1v-1Zm-4 0-1-1 1-1v3l4 1h-4l-1-1Zm-21 1h1v1h-1v-1Zm-24 0h1v1h-1v-1Zm20 3h1l3 1h-5l1-1Zm-3 0h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm39 1-2-2h7v1l-4 2-1-2Zm-8 1h1v1h-1v-1Zm-9 1h1v1h-1v-1Zm-3 0 1-1 1 1-3 1 1-1Zm5 1v-1l2-1h1l-3 3v-1Zm-30 0v-2l1 3-1 1v-2Zm-3 2h1v1h-1v-1Zm40 1h1v1h-1v-1Zm-5 0v-1l1 1-1 1v-1Zm-46-10-2-2h-4l5 2 1 3 2-1-2-2Zm-8 1 2-3-5 4v2l1-1 2-2Zm9 4h-1v1h1v-1Zm-3-1v-3h-4l-1 3 1 3 4-1v-2Zm-3 5-2-1-2-2 3 4h4l-3-1Zm-12-1v2l1-1 1-10-4-1-2 4h4v1l-4 4 2-1v4l2-5v3Zm16 0h1v1h-1v-1Zm2 0-1-1-2 1 3 3 1-1-1-2Zm-12 1v-1h-2v3h2v-2Zm-12-6v-9h26v18H87v-9Zm81 12h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-23 0h1v1h-1v-1Zm-3 1h1v1h-1v-1Zm2 1h1v1h-1v-1Zm-11-1h-1v1h1v-1Zm-1 2v-1l-2 1 2-3 3 1v2l-3 1v-1Zm-15-39h-1v1h1v-1Zm41 5h-2l-5 1h10l-2-1Zm-1 2h-1v1h1v-1Zm-71 24h-1v1h1v-1Zm73 6-1-1v3l1-1v-1Zm-8 1-1-1-1 2h3l-1-1Zm4 2h-1l-2 1h5l-1-1Zm-4 0-1-1-1 2h3l-1-1Zm-42-1h1v1h-1v-1Zm13 0v-1l-2-1v2l-7 1 1-2 5 1-1-2-2 1-1-2-4 2-5-1 3 4h13v-2Zm-15 1v-1h-3v-3l-4 4h7Zm-12 0h1v1h-1v-1Zm-2 1h5l1-1-1-3h-3l2 2-4 1 1-3h-7l1-1h-2v3l2 3 4-1h1Zm35 5h-1v1h1v-1Zm-2 0v-1l-6 1v1h5l1-1Zm-10-1-1-1v3l1-1v-1Zm-2 0-1-1v3l1-1v-1Zm-16 1h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm68 1h1l-4-2-6 1 2 2 7-1Zm-16-1h1v1h-1v-1Zm6 1v-1l-7-1h-5v2l1-1 6 2h5v-1Zm-29 2v-1h-2l-1 2h3v-1Zm49 1v-1h-1l-1 2h1l1-1Zm-6 1v-1l-2-1v2h2Zm-39-1 1 1 3-2-4-1h-3v3l3-2v1Zm42 1-1-2v4l1-1v-1Zm-32 0v-3h-3v1l1 5h2v-3Zm24 4h-1v1h1v-1Zm-5-3h1v1h-1v-1Zm-10 0h1v1h-1v-1Zm5 3-1-1h4l-1-3 3 4 4-1-2-2h3v2l2-3-1-2h-18l4 2h-3l-3-3h-2l1 3 4 1v4h6l-1-1Zm5 4-1-1-1 2h3l-1-1Zm-19 2h-1v-2l-6-6h-11l-7-8h-5l-2 4H87l-1-4h-4v-39l1-3h10l2-3h3l-3 2 5-1 2-3v4h6v-2h2l-1 2 2 1v-4l2 3 1-3-3-1-15 1 2-3 15 1 4 6h6l1-1h41v-6l2 3v3l3 3h4l1-2v3l-16-1v2l7-1v3h-2v-2l-1 2h-14l2-2-3 2h-11l1-3h11l-20-1-1-2-1 2h-4l-3 2 1 2h-5l3-1 2-3H83l1 7v1l14-1 1-6v6l17 1H85l1 22h29l1-21v2h9v2h-8l-1 12 4 1h-4l-1 5h5l4 4-3 1h4v-5l1 4 3 1 5-1 1-4v5h2l-1-2 3 2h2l-1-2 5 2 1-1-1-4 5 1 1 3 2-3v2l3-3 2 1-1 4 3-2 3 2v-8l5-4-3 4v8l4-1-1-2h2l5-5v-15l-2 1 1-2-7-2h6l2 2v-10l1 1 1 27-8 8v10l-5 1-4 4h-5l-2 4h-3l-1-3h-2v3h-7l-3-2v2h-2l-1-1Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="m97 108 1-2h15l1 2H99l-3 1 1-1Zm29 1 5-5h32v2h-33v1l-4 3v-1Zm-28 7h1v1h-1v-1Zm28 1h1v1h-1v-1Zm12 0v-1h27l1 2-1 1-2-2-1 2-4-2v2h-3l-1-3v3h-4l-1-3-2 3-2-3-1 3h-7l1-2Zm-15 1v-1l2 1-2 1v-1Zm33 4 1 1h-2l1-1Zm-27-1v-2l2-2 5-1v3h-6l-1 4v-2Zm44 2h1v1h-1v-1Zm-58 1h1v1h-1v-1Zm56 3h1v1h-1v-1Zm2 3h1v1h-1v-1Zm-5-1v-2l1 3-1 1v-2Zm3 2v-1l1 2h-2l1-1Zm2 2h1v1h-1v-1Zm-4 1-1-1 4 1v1h-3v-1Zm-8 2h1v1h-1v-1Zm-11 0v-1l1 2h-2l1-1Zm4 2v-1l2-1h1l-3 3v-1Zm-30 0v-2l1 3-1 1v-2Zm32 2h1v1h-1v-1Zm-64-6v-1l2 1-2 1v-1Zm-2 1h1v1h-1v-1Zm3 4v2l2-5v-7l-4 1h-1l-1 8h2v3l2-5v3Zm15-4v-3h-4l-1 3 1 3 4-1v-2Zm-6 3-2-1v-4l5-3 4 1 1 4v5h-5l-2-2Zm9-1v-5l-2-1 1-2-8 1-3 3-1-1 1 5 6 4 4-1 1 2h1v-5Zm-12 4v-2l-2-1-1 3 2 1h1v-1Zm-12-7v-9h26v18H87v-9Zm67 13h1v1h-1v-1Zm-22 1h1v1h-1v-1Zm-9 1v-1l2 2h-3v-1h1Zm-18 0h1v1h-1v-1Zm10-39h-1v2l1-1v-1Zm-31 19-1-1v3l1-1v-1Zm9 17h-1v1h1v-1Zm75 5h-1v1h1v-1Zm-83-4h1v1h-1v-1Zm12 2v-3h-3l-1 2-3-2-2 1-4-2v-7l-1 2 1 12h13v-3Zm64 7v-1h-2v2h1l1-1Zm-28 0h-1v1h1v-1Zm-5 0 2-1h-6l-6 2h9l1-1Zm-14 0v-1h-3l-1 2h4v-1Zm-18 0h-1v1h1v-1Zm-6 0h-1v1h1v-1Zm76 0-1-1h-2l2 1-1 2 2-1-1-1h1Zm-68 0-1-1v3l1-1v-1Zm25 4v1h3v-2h-1l-5-1v3l3-2v1Zm-4 0v1-3h-3l-1 3 3-2 1 1Zm16 1h-1v1h1v-1Zm32 0h1v-2l-4 1v3l1-2h2Zm-34 0v-3h-3v5l1 1h2v-3Zm15-5h1v1h-1v-1Zm6 6h1v1h-1v-1Zm4 3v-3h3l1-2-3-3 1 3-7-1-1-1h6v-3l-22-1v3l4 1h11l1 1-16-1 1 5h4v3h17v-1Zm-25 6h-1v-2l-6-6h-11l-7-8h-5l-2 4H87l-1-4h-4v-39l1-3h10l4-4-2 3h6l1-4v4h9v-3l1 3 3-4 1 5h7l1-1h41v-5l2 1v4l3 3h6-46l-2-3-1 3-7-1 1 5h-5l3-1v-4l-36 1v12l2-5h30l-30 1 1 21 29 1v-19h10v1h-8l-1 13 4 1h-4v6l-3-1-4 2-3-2-3 2 1-2h-2l-3 2 2-3-3 2v5l3-2h1l-1 1 19 1 1-6v5h4l1-4v4l8-1 1-5v6h20l-9-1 1-3h-2l1-1 3 1-2 2h10l1-3v4l-3 1 8-1v-7l5-4-4 5v7l5-1 6-7v-15l-2 1 1-2-6-2h5l2 3 1-11v29l-7 6v11l-5 1-4 4h-5l-2 5-4-2v-2l4 1-3-2-3 1v3h-7l-3-2v2h-2l-2-1Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M98 107v-1h15l1 2H98v-1Zm-2 1h1v1h-1v-1Zm30 2v-1l5-5h32v2h-32l-1 1-4 3Zm-31 0h1v1h-1v-1Zm37 6h1v1h-1v-1Zm33 2-1-1h2v2h-1v-1Zm-5-1v-1l3 1v2h-3v-2Zm-4 1-1-1 2-1 1 1v2l-2-1Zm-6 0v-2h4v2l-4 1v-2Zm-12-1v-1h11l-2 3-2-2-2 3-1-3-3 2h-2l1-1Zm-3 1-1-1 1-1 1 1v2l-1-1Zm-3 0h1v1h-1v-1Zm-2 0v-1l1 1-1 1v-1Zm-13 0h2l1-2 1 3h-5l1-1Zm12 3v-1l1 1-1 1v-1Zm-35 1h7l15 1H86l8-1Zm75 3h2l3 1h-6l2-1Zm-46 1h1l1 1h-3l1-1Zm48 1h1v1h-1v-1Zm2 3h1v1h-1v-1Zm-5 0v-1l1 1-1 1v-1Zm3 1v-1l1 2h-2l1-1Zm-1 3v-1l1 2h-2l1-1Zm-9 2h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-32 2v-2l1 3-1 1v-2Zm-16-11h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm-12 0h-1v1h1v-1Zm6 2h-1v1h1v-1Zm-7 6h1v1h-1v-1Zm3 4v2l2-3v-10l-2 1-3 1-2 2 1 5 3 4 1-4v2Zm9-5h-1v1h1v-1Zm6 2v-2l-2-2-3 1-1 5 2-1v2h3l1-3Zm-5 3-2-2-2-5 1-1v2l7-4v3l2-1 2 4-3 5h-3l-2-1Zm-4 2v-1l4 2-1-2 5 1 3-2-1 3h2v-10l-2-1 1-1-6-1-4 2-2-2 1 2-3 1v3l2-3 1 3-1 1 5 4h-2l-4-2-1 3 1 1h2v-1Zm-12-7v-9h26v18H87v-9Zm70 13h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-7 0h1v1h-1v-1Zm-42 2h1v1h-1v-1Zm45 22-1-1v-1l3 2 2-1-1 2h-2l-1-1Zm-66-37h-1v1h1v-1Zm0 2h-1v1h1v-1Zm0 17h-1v1h1v-1Zm45 2v-1h-19v3l19-1v-1Zm-41 1h-1v1h1v-1Zm78 0 1-2-4 1v3h2l1-2Zm-65 1v-1h-2v2h1l1-1Zm-5 0v-1h-4v2l4-1Zm-5 0v-1h-2v2h2v-1Zm24 2h1v1h-1v-1Zm13 1-1-2h-14v2l3 1 3-3-2 3h2v-3l1 3 3-2v2h4v2l1-2v-1Zm18-2h2l3 1h-6l2-1Zm-11 2h1v1h-1v-1Zm4 2h1v1h-1v-1Zm21 3 1-2-3 2v-3l4-1-1-3-3 1 3-3v-2l-5 1 1-2-5 1-1 1h-4v-3l-2 3-3-2v2l-3-2-4 2-3-1v3h-2v8l3-1 1-8 7 1-1 2-2-1-4 1v4l3-1v2h3l1 2h18l1-1Zm-23 4v-1h-3v2h2l1-1Zm4 0v-1h-3l1 3h1l1-2Zm-8 2h-1v-2l-6-7-10 1-8-8h-5l-2 4h-3l-1-4v4H87l-1-4h-4v-40l2-2 17-1 1-4v5h7l6-1-1-3 2 1v2h49v-5l2 1v4l3 3h6-46l-2-3-1 2H93l-10 1 1 16 1-9 1 22 29 1 1-19h6l-2 1h-3l-1 13h4l-4 1v4l-27 1-5-1v-8 14l13 1 1-4v4h2l1-3v3h19l1-6v6l5-1h8l1-4v4l20-1-9-1h13l-4 2h8v-8l5-4-4 4v9h4l7-7v-18l-2 2 2-3 1-10v30l-7 6v6l-3 1h-2v4l3-2h2v2l-5 1-4 4h-17l3 3-1-3 2 2v2l-7-1-3-1v2h-2l-1-1Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="M148 104h1v1h-1v-1Zm11 1v-1h2l3 2h-5v-1Zm-5 1v-1l3-1 1 2h-4Zm-4 0v-1l3-1-1 2h-2v-1Zm-8-1-1-1h6l-1 2h-2l-2-1Zm-13 1v-1l5-1 6 2-11 1v-1Zm-21 1v-1h5l-1 1-5 1 1-1Zm-4 0 2 1h-3v-1h1Zm-6 0h1v1h-1v-1Zm-2 1h1v1h-1v-1Zm30 1v-1l2 1-2 1v-1Zm32 4 1 1h-2l1-1Zm-3 0v-1h1l-1 2h-1l1-1Zm-8 0h2l5 1h-9l2-1Zm-9 0-1-1h6l-1 2h-4v-1Zm-5 0h1l3 1h-5l1-1Zm-16 1v-1l8-1v2h-8v-1Zm-6-1h4l1-4v5h-8l3-1Zm-21 0 2 1h-3v-1h1Zm39 1v-1h2v2h-2v-1Zm-3 0h1v1h-1v-1Zm-29 0h-5l1-2 2 1h11v1h-9Zm-13 0-1-1h3v2l-2-1Zm88 1h1l3 1h-5l1-1Zm-5 0-2-2-4 2h-1v-2h4l1-3h2l-1 3h3l1 3-3-2Zm-10 1h1v1h-1v-1Zm4 1-1-1h2v2h-1v-1Zm-8 0-1-1h2v2h-1v-1Zm-13 0-1-1 4 1 1 1-4-1Zm-5 0 1 1h-2l1-1Zm-16 1v-1l2 1-2 1v-1Zm-3 0h1v1h-1v-1Zm-34 0v-2l1 3-1 1v-2Zm93 1v-3l1 3-1 2v-2Zm0 3h1v1h-1v-1Zm-61 0 2 1h-3v-1h1Zm-7 0h1v1h-1v-1Zm-4 0 2 1h-3v-1h1Zm-3 0 2 1h-3v-1h1Zm69 3h1l2 1h-4l1-1Zm-45 1h1v1h-1v-1Zm-6 0h1v1h-1v-1Zm-36-2v-4l1 4-1 3v-3Zm89 3h1v1h-1v-1Zm-3 2h1v1h-1v-1Zm-62 1v-1l2 2h-3v-1h1Zm-5 0v-1h1l-1 2h-1l1-1Zm2 1h1v1h-1v-1Zm-21 0v-1l2 1-2 1v-1Zm19 1h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm77-3v-6 11-5Zm-94 4h1v1h-1v-1Zm87 1h1v1h-1v-1Zm-67 0h1v1h-1v-1Zm73 1h1v1h-1v-1Zm-67 0v-1l2 1-2 1v-1Zm-13 1h1v1h-1v-1Zm2 0v-2l1 3-1 1v-2Zm-5 1h1v1h-1v-1Zm83 1v-1l1 1-1 1v-1Zm-51 1h1v1h-1v-1Zm-19 0h2l3-3-3 4h-3l1-1Zm-23-1v-3l1 3-1 2v-2Zm29 4 1-1-2-3 2 1v-9l-2-1 1-2-3 1 4 4-6-4-1 1 1-2 2 1v-2h-5l1 2-5-1-3 2 2 4-3-3 1-2-3-1h-4v2l6-1-5 2-2-1 1 3-1 2v-9h25v18h-4l1-1Zm-5 0-1-1h2v2h-1v-1Zm-5 0-2-1v-4l3 2 1-1v3l-3-1 2 3-2-1h1Zm-4 0h1v1h-1v-1Zm-1-3h-1v1h1v-1Zm-4 1 1-2v4h2l-1-3 1-1 2 1-2 4h-4l1-3Zm-2 0v-1h-1l-1 2h1l1-1Zm-3 1v-2l3-1h-3v-3l4 4-2 4h-2v-2Zm-3 2h1v1h-1v-1Zm31 1h1v1h-1v-1Zm48 1v-1l1 1-1 1v-1Zm-51 0v-1l2 2h-3v-1h1Zm-3 0h1v1h-1v-1Zm-16 0h16-21 5Zm-11-1v-3l1 4-1 2v-3Zm92 3 1-2v-6l1 4-1 5h-2l1-1Zm-17 2h1v1h-1v-1Zm-4 0v-1l1 2h-2l1-1Zm-4 0h1v1h-1v-1Zm13 6h1v1h-1v-1Zm-66-2h-1v1h1v-1Zm-2 3h-7l-2-2 6 1-2-1-6-1 1 2h-2v-8l2 4 21 1 16-1 4 2v-2h10l-1 2h-2v4l-2-1v-2h-20v3l-1-3h-8l2 2h-9Zm66 1v-1l1 2h-2l1-1Zm-34 0v-1l2 2h-3v-1h1Zm-8 0h1v1h-1v-1Zm-6 1v-1l5-1-1 2h-4v-1Zm-16-1h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-8 0h1v1h-1v-1Zm12 1v-1l2 1-2 1v-1Zm-7 0h1v1h-1v-1Zm72 1v-1h4v-4h-6l-2-1h-23v-2h26l2-1-1 2h5l4-4v2l-4 2 1 4-2 3-4 1v-1Zm-29-1v-1h1l1 2-3 1v-2Zm-22 1h1v1h-1v-1Zm21 3v-1l1 1-1 1v-1Zm-9 0v-1l2 2h-3v-1h1Zm-6 1v-1l4-1v2h-4Zm-3-1-1-1v-1h3l-1 3h-1v-1Zm13 0 1-1-1-4h2v7h-4l1-2Zm10 3v-1h2l1 2-4 1 1-2Zm-6 4v-1l-4-2 2-2 4 1h2v3l-2-3v6h-2v-2Zm21 2v-1h1l-1 2h-1l1-1Zm-3 0-1-2 2 2v1h-1v-1Zm-4 0v-1h1v2h-2l1-1Zm3-4h-1v1h1v-1Zm-7 3v-4l17 1 1-2-2-2h4l1-2 2 2 3 1h-5l-3 4-5-1v1h-8l-4-1 1 5h-1l-1-2Zm-7 1 3-3 3 4h-1l-3-2v2h-2v-1Z" style="fill:';
    string private constant PART_11 = '"/>';
    string private constant COLOR_1 = "hsl(220, 3%, 52%)";
    string private constant COLOR_2 = "hsl(222, 0%, 63%)";
    string private constant COLOR_3 = "hsl(194, 59%, 63%)";
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
