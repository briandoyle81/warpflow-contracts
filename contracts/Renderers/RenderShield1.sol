// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderShield1 {
    string private constant PART_1 = '<path d="M85 116h81v35H85z" style="fill:';
    string private constant PART_2 =
        '"/><path d="m139 129-2-2v2h2Zm-2 2v-1h-1v1h1Zm-39 1v-1h-4v2h4v-1Zm55 10v-1h-1v1h1Zm-11 2v-1l4-3 3-6 4 2v-1l-2-2 2-5h-2l-1 4-4 1-2-1 1-10-2 1-1 8 3 6-1 2-5-2-4-4v2l6 5-1 6 2-1v-1Zm6 7v-1h-1v1h1Zm-22 12-2-2h-12l-8-8h-3l-3 3H84v-3h-5v-39l10-2 5-5h12l5 5h8l8-8h37l4 2v3h2l1-2h6l7 7v28l-8 7v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M98 132v-1h-4v2h4v-1Zm43 3v-1h1v1h-1Zm-3-1 1-1-3 1 2-5h1l-1 2h2v4h-2v-1Zm11 4v-1h2l1 2h-3v-1Zm-5 8v-1h-2l1-2 3 1 3 3-1-5h2l6 1-2-3-2-10 2-2-1-1-5 1 1 2-2 1v-2l-2 1v-1l3-3-4-4-4 6-3-1-2 7-2-4v3l3 3v2l-4-1 1 2 6-1-3 2 3 3-1 3-4-1v1l4 2 6-1v-1Zm4 5v-1h-1v1h1Zm-22 12-2-2h-12l-8-8h-3l-3 3H84v-3h-5v-39l10-2 5-5h12l5 5h8l8-8h37l4 2v3h2l1-2h6l7 7v28l-8 7v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="m164 107-7-1v1h7Zm-8-1v-1l-5 1 1-2-7 2-16-1 3 2h23v-1Zm-27 3-2-2 1 2h1Zm-28 0-1-1-3 1h5-1Zm26 1v-1h-1v1h1Zm53 3v-1h-8v2l8-1Zm-65 2v-1h-1v1h1Zm26 1-1-1-1 1h2-1 1Zm-32-1-2-1h-1v2h4l-1-1Zm-7 0v-1l-4 1 1 1 3-1Zm-7 0 1-1h-1l-1 2h1v-1Zm10 1-1-1v3l1-2h-1Zm28 1 1-2h-1l-3 2v1h1l1-1Zm25 0 2-2h-1l-3 4h1l1-2Zm-30 1 1-1h-1l-1 2h1v-1Zm51 2-2-1-6 1h10-2Zm-42 0v-1h-1v1h1Zm-50-4h3l-1-2-4 1-1 2v4l1-5h2Zm41 5v-1h-1v1h1Zm36 1v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm-36 0v-1h-1v1h1Zm-2 0-4-1v1h4Zm57 1v-1h-1v1h1Zm-52 2v-1h-1v1h1Zm-36-1-1-1v3l1-2h-1Zm93 1h2l-5-1-1 4 2-2 2-1Zm-5 1-1-1v3l1-2h-1Zm-60 1v-1h-1v1h1Zm-16 1-1-1-2 1h3Zm76 1v-1h-1v1h1Zm-6 4-1-1-3 1 4 1v-1Zm-46-3-1-1v5l1-3v-1Zm-23 2v-1h-4v2h4v-1Zm43 3v-1h1v1h-1Zm-3-1 1-1-3 1 2-5h1l-1 2h2v4h-2v-1Zm11 4v-1h2l1 2h-3v-1Zm-5 8v-1h-2l1-2 3 1 3 3-1-5h2l6 1-2-3-2-10 2-2-1-1-5 1 1 2-2 1v-2l-2 1v-1l3-3-4-4-4 6-3-1-2 7-2-4v3l3 3v2l-4-1 1 2 6-1-3 2 3 3-1 3-4-1v1l4 2 6-1v-1Zm4 5v-1h-1v1h1Zm-9 5v-1h-1v1h1Zm-13 7-2-2h-12l-8-8h-4l-2 3H84l-1-4h-4v-38h4l1-2h5l5-6h13l4 5h9l7-8h38l2 3-2 2 3-2v4l4-4h5l7 8v27l-8 8v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="m164 107-7-1v1h7Zm-8-1v-1l-5 1 1-2-7 2-16-1 3 2h23v-1Zm-27 3-2-2 1 2h1Zm-28 0-1-1-3 1h5-1Zm26 1v-1h-1v1h1Zm53 3v-1h-8v2l8-1Zm-65 2v-1h-1v1h1Zm26 1-1-1-1 1h2-1 1Zm-32-1-2-1h-1v2h4l-1-1Zm-7 0v-1l-4 1 1 1 3-1Zm-7 0 1-1h-1l-1 2h1v-1Zm10 1-1-1v3l1-2h-1Zm28 1 1-2h-1l-3 2v1h1l1-1Zm25 0 2-2h-1l-3 4h1l1-2Zm-30 1 1-1h-1l-1 2h1v-1Zm51 2-2-1-6 1h10-2Zm-42 0v-1h-1v1h1Zm-50-4h3l-1-2-4 1-1 2v4l1-5h2Zm41 5v-1h-1v1h1Zm36 1v-1h-1v1h1Zm-10 0v-1h-1v1h1Zm-36 0v-1h-1v1h1Zm-2 0-4-1v1h4Zm57 1v-1h-1v1h1Zm-52 2v-1h-1v1h1Zm-36-1-1-1v3l1-2h-1Zm93 1h2l-5-1-1 4 2-2 2-1Zm-5 1-1-1v3l1-2h-1Zm-60 1v-1h-1v1h1Zm-16 1-1-1-2 1h3Zm76 1v-1h-1v1h1Zm-6 4-1-1-3 1 4 1v-1Zm-46-3-1-1v5l1-3v-1Zm-23 3v-2h-4v4l3-2v2h1v-2Zm58 13v-1h-1v1h1Zm-23 1v-1h-1v1h1Zm21 1v-1h-1v1h1Zm0-16 1-1 1 1h-3 1Zm-5 16 2-1 5-4 2-8-1-5h-4l3-1-5-6v2l-3-1 1-1-8-1 1 1h-2l-6 6v-2l-3 3v2h-2v4l2 8 7 5h9l2-1Zm-14 1v-1h-1v1h1Zm13 2-1-1-1 1h2-1 1Zm-7 0-1-1-3 1 4 1v-1Zm-2 5v-1h-1v1h1Zm-13 7-2-2h-12l-8-8h-4l-2 3H84l-1-4h-4v-38h4l1-2h5l5-6h13l4 5h9l7-8h38l2 3-2 2 3-2v4l4-4h5l7 8v27l-8 8v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="M162 105v-1h-1v1h1Zm-34 3v-1h1v1h-1Zm4-1h2l3-2-1 3 21-1v1l7-1-5-1-1-1-29-1 1 4-3-3 1 5 2-3h2Zm-28 2-2-1-5 1h8-1Zm-7 0v-1h-1v1h1Zm79 1v-1h-1v1h1Zm-34 0-1-1-1 1h2-1 1Zm-15 0v-1h-1v1h1Zm33 0-1-1v3l1-2h-1Zm-56 1v-1h-1v1h1Zm14 2v-1h-1v1h1Zm59 1h4v-2h-9v4l2-3 3 1Zm-25 2-2-1-5 1h9-2Zm-7 0-1-1-3 1h4Zm-30-1-1-1v3l1-2h-1Zm-2 1v-1h-1v1h1Zm-3-1v-1h-4v2h4v-1Zm32 3v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm28 1-1-1-1 1h2-1 1Zm-11-2-1-1 3 1 3-2h-7l2 3-2 2 3-2-1-1Zm-12 2-1-1-1 1h2-1 1Zm20-2-1-2v6l1-3-1-2Zm-14 3v-1h-1v1h1Zm-14 0v-1h-1v1h1Zm-44 0v-1h-1v1h1Zm-2-4h7l7 1v-2H84v6l1-4 6-1Zm90 4h1l-10-1v2l7-1h2Zm-51-1 3-2 8-1-10-1-6 5 1 1h2l2-2Zm-7 2-1-1-2 1h3Zm31 1v-1h-1v1h1Zm-20-1 1-1h-1l-1 2h1v-1Zm-16 0v-1h-6v2h6v-1Zm38 2v-1h-1v1h1Zm-49 1v-1h-1v1h1Zm-3 0v-1h-1v1h1Zm-5 0-2-1-6 1h10-2Zm-9 0-1-1-3 1h5-1Zm72-1 2-2h-1l-3 4h1l1-2Zm-41 2v-1h-1v1h1Zm44 3v-1h-1v1h1Zm13-3h2l-5-1-1 3v3l2-4 2-1Zm-82 3-1-1-2 2 4-1h-1Zm-11-3-1-2v7l1-4-1-1Zm93 5 1 1v-4h-3v4l1-3 1 2Zm-5-6-1-2v9l1-5v-2Zm-57 3h2l-6-1v5l1-4h3Zm-3 5v-1h-1v1h1Zm54 1-1-1-3 1 4 1v-1Zm-82 0v-1h-1v1h1Zm36-3v-4h-1v8h1v-4Zm-23 2v-1h-4v4l3-2v3l2-3-1-1Zm69 6v-1h-1v1h1Zm-82-1-1-2v6l1-3-1-2Zm21 4v-1h-1v1h1Zm15-3-1-2v7l1-4-1-2Zm-36 5v-1h-1v1h1Zm30 1-1-1-2 1h3Zm41 2v-1h-1v1h1Zm-2 2v-1h-1v1h1Zm-21-1-1-1v3l1-2h-1Zm21-15 1-1 1 1h-3 1Zm-5 16 2-1 5-4 2-8-1-5h-4l3-1-5-6v2l-3-1 1-1-8-1 1 1h-2l-6 6v-2l-3 3v2h-2v4l2 8 7 5h9l2-1Zm-14 1v-1h-1v1h1Zm13 2-1-1-1 1h2-1 1Zm-7 0-1-1-3 1 4 1v-1Zm-2 5v-1h-1v1h1Zm15 1v-1h-1v1h1Zm-28 6-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-38h4l1-2h5l5-6h13l4 5h9l7-8h38l2 3-2 2 3-2v4l4-4h5l7 8v27l-8 8v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="M167 107v-1h-2l1 2h1v-1Zm9 3 1-1-4-1v2h3Zm-82 0v-1h-1v1h1Zm78 0-1-1v3l1-2h-1Zm-8 1v-1h-1v1h1Zm-2-5v-1h1v1h-1Zm-33 0v-1h1v1h-1Zm24 4v-1h1v1h-1Zm-4 0-3-3h3l2 4h5l-1-5h2v6l1-5 6 2v-5h-36l-5 5 6-2-1 2 2 2v-4h4l3-2-1 2 2 1 7-1-1 3h-5l1-2-2 1v2h11v-1Zm11 0-1-1v4l1-1v-2Zm-33 0-1-1v2l1 1 1-1-1-1Zm-25 0 1-1v4l2-2v-3h-9v1l2 3h3l1-2Zm23 5v-1l-6 1 6 1v-1Zm50-1v1l3-2h2l-1 3h2v-4h-9v6l2-5v1Zm-47 3v-1h-1v1h1Zm-11-2h1l-2-1 2-2-4 1v5l1-3h2Zm-4 0-1-1v4l1-1v-2Zm9 3v-1h-1v1h1Zm-40 0-1-1-2 1h3Zm27 0 2-2v-2h-5v6h1l2-2Zm72 2 1-1h-10v2h9v-1Zm-84-3v-1h1v1h-1Zm3 1v-1l1 1-1 2v-2Zm-12 1-1-1-2-2h4v4h4l-1-1 2-3v5l2-3v2h6v-2l1 2 2-1v-5H85l-1 2v5l4-1-1-1Zm30 2v-1h-6v2h6v-1Zm-7 0-1-1v3l1-2h-1Zm6 3 1-1h-1l-1 2h1v-1Zm41 2v-1h-1v1h1Zm-70 0v-1h-1v1h1Zm72 2v-1h-1v1h1Zm-31-1v-1h-1l-1 2h2v-1Zm-33 1-1-1-2 2 4-1h-1Zm82 2 1 2v-5h-3v5l1-4 1 2Zm-10-1v-2h-7l7-2v-7h-4l3-2h-3l3-2h-3v8l2-2 1 3-4-2-2 3v4l3 1-2 1 2 1h4v-2Zm-41 1-1-1v3l1-2h-1Zm31-10v-1h1v1h-1Zm-33 6v-1l2 1-1-5h1l3 3-2-4h4l-1-1 4-3 3 2-2 2h-3l-3 6 7-7 7-1-1 2 4-2 8 6 1-1-9-6 7 1v2l3 3 4 3-1-2 1-6 2 2v-4l-33-1-6 6h-4v3l3-3 1 2h-2l1 2h-4l5 3-1 2 1 2 1-4v-1Zm56 6v-1h-1v1h1Zm-91 0-1-1-2 1h3Zm34 1-1-1v3l1-2h-1Zm-2 1v-2l1-4h-2l1-2h-2v8h2v-1Zm-32 0v-1h-1v1h1Zm85-2-1-2v6l1-3-1-2Zm-77 0-2-2-3 3 1 1 3-1v3l2-3-1-1Zm82 4-1-1-1 1h2-1 1Zm-54-1-1-1v4l1-2v-1Zm42 2v-1h-4v-2l3-2h-2l-3-1 1 7h4l1-1Zm-61 1v-1h-1v1h1Zm69 0v-1h-2v2h2v-1Zm-53-1v-1l-1 1 1 3 1-3h-1Zm51-8v1l2-5h4l1 3v-4l-3 1-3-3-2 2h3l-3 4-1-6v20l1-14 1 1Zm-61 1v-3l1 3-1 3v-3Zm0 4 3-2 1 2v1h-4v-1Zm0 6v-1l2 1v1h-2v-1Zm3 1v-1l2 3v-3l-5-1v-3h4l1 3v-13h-6v15l1 1h3v-1Zm-11 1 1-1H96l-4 1h13v-1Zm-14 0-1-1-3 1 4 1v-1Zm4-18h10v11l1 1v-13l-22-1v22l1-20h10Zm9 20v-1h-1v1h1Zm-4 0-2-1-6 1h10-2Zm-10 0-1-1-3 1h5-1Zm66 1 1-1h-1l-1 2h1v-1Zm-26 1-2-2 1 2h1Zm-4-3-6-7v8h2l-1-3h1l3 2-3 4 4-3Zm-5 3v-1h-1v1h1Zm-6-2h1l-1 3 2-1 1-3h-6v4l1-3h2Zm39 4v-1h-1v1h1Zm0-16 1-1 1 1h-3 1Zm-5 16 2-1 5-4 2-8-1-5h-4l3-1-5-6v2l-3-1 1-1-8-1 1 1h-2l-6 6v-2l-3 3v2h-2v4l2 8 7 5h9l2-1Zm-15 0-2-1 1 2h2l-1-1Zm-6 1-3-2 2 2h1Zm31 2v-1h-1v1h1Zm-18 0-1-1-3 1 4 1v-1Zm-11 0-1-1-1 1h2Zm18 0v-1h-2l1 2h1v-1Zm10 2v-1h-1v1h1Zm-2 0-1-1-3 1 4 1v-1Zm-24 0-1-1-1 1h2-1 1Zm7 3v-1h-1v1h1Zm21 3v-1h-1v1h1Zm-27-1v-2h-4v2l3-1v2h1v-1Zm24 1-1-1v3l1-2h-1Zm-3 1-1-1 1-3-3 2-7 1 1-1h-8v2h18l-1-1Zm-19-1 1-2h-2v3h1v-1Zm-9 4-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-38h4l1-2h5l5-6h13l4 5h9l7-8h38l3 4v3l4-3h5l3 2 3 4 1 28-8 8v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M167 107v-1h-2l1 2h1v-1Zm9 3 1-1-4-1v2h3Zm-82 0v-1h-1v1h1Zm78 0-1-1v3l1-2h-1Zm-8 1v-1h-1v1h1Zm-2-5v-1h1v1h-1Zm-33 0v-1h1v1h-1Zm24 4v-1h1v1h-1Zm-4 0-3-3h3l2 4h5l-1-5h2v6l1-5 6 2v-5h-36l-5 5 6-2-1 2 2 2v-4h4l3-2-1 2 2 1 7-1-1 3h-5l1-2-2 1v2h11v-1Zm11 0-1-1v4l1-1v-2Zm-33 0-1-1v2l1 1 1-1-1-1Zm-25 0 1-1v4l2-2v-3h-9v1l2 3h3l1-2Zm23 5v-1l-6 1 6 1v-1Zm50-1v1l3-2h2l-1 3h2v-4h-9v6l2-5v1Zm-47 3v-1h-1v1h1Zm-11-2h1l-2-1 2-2-4 1v5l1-3h2Zm-4 0-1-1v4l1-1v-2Zm9 3v-1h-1v1h1Zm-40 0-1-1-2 1h3Zm27 0 2-2v-2h-5v6h1l2-2Zm72 2 1-1h-10v2h9v-1Zm-84-3v-1h1v1h-1Zm3 1v-1l1 1-1 2v-2Zm-12 1-1-1-2-2h4v4h4l-1-1 2-3v5l2-3v2h6v-2l1 2 2-1v-5H85l-1 2v5l4-1-1-1Zm30 2v-1h-6v2h6v-1Zm-7 0-1-1v3l1-2h-1Zm6 3 1-1h-1l-1 2h1v-1Zm41 2v-1h-1v1h1Zm-70 0v-1h-1v1h1Zm72 2v-1h-1v1h1Zm-31-1v-1h-1l-1 2h2v-1Zm-33 1-1-1-2 2 4-1h-1Zm82 2 1 2v-5h-3v5l1-4 1 2Zm-10-1v-2h-7l7-2v-7h-4l3-2h-3l3-2h-3v8l2-2 1 3-4-2-2 3v4l3 1-2 1 2 1h4v-2Zm-41 1-1-1v3l1-2h-1Zm31-10v-1h1v1h-1Zm-33 6v-1l2 1-1-5h1l3 3-2-4h4l-1-1 4-3 3 2-2 2h-3l-3 6 7-7 7-1-1 2 4-2 8 6 1-1-9-6 7 1v2l3 3 4 3-1-2 1-6 2 2v-4l-33-1-6 6h-4v3l3-3 1 2h-2l1 2h-4l5 3-1 2 1 2 1-4v-1Zm56 6v-1h-1v1h1Zm-91 0-1-1-2 1h3Zm34 1-1-1v3l1-2h-1Zm-2 1v-2l1-4h-2l1-2h-2v8h2v-1Zm-32 0v-1h-1v1h1Zm85-2-1-2v6l1-3-1-2Zm-77 2 1-1-3-3-3 3 2 2h3l1-1Zm82 2-1-1-1 1h2-1 1Zm-54-1-1-1v4l1-2v-1Zm42 2v-1h-4v-2l3-2h-2l-3-1 1 7h4l1-1Zm-61 1v-1h-1v1h1Zm69 0v-1h-2v2h2v-1Zm-53-1v-1l-1 1 1 3 1-3h-1Zm51-8v1l2-5h4l1 3v-4l-3 1-3-3-2 2h3l-3 4-1-6v20l1-14 1 1Zm-61 1v-3l1 3-1 3v-3Zm0 4 3-2 1 2v1h-4v-1Zm0 6v-1l2 1v1h-2v-1Zm3 1v-1l2 3v-3l-5-1v-3h4l1 3v-13h-6v15l1 1h3v-1Zm-11 1 1-1H96l-4 1h13v-1Zm-14 0-1-1-3 1 4 1v-1Zm4-18h10v11l1 1v-13l-22-1v22l1-20h10Zm9 20v-1h-1v1h1Zm-4 0-2-1-6 1h10-2Zm-10 0-1-1-3 1h5-1Zm36-1-6-7v8h2l-1-3h1l3 2-3 4 4-3Zm-5 3v-1h-1v1h1Zm-6-2h1l-1 3 2-1 1-3h-6v4l1-3h2Zm13 5-3-2 2 2h1Zm31 2v-1h-1v1h1Zm-29 0-1-1-1 1h2Zm4-3v-1h1v1h-1Zm18 1 4-2-1-3 2 1 2-5-1-8-1-5-2 2 1-2-5-4-7-3-8 2-4 3-4 8 1 9 1 4-2-2 1 2 2-1v2l5 4 6 1h7l3-3Zm6 4v-1h-1v1h1Zm-2 0-1-1-3 1 4 1v-1Zm-24 0-1-1-1 1h2-1 1Zm7 3v-1h-1v1h1Zm21 3v-1h-1v1h1Zm-27-1v-2h-4v2l3-1v2h1v-1Zm24 1-1-1v3l1-2h-1Zm-3 1-1-1 1-3-3 2-7 1 1-1h-8v2h18l-1-1Zm-19-1 1-2h-2v3h1v-1Zm-9 4-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-38h4l1-2h5l5-6h13l4 5h9l7-8h38l3 4v3l4-3h5l3 2 3 4 1 28-8 8v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="m107 109-1-1v3l1-2h-1Zm65 0-1-1v4l1-1v-2Zm-8-3v-1h1v1h-1Zm-32 4v-1h1v1h-1Zm24 0v-3l2 6v-5l1 5 4-4v2l4 1v-5l-3-3h-36l-4 3 3 1-1 2 1 2h29v-3Zm-51 0v-2h-9v4h9v-2Zm71 0v-1h1v1h-1Zm1 7v-1h1l3 3v-7h-5l3-1-1-3h-5v3l2-1 1 2h-4v6h6l-1-1Zm-53 0 1-1v-2l-6 1 5 1h-3v2h1l2-1Zm-8-3v-1h1v1h-1Zm2 2 1-2-2-2-3 1v5l4-1v-1Zm-36 2v-1h-2v2h2v-1Zm26 1v-1l2 1 1-3 2 3v-5h-7v6h2v-1Zm-21 1 2-2v3h16v-7H85l-2 3 1 4h2l1-1Zm32 1v-1h-9v2h9v-1Zm36 1-1-2h-2l3 4h2l-2-2Zm-37 3v-1h-6v1h6Zm52 4-1-1v3l1-2h-1Zm11 0-1-1v5l1-3v-1Zm-4 0v-1h1v1h-1Zm2 1v-3h-3v5l2-2v2h1v-2Zm-19 2v-1h-1v1h1Zm10 8v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-7-2v-4l-2 3 1 4h1v-4Zm-1 5v-1h-1v1h1Zm13-11v-2l1 3-1 1v-2Zm0 6v-3h3l-2 3v2l3-2-1 2h-3v-2Zm0 5v-1l3 2 5-4v-4l-2-3-4 1v-8l-2 1v-3h2v3l5-2v2h2l-1-4h-8v-2h9v-2h-10v25h2l-1-1Zm-60-9v-1h1v1h-1Zm-1 2v6h6l1-4v-11l-6-1-3 3v16l2-16v7Zm-24-10-1-1v3l1-2h-1Zm8 2-1-1-2 2 4-1h-1Zm-6 4-1-1-2 1h3Zm8 2 1-1-3-3-3 3 2 2h3l1-1Zm-8 0-1-1v5l1-3v-1Zm9 3 2-2v-3l-3 4-3 2-3-2 2 2h3l2-1Zm-11 1-1-1v3l1-2h-1Zm-3 2v-15h20l-1 16-18 1-1-2Zm22 3 1-1h-2v-2l2-3h-2l1-15H84v22h23l1-1Zm43-24v-1h1v1h-1Zm-10 0v-1h1v1h-1Zm25 2v-1h1v1h-1Zm-36 3 3-3v2l-3 1Zm36 3 1-1 1 1h-4 2Zm-1 17v-1l1 1-1 2v-2Zm2 1 1-2-2-6 3 1v-2h-5l5-2v-2h-5l5-1v-13h-3l3-1v-3h-38l-6 6h-4v5l2 1h-2v9h4v-4l4-7-2-1v-2h2l1 4-3 4v2l6-8 5-4-4 1 1-3 6 3 2-1 5-1 3 2 3-1 6 6 4-5v-4l1 4-4 4 1 4-4-5v3l3 4 2-1 1 7-3 10h6v-2Zm-48 0 1-2h-7v3h6v-1Zm-7 1v-1h-1v1h1Zm15 5v-1h-1v1h1Zm-37 0-3-1-2-3v4h8-3Zm71 1 1-2h-4v3h2l1-1Zm-5 1-1-1-3 1h5-1Zm-26-8v-1l1-1 1 3h-1l-1-1Zm5 3v-1h1v1h-1Zm14 5v-1l8-5-1-3 2 1 2-5-1-8-1-5-2 2 1-2-5-4-7-3-8 2-4 3-4 8 1 10-2-2-2-9 1 9 5 8 1-1 6 3 8 1v1h2Zm-7 0-1-1-1 1h2-1 1Zm-17-7v-1h1v1h-1Zm-3-1v-1l2 1v1h-2v-1Zm9 5-4-3v-1l-2-10h-4v11l5 1 5 5h3l-3-3Zm-36 4v-1h-1v1h1Zm46 2-1-1-1 1h2-1 1Zm-17 1-1-1-3 1 4 1v-1Zm-5 0v-1h-1v1h1Zm50 0-1-1v5l1-3v-1Zm-5 1v-3h-2v3l-2-2v4h4v-2Zm-5 1v-2h-2v3h2v-1Zm-3 0-1-2h-17v3h18v-1Zm-19 0v-1l-2-2v4h2v-1Zm-3-1-1-2-3-1v5h4v-2Zm-7 5-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-38h4l2-2h9l1-3h-2l-2 3v-2l4-4h12l4 5h10l1-3 3 1-1-2 4-4h37l3 4v3l4-3h5l6 6v29l-7 7v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="m107 109-1-1v3l1-2h-1Zm65 0-1-1v4l1-1v-2Zm-8-3v-1h1v1h-1Zm-32 4v-1h1v1h-1Zm24 0v-3l2 6v-5l1 5 4-4v2l4 1v-5l-3-3h-36l-3 3-4 5 5-2 1 2h29v-3Zm-51 0v-2h-9v4h9v-2Zm71 0v-1h1v1h-1Zm1 7v-1h1l3 3v-7h-5l3-1-1-3h-5v3l2-1 1 2h-4v6h6l-1-1Zm-53 0 1-1v-2l-6 1 5 1h-3v2h1l2-1Zm-8-3v-1h1v1h-1Zm2 2 1-2-2-2-3 1v5l4-1v-1Zm-36 2v-1h-2v2h2v-1Zm26 1v-1l2 1 1-3 2 3v-5h-7v6h2v-1Zm-21 1 2-2v3h16v-7H85l-2 3 1 4h2l1-1Zm32 1v-1h-9v2h9v-1Zm-1 4v-1h-6v1h6Zm52 4-1-1v3l1-2h-1Zm11 0-1-1v5l1-3v-1Zm-4 0v-1h1v1h-1Zm2 1v-3h-3v5l2-2v2h1v-2Zm-9 10v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm5-8v-2l1 3-1 1v-2Zm0 6v-3h3l-2 3v2l3-2-1 2h-3v-2Zm0 5v-1l3 2 5-4v-4l-2-3-4 1v-8l-2 1v-3h2v3l5-2v2h2l-1-4h-8v-2h9v-2h-10v25h2l-1-1Zm-60-9v-1h1v1h-1Zm-1 2v6h6l1-4v-11l-6-1-3 3v16l2-16v7Zm-24-10-1-1v3l1-2h-1Zm8 2-1-1-2 2 4-1h-1Zm-6 4-1-1-2 1h3Zm8 2h1l-1-4h-4v2l-1 3h5v-1Zm-8 0-1-1v5l1-3v-1Zm9 3 2-2v-3l-3 4-3 2-3-2 2 2h3l2-1Zm-11 1-1-1v3l1-2h-1Zm-3 2v-15h20l-1 16-18 1-1-2Zm22 3 1-1h-2v-2l2-3h-2l1-15H84v22h23l1-1Zm11 2 1-2h-7v3h6v-1Zm-7 1v-1h-1v1h1Zm15 5v-1h-1v1h1Zm-37 0-3-1-2-3v4h8-3Zm71 1 1-2h-4v3h2l1-1Zm-5 1-1-1-3 1h5-1Zm-5-34v-1h1v1h-1Zm15 2v-1h1v1h-1Zm-29-1 1-1-4 1 1-3 4 2 10-1 1 3-9-1-4 1 1-1Zm-2 2v-1h1v1h-1Zm20 2v-1h1v1h-1Zm11 3 1-1 1 1h-4 2Zm-6-1-1-2-3 2 2-2-3-4h-2l1 3-2-2 2-2 6 6 4-5v-4l1 4-4 5 1 3h-1l-1-2Zm-32 15v-1h1v1h-1Zm37 3v-1l1 1-1 2v-2Zm-9 4 4-5v-5l2 4v-7l-3-7 2 2 2-1 1 8-3 9h6l1-3-2-6 3 1v-2h-5l5-2v-2h-5l5-1v-13h-3l3-1v-3h-38l-6 6h-4v4l2 2h-2v9h4v-4l3-7-1-1v-2h2v3l3-3 2 3-4-1 1 4-2-1-1 3 2-1-2 3-1-3 1 9-2-5 1 9 4 7h3v2l6 2h11l5-5Zm-31-2v-1h1v1h-1Zm-3-1v-1l2 1v1h-2v-1Zm9 5-4-3v-1l-2-10h-4v11l5 1 5 5h3l-3-3Zm-36 4v-1h-1v1h1Zm46 2-1-1-1 1h2-1 1Zm-17 1-1-1-3 1 4 1v-1Zm-5 0v-1h-1v1h1Zm50 0-1-1v5l1-3v-1Zm-5 1v-3h-2v3l-2-2v4h4v-2Zm-5 1v-2h-2v3h2v-1Zm-3 0-1-2h-17v3h18v-1Zm-19 0v-1l-2-2v4h2v-1Zm-3-1-1-2-3-1v5h4v-2Zm-7 5-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-38h4l2-2h9l1-3h-2l-2 3v-2l4-4h12l4 5h9l8-8h37l3 4v3l4-3h5l6 6v29l-7 7v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_11 =
        '"/><path d="m128 104 1-1 1 1h-3 1Zm-4 3 1-2h1l-2 4h-2l2-2Zm38 3v-1h1v1h-1Zm10-1-1-1v4l1-1v-2Zm-63 2v-1l-3-2v5l2-1 1-1Zm-4-1v-2h-9v4h9v-2Zm65 5v-1h-1v1h1Zm6-5v-1h1v1h-1Zm5 6 1-2-1-2h-5l3-2-1-2h-5l-1 6v4h9v-2Zm-59 0 1-1 1 1h-2Zm2 1 1-1v-1l-5-1v3l1 1h1l2-1Zm-6 0h1l-1-4h-4v6l3-2h1Zm-36 1-2-2v3h2v-1Zm23-2v-1h1v1h-1Zm0 3v-1h1v1h-1Zm3 1v-2l3 2v-4l2 4v-6l-28-1-2 4 1 4h24v-1Zm8 3 1-1 1 1h-4 2Zm3 0v-3h-9v4l2-2v3h7v-2Zm-8 2v-1h-1v1h1Zm-30 7v-1h-1v1h1Zm0 9v-1h-1v1h1Zm25-1v-1h1v1h-1Zm-18-14-1-1v3l1-2h-1Zm9 2-2-1-2 2h6l-2-1Zm-9 2v-1h-1v1h1Zm10 4h1l-1-4h-4l-1 3 2 2h3v-1Zm-8 0v-3h-2l1 6h1v-3Zm3 2v-1h1v1h-1Zm6 1 2-2v-4l-2-1 1 4-3 3h-3v-2h-2l-1-5v5l3 3h3l2-1Zm-4 3v-1h-1v1h1Zm-7-2-1-1v4l1-2v-1Zm-2 2-1-1v-14h20v15l-2 1 1-8-2-1v9h-4l3-1v-1l-7 2-1-2-4 2h-3v-1Zm20 2v-1h1v1h-1Zm2-1v-4h-2l1-2v-12H83l1 21h24v-3Zm11 4v-2h-7v4l6-1v-1h1Zm-7-9v6h6v-15l-6-1v3l-2-2v20l1-18 1 7Zm62-10-2-2 3 2 4 1h-4l-1-2Zm3 3v-1h1v1h-1Zm-2 0v-1l1 1-1 2v-2Zm-1 7v-1h1v1h-1Zm-1 3-1-1 3 1v1h-1l-1-1Zm1 5v-1l1 1-1 2v-2Zm4-1 4-4v-4h-2l2-3-2-4v5h-5v-1l3-2 1 3v-5l3-1v-5h-9l9-1v-2h-10v26h-2l1 2h3l4-4Zm-16 6v-1h-1v1h1Zm-3 0-1-1-1 1h2-1 1Zm-34 0v-1h-1v1h1Zm-17 1-2-2v3l-2-2v2h4Zm-5 0v-2h-5l-5-1 3 2h-5v-2l-5 3v-2h-2v4h19v-2Zm58 2v-2h-4v4l3-1 1-1Zm6-34 1-1 1 1h-3 1Zm-22 1 1-1 1 1h-3 1Zm18 1v-1l1 1-1 2v-2Zm-8 2v-1h1v1h-1Zm-29 0v-1h2l-1 2h-1v-1Zm42 0v-2l1 2-1 3v-3Zm-8 1 1-1h1l-1 2h-1v-1Zm5 4 1-1 1 1h-4 2Zm-6 0v-1h1v1h-1Zm-33 0v-1h1v1h-1Zm-1 2v-1l1 1-1 2v-2Zm41 3v-1h1v1h-1Zm-2 0v-1h1v1h-1Zm2 4 2-1v-5l1 6h-6 3Zm0 6v-1h1v1h-1Zm-2 2v-1h1v1h-1Zm-8 8v-1l-5 2 6-7h2l2-7v-8l2 1v6l-3 7v2h4l3-2 3-4v-23l-3-4h-37l-6 6h-4v15h4v-3h1v9l4 6 3 3 6 3h18v-1Zm-34-6v-1h1v1h-1Zm5 5v-2h1l1 3h-2v-1Zm3-1-4-4-2-10h-4v11h6l-1 4 2 2h6l-4-4Zm-11 4-1-1-2 1h3Zm-25 0v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-2 0-1-1-2 1h3Zm-3 0v-1h-1v1h1Zm53 2-1-1-1 1h2-1 1Zm-15 0-1-1v3l1-2h-1Zm-2 0v-1h-3v2h3v-1Zm-4 1-2-2v2h2Zm-7-1v-1h1v1h-1Zm1 0h1l-2-2-2 3h3Zm55 2v-3l-2 4v1h2v-3Zm-5 0v-3h-4v5l3 1h1v-3Zm-5 1v-3l-21 1v1l-3-3v6h23l1-2Zm-25-1v-3h-4v6h4v-3Zm20 5-1-1-1 1h2-1 1Zm-27 0-1-2h-13l-7-8h-5l-2 3H84l-1-4h-4v-22l2-1-2-1v-14h4l2-2h10v-3h-2l-2 3v-2l4-4h12l4 6 44 1 2-3v3l2-5v4h8v-5l-3-3h-22l22-1 4 4v3l4-3h5l6 6v29l-7 7v7l-8 7-6 2-35 1-1-2Z" style="fill:';
    string private constant PART_12 =
        '"/><path d="m157 104 3-1 5 1h-11 3Zm-5 0 1-1 1 1h-3 1Zm14 2-1-1 3 1v1h-1l-1-1Zm-44 3v-1h1v1h-1Zm36 1v-1l1 1-1 2v-2Zm-11 55 1-1 1 1h-3 1Zm-9 0v-1h1v1h-1Zm-42-57v-1h-1v1h1Zm86 8v-2l-6-7-3 1h-2v4l2-2-1 4h-2v-2h-2l2 5 2-2v3h10v-2Zm-58 2v-2h3v-3h-7v5l1 1h3v-1Zm49 4 1-1 1 1h-3 1Zm4 5v-1h1v1h-1Zm0 2v-1h1v1h-1Zm0 2v-1h1v1h-1Zm2 1v-1l1 1-1 2v-2Zm-3 1v-1h1v1h-1Zm2 9 1-1h1l-1 2h-1v-1Zm0 2 4-3v-19h-4l4-1v-2h-10v24l-4 4 2 1h4l4-4Zm-62-21 1-1 1 1h-2Zm-4 3 1-1 2 1-4 1 1-1Zm7 25-1-1-4-1-3 3v-5h8v-4h-8l8-1-1-22h-8v31l1 1h8l-1-1Zm-6-36v-1h1v1h-1Zm-14 11v-1h1v1h-1Zm-11 0v-1h1v1h-1Zm7 4v-1h1v1h-1Zm3 1v-1h1v1h-1Zm-6 1v-1h1v1h-1Zm14 5v-1h1v1h-1Zm-8 1 1-1h-6l1 1h4v-1Zm-12-4-1-7 2-3v4h2l3 2v-4l1 3-3 2-3-2v2l3 7v-4l1 2h2l-1-2 4 3 4-5-1 5 2-3-1-4-6-4 1-1h3l-1 1 5 4v6l-5 3-6-1h-3v-3l-2 6v-7Zm18-1v-8l1-1v16l-2 1 1-8Zm5 17v-2l-2-1H87v2l-4-4 1-1h24l1-22H84l25-1v-2h4v-3l3 4 2-1 1-7-7 2-26-1-3 3v35l1 1h24l1-2Zm64 3v-1h-1v1h1Zm-4 0v-1h-1v1h1Zm-5 0-1-1-1 1h2-1 1Zm-38-31v-1h1v1h-1Zm35 1v-1h1v1h-1Zm-37 10v-1l1 1-1 2v-2Zm41 3v-1h1v1h-1Zm-41 1v-1l1 1-1 2v-2Zm37 0v-2l2-3-1 7h-1v-2Zm-33 9v-1h1v1h-1Zm31 2v-1h1v1h-1Zm-3 0v-1h1v1h-1Zm-27 0v-1h1v1h-1Zm3 3v-1h1v1h-1Zm24 1v-1h1v1h-1Zm5 0v-1l9-9v-24l-3-4h-37l-6 6h-4v27h6l-4 4-2-2v3h4v-2l3 3h34v-1Zm-74 2-1-1-2 1h3Zm10 0v-1h-4v2l4-1Zm-5 0v-1h-4v2h4v-1Zm81 2v-1h-1v1h1Zm-46 1v-1h-1v1h1Zm-2-1-1-1-4-2v4h5l-1-1h1Zm-6-1v-2h-2v4h2v-2Zm-5 0v-2h-5l-1 2 2 2h4v-2Zm13 4v-1h-1v1h1Zm-2 0v-1h-1v1h1Zm-11 0-1-1-3 1 4 1v-1Zm9 0v-1h-5l3 2h2v-1Zm-5 0v-1h-2l-1 2h3v-1Zm50 1v-1h3v-2l-3-2h-2v6h2v-1Zm-6 2 2-1v-6h-5v8h2l1-1Zm-27 1v-1h-1v1h1Zm-4-1v-1h1v1h-1Zm2-2v-5h-5v9h5v-4Zm-7 3-1-2h-13l-7-8h-5l-2 3H84l-1-4h-5l4-1v-3h-4l4-1h-3v-3h2v-4l-3-1 4-3-1-8-3-1 3-6h-3l4-2v-3h-3v-2h4l1-2h5l5-6h13l1 2-13 1-1-1-4 4h19l-1-3 2 3 12-1v1h46v-2l5-4h3l7 8v28l-8 8v8h-3v2l-5 3-7 2h-5v-5l1 4 2-1v-8h-20v3l-3-3h-1v7l3-2v5h-10l-1-2Z" style="fill:';
    string private constant PART_13 = '"/>';
    string private constant COLOR_1 = "hsl(183, 89%, 64%)";
    string private constant COLOR_2 = "hsl(191, 83%, 53%)";
    string private constant COLOR_3 = "hsl(220, 0%, 63%)";
    string private constant COLOR_4 = "hsl(202, 79%, 46%)";
    string private constant COLOR_5 = "hsl(220, 4%, 43%)";
    string private constant COLOR_6 = "hsl(223, 2%, 37%)";
    string private constant COLOR_7 = "hsl(208, 81%, 30%)";
    string private constant COLOR_8 = "hsl(213, 6%, 24%)";
    string private constant COLOR_9 = "hsl(223, 9%, 20%)";
    string private constant COLOR_10 = "hsl(225, 10%, 18%)";
    string private constant COLOR_11 = "hsl(223, 10%, 13%)";
    string private constant COLOR_12 = "hsl(225, 17%, 9%)";

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
            PART_12,
            ship.shipData.shiny
                ? blendHSL(
                    ship.traits.colors.h1,
                    ship.traits.colors.s1,
                    ship.traits.colors.l1,
                    COLOR_12
                )
                : COLOR_12
        );
        string memory chunk4 = string.concat(PART_13);
        return string.concat(chunk1, chunk2, chunk3, chunk4);
    }
}
