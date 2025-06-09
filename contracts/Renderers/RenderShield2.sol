// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../Types.sol";
import "../IRenderer.sol";
import "./RenderUtils.sol";

contract RenderShield2 {
    string private constant PART_1 =
        '<path d="M111 120h-5 6-1Zm-7 0-1-1-2 2h4l-1-1Zm-4 0h-1v1h1v-1Zm-2 0h-2l-2 1h5l-1-1Zm-8 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm51 45v-1l-4 1-3-3h-2l-4-4h-10l-6-6h-8l-2 2H85v-3h-6v-38l5-3h9l5-5h14l6 5h3l7-8h36l5 4v5h12v33l-4 5v3h-2v6h-8l-7 3v2h-5l-2 1h-8l-2-2v4h-3v-1Z" style="fill:';
    string private constant PART_2 =
        '"/><path d="M139 165v-1l-4 1-3-3h-2l-4-4h-10l-6-6h-8l-2 2H85v-3h-6v-38l5-3h9l5-5h14l6 5h3l7-8h36l5 4v5h12v33l-4 5v3h-2v6h-8l-7 3v2h-5l-2 1h-8l-2-2v4h-3v-1Z" style="fill:';
    string private constant PART_3 =
        '"/><path d="M111 120h-5 6-1Zm-7 0-1-1-2 2h4l-1-1Zm-4 0h-1v1h1v-1Zm-2 0h-2l-2 1h5l-1-1Zm-8 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm18 10v-1h-2v2h2v-1Zm63 12-1-27-48 1v26l20 3 29-3Zm-30 23v-1l-4 1-3-3h-2l-4-4h-10l-6-6h-8l-2 2H85v-3h-6v-38l5-3h9l5-5h14l6 5h3l7-8h36l5 4v5h12v33l-4 5v3h-2v6h-8l-7 3v2h-5l-2 1h-8l-2-2v4h-3v-1Z" style="fill:';
    string private constant PART_4 =
        '"/><path d="m136 105-1-1-1 2h3l-1-1Zm-3 0h-1v1h1v-1Zm26 0-1-1v3l2-1-1-1Zm-3 0h1-8l1 2 6-2Zm-8 1v-1h-11l6 1h5Zm16 1v-2h-4v2l3-2v4h1v-2Zm-31 1h-1v1h1v-1Zm-22 0v-1h-9v2h9v-1Zm-10 0v-1h-2v2h2v-1Zm60 1h-1v1h1v-1Zm-10 0h-1v1h1v-1Zm-20 0v-1h-3l-1 2h3l1-1Zm48 4v-1h-7l1 2 4-1v2h1l1-2Zm-61 0h1v1h-1v-1Zm2 0v-1h-5v3h5v-2Zm-6 0v-2l-9 1-1 2 10 1v-2Zm-11 0v-1H88l-3 1v2h18v-2Zm-16 3-1-1-1 2h3l-1-1Zm21 0-1-1v3l2-1-1-1Zm-2 1v-1h-1l-1 2h1l1-1Zm-9 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm87 1h-7 9-2Zm-8 0v-1h-3v2h3v-1Zm-52 0v-1h-6v2h6v-1Zm-8 0h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm0 2h-1v1h1v-1Zm92 5h-1v1h1v-1Zm-59 0-1-1-1 2h3l-1-1Zm-12 5v-1h-2v2h2v-1Zm-19 0v-8h-1v16h1v-8Zm26 0v-8l-3-2H88l24 1 1 4v13l1-1v-7Zm-7 9h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-5 0-1-1-1 2h3l-1-1Zm-3 0-1-1-2 2h4l-1-1Zm-4 0h-5 6-1Zm48-11v-12h-2v26l2-1v-13Zm-13-6v-8 28-21Zm37-1v-7 29-22Zm-4 0v-7 29-22Zm-4 0v-7 29l2-14-2-8Zm-4 0v-7 29l1-14-1-8Zm-3 0-1-7v29l1-15v-7Zm-4 0-1-7v29l1-15v-7Zm-10 0v-7 29-22Zm-3 7v-12h-2v27l1-2 1-13Zm-8-5v-8 28-21Zm13 27h-1v1h1v-1Zm22 4h-1v1h1v-1Zm-3 0h-6 8-2Zm-7 0h-1v1h1v-1Zm-4 0h-9 12-3Zm-10 0-1-1-1 2h3l-1-1Zm4 10-1-2-2 3h-1l-3-3-7-4h-9l-6-6h-8l-2 2H86l-1-3h-6v-38l5-2h9l5-6h14l5 5h4l7-7h37l4 4v4h13v33l-4 5v3h-2v6h-11v1l-7 4h-3l-2 1h-8l-2-1-1 3h-2l-1-2Z" style="fill:';
    string private constant PART_5 =
        '"/><path d="m136 105-1-1-1 2h3l-1-1Zm-3 0h-1v1h1v-1Zm26 0-1-1v3l2-1-1-1Zm-3 0h1-8l1 2 6-2Zm-8 1v-1h-11l6 1h5Zm16 1v-2h-4v2l3-2v4h1v-2Zm-31 1h-1v1h1v-1Zm-22 0v-1h-9v2h9v-1Zm-10 0v-1h-2v2h2v-1Zm60 1h-1v1h1v-1Zm-10 0h-1v1h1v-1Zm-20 0v-1h-3l-1 2h3l1-1Zm48 4v-1h-7l1 2 4-1v2h1l1-2Zm-61 0h1v1h-1v-1Zm2 0v-1h-5v3h5v-2Zm-6 0v-2l-9 1-1 2 10 1v-2Zm-11 0v-1H88l-3 1v2h18v-2Zm-16 3-1-1-1 2h3l-1-1Zm21 0-1-1v3l2-1-1-1Zm-2 1v-1h-1l-1 2h1l1-1Zm-9 0h-1v1h1v-1Zm-5 0h-1v1h1v-1Zm87 1h-7 9-2Zm-8 0v-1h-3v2h3v-1Zm-52 0v-1h-6v2h6v-1Zm-8 0h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm0 2h-1v1h1v-1Zm92 5h-1v1h1v-1Zm-59 0-1-1-1 2h3l-1-1Zm-15 5h-1v1h1v-1Zm4-1-1-1h-2v2l3 1h1l-1-2Zm35 7h-1v1h1v-1Zm-55-6v-8h-1v16h1v-8Zm26 0v-8l-3-2H88l24 1 1 4v13l1-1v-7Zm29 9h-1v1h1v-1Zm-36 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-5 0-1-1-1 2h3l-1-1Zm-3 0-1-1-2 2h4l-1-1Zm-4 0h-5 6-1Zm50 2h-1v1h1v-1Zm18 1v1m3-2 1 2v-28l-3 1v3l-1-5-2 5-2-5-2 5 2 24m-14-10v-2l2 2-2 1v-1Zm3 4-1-6 1-7h2l1 19 1-6v-16l2 2v20l1-1 1-24-2-4-1 7-1-6h-5l-3 2v17h2v9h2v-6Zm-5-8v-15l-2 1v22l1 6h1v-15Zm-4-12v-2h-2l-1 25 2 3 1-24v-2Zm-4 12v-15l-2 1v28h2v-15Zm-8 0v-1h1l1 3h-2v-2Zm1 6v5l1 3h2v-28h-5l-1 23 2 5 1-12v4Zm12 15h-1v1h1v-1Zm22 4h-1v1h1v-1Zm-3 0h-6 8-2Zm-7 0h-1v1h1v-1Zm-4 0h-9 12-3Zm-10 0-1-1-1 2h3l-1-1Zm4 10-1-2-2 3h-1l-3-3-7-4h-9l-6-6h-8l-2 2H86l-1-3h-6v-38l5-2h9l5-6h14l5 5h4l7-7h37l4 4v4h13v33l-4 5v3h-2v6h-11v1l-7 4h-3l-2 1h-8l-2-1-1 3h-2l-1-2Z" style="fill:';
    string private constant PART_6 =
        '"/><path d="m136 105-1-1-1 2h3l-1-1Zm-3 0-1-1-1 2h3l-1-1Zm24 0h1-9v2l7-1 1-1Zm-9 0h-11v2l11-1v-1Zm9 3h-1v1h1v-1Zm-46 0v-1h-9v2h9v-1Zm-10 0v-1h-2v2h2v-1Zm62-1 1 2v-4h-6v2l2-1v4l3-5v2Zm-26 2-2-1-1 2h3v-1Zm22 0v-2l-1 4 2-1-1-2Zm-6 1v-1h-3l1 2h1l1-1Zm-22-1h-1 3v-2l-4 1-3 2h5v-1Zm-18 1h-1v1h1v-1Zm67 3-1-1h-7v3h8v-2Zm-60 0v-1h-5v3h5v-2Zm-6 0v-1h-10v3h10v-2Zm-11 0v-1H88l-3 1v2h18v-2Zm72 3h-1v1h1v-1Zm-85 0h-1v1h1v-1Zm7 1-2-2 1 3h1v-1Zm-3 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm87 1h-7 9-2Zm-60 0v-1h-6v2h6v-1Zm-13 0-1-2 6 3v-3h-6l-1 3h3l-1-2Zm-19-1v-1h-3l2 1-2 2h3v-2Zm83 2h1v-2h-4l1 4 1-2h1Zm-85 1h-1v1h1v-1Zm93 5-1-1-1 2h3l-1-1Zm-60 1v-1h-2v2h1l1-1Zm-24 3h-1v1h1v-1Zm9 1h-1v1h1v-1Zm4-1-1-1h-2v2l3 1h1l-1-2Zm61 7h-1v1h1v-1Zm-26 0h-1v1h1v-1Zm-55-6v-8h-1v16h1v-8Zm55 9h-1v1h1v-1Zm-30 0 1-2v-15l-3-2H88l24 1 1 3v14l-4 2h3l1-2Zm-5 0h-5 6-1Zm-10 0H87h13-3Zm45 2h-1v1h1v-1Zm16-21 1 22 1 1 1-24 1 4v16l2 4v-28l-2 1-1 3-1-5-2 5-2-5-2 5 2 24 2-24v1Zm-16 13v-2l2 2-2 1v-1Zm3 4-1-6 1-7h2l1 19 1-6v-16l2 2v20l1-1 1-24-2-4-1 7-1-6h-5l-3 2v17h2v9h2v-6Zm-5-8v-15l-2 1v22l1 6h1v-15Zm-4-12v-2h-2l-1 25 2 3 1-24v-2Zm-4 12v-15l-2 1v28h2v-15Zm-8 0v-1h1l1 3h-2v-2Zm1 6v5l1 3h2v-28h-5l-1 23 2 5 1-12v4Zm28 15h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm18 2h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm8 2h-1v1h1v-1Zm-3 0h-6 8-2Zm-7 0h-1v1h1v-1Zm-4 0h-9 12-3Zm-10 0-1-1-1 2h3l-1-1Zm4 10-1-2-2 3h-1l-3-3-7-4h-9l-6-6h-8l-2 2H86l-1-3h-6v-38l5-2h9l5-6h14l5 5h4l7-7h37l4 4v4h13v33l-4 5v3h-2v6h-11v1l-7 4h-3l-2 1h-8l-2-1-1 3h-2l-1-2Z" style="fill:';
    string private constant PART_7 =
        '"/><path d="m136 105-1-1-1 2h3l-1-1Zm-3 0-1-1-1 2h3l-1-1Zm24 0h1-9v2l7-1 1-1Zm-9 0h-11v2l11-1v-1Zm9 3h-1v1h1v-1Zm-46 0v-1h-9v2h9v-1Zm-10 0v-1h-2v2h2v-1Zm62-1 1 2v-4h-6v2l2-1v4l3-5v2Zm-26 2-2-1-1 2h3v-1Zm22 0v-2l-1 4 2-1-1-2Zm-6 1v-1h-3l1 2h1l1-1Zm-22-1h-1 3v-2l-4 1-3 2h5v-1Zm-18 1h-1v1h1v-1Zm67 3-1-1h-7v3h8v-2Zm-60 0v-1h-5v3h5v-2Zm-6 0v-1h-10v3h10v-2Zm-11 0v-1H88l-3 1v2h18v-2Zm72 3h-1v1h1v-1Zm-85 0h-1v1h1v-1Zm7 1-2-2 1 3h1v-1Zm-3 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm87 1h-7 9-2Zm-60 0v-1h-6v2h6v-1Zm-13 0-1-2 6 3v-3h-6l-1 3h3l-1-2Zm-19-1v-1h-3l2 1-2 2h3v-2Zm83 2h1v-2h-4l1 4 1-2h1Zm-85 1h-1v1h1v-1Zm93 5-1-1-1 2h3l-1-1Zm-60 1v-1h-2v2h1l1-1Zm48-6v-4 14-10Zm-72 9h-1v1h1v-1Zm11 2v-1l2 2h-3l1-1Zm2 0 1-1-1-2h-2l-3 2 3 3h1l1-2Zm61 5h-1v1h1v-1Zm-81-6v-8h-1v16h1v-8Zm25 9 1-2v-15l-3-2H88l24 1 1 3v14l-4 2h3l1-2Zm-5 0h-5 6-1Zm-10 0H87h13-3Zm56-22h1v1h-1v-1Zm-21 11v-2l2 2-2 1v-1Zm22 0v-3l1 3-1 2v-2Zm-22 4v-2l2 2-2 1v-1Zm17 1v-2l2 2-2 1v-1Zm-8 0v-4 7-3Zm17 3v-3l1 3-1 2v-2Zm3-1v-5 9-4Zm-15 6h1v1h-1v-1Zm-20 1 2 1 1-18v12l2 7 1-1 1-8 1 8h2l1-21v21h3l1-7 1 7h7l1-6 1 7 2-1 1-13 1 12 2 1v-5l3 5 1-3v2l3 2v-29h-26l-1 3-1-3h-6l-2 3v-3h-5l-1 26 2 3 1-2h1Zm27 8h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm18 2h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm8 2h-1v1h1v-1Zm-3 0h-6 8-2Zm-7 0h-1v1h1v-1Zm-4 0h-9 12-3Zm-10 0-1-1-1 2h3l-1-1Zm4 10-1-2-2 3h-1l-3-3-7-4h-9l-6-6h-8l-2 2H86l-1-3h-6v-38l5-2h9l5-6h14l5 5h4l7-7h37l4 4v4h13v33l-4 5v3h-2v6h-11v1l-7 4h-3l-2 1h-8l-2-1-1 3h-2l-1-2Z" style="fill:';
    string private constant PART_8 =
        '"/><path d="M98 108h-1v1h1v-1Zm64 1v-1l2-3-1 3 1 3v-6h-6v5l5 1-1-2Zm-16 1h-1v1h1v-1Zm2-4h1v1h-1v-1Zm7 1h1v1h-1v-1Zm-22 0-2-1h5l3 2-3-1h-3Zm-3 2h1v1h-1v-1Zm16 1h1l6 1-2-2 4 2h2v-6h-26l-5 6 20-1Zm-33-1-1-1v3l2-1-1-1Zm-6 0h1v1h-1v-1Zm-5 1-1-1 10 2v-4H99v4h3v-1Zm62 2-1-1v3l2-1-1-1Zm16 1v-1h-8v3h9l-1-1Zm-10 1h1-4l-1 2 3-1 1-1Zm-87 1h-1v1h1v-1Zm96 1h-7 9-2Zm-72-1h1v1h-1v-1Zm5 2v-1h-3l6-2 1 1h4v-3h-16v3h3l-3 1v3h8v-2Zm-9 0v-1h-9l-3 1v2h12v-2Zm-12 0v-1h-2v2h-2l1-2-3-1h18v-3H85l-1 7h6l1-2Zm-6 3h-1v1h1v-1Zm93 5v-1h-2v2h2v-1Zm-1 3v-1l-2 1 1 2h1v-2Zm-11-8v-4 14-10Zm10 1v-1l-3-1h3l3 3h-3v-1Zm-1 3 1-1h4v-5h-8l1 15 1-8 1-1Zm4 11 1-1-2 2-3-3-3 2 3-1 1 3h2l1-1Zm-11 0h1v1h-1v-1Zm3-8v-10h-4v20l3 1h1v-11Zm-54-7v-1l2 2h-3l1-1Zm0 4v-1l2 2h-3l1-1Zm0 12-1-1h3v-8h-2l2-3v-7h-6v4h2v17l2-2Zm59 2h-1v1h1v-1Zm-60 1h-1v1h1v-1Zm-15-11h-1v1h1v-1Zm-6 2v-1h-2v2h1l1-1Zm10 1v-1l2 2h-3l1-1Zm2 0 1-1-1-2h-2l-3 2 3 3h1l1-2Zm2 5h-1v1h1v-1Zm-22-6v-9h24l1 4v13l-25 1v-9Zm26 8v-15l-1-3H88l-3 2v15l3 3h24l1-2Zm61 3-2-1v2h2v-1Zm-57 0h-1v1h1v-1Zm53 1-1-1 3-1h-5l3 3h1l-1-1Zm-17-25h1v1h-1v-1Zm-21 11v-2l2 2-2 1v-1Zm22 0v-3l1 3-1 2v-2Zm-22 4v-2l2 2-2 1v-1Zm17 1v-2l2 2-2 1v-1Zm-8 0v-4 7-3Zm17 3v-3l1 3-1 2v-2Zm3-1v-5 9-4Zm-15 6h1v1h-1v-1Zm-20 1 2 1 1-18v12l2 7 1-1 1-8 1 8h2l1-21v21h3l1-7 1 7h7l1-6 1 7 2-1 1-13 1 12 2 1v-5l3 5 1-3v2l3 2v-29h-26l-1 3-1-3h-6l-2 3v-3h-5l-1 26 2 3 1-2h1Zm-12 0v-2l-1 4 1-1v-1Zm-28 2-2-2 1 3h1v-1Zm80 1 1-2h-1l-4 3h3l1-1Zm-9 0h-14 19-5Zm-16 0h-6 8-2Zm-7 0-1-1-1 2h3l-1-1Zm-4 0h-6 8-2Zm-8-1-1-1-1 1 1 2h1v-2Zm31 6h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm24 2h1-4v3l2-2h1Zm-9 1h1v1h-1v-1Zm5 0v-1h-7l1 2h-1l-1-3-1 4h9v-2Zm-14 0h1l3 1h-6l2-1Zm4 0v-1h-11l4 1-4 2h12l-1-2Zm-12 0v-1h-2v3h2v-2Zm4 11-1-2-2 3-9-6v-1h-11l-6-6h-8l-2 2H86l-1-3h-6v-38l6-2h8l5-6h14l5 5h4l7-7h37l4 4v4h13v34l-4 4v3h-2v6h-11v2l-6 2h-4l-1 2-9 1-2-2-2 3h-1l-1-2Z" style="fill:';
    string private constant PART_9 =
        '"/><path d="M98 108h-1v1h1v-1Zm64 1v-1l2-3-1 3 1 3v-6h-6v5l5 1-1-2Zm-16 1h-1v1h1v-1Zm2-4h1v1h-1v-1Zm7 1h1v1h-1v-1Zm-22 0-2-1h5l3 2-3-1h-3Zm-3 2h1v1h-1v-1Zm16 1h1l6 1-2-2 4 2h2v-6h-26l-5 6 20-1Zm-33-1-1-1v3l2-1-1-1Zm-6 0h1v1h-1v-1Zm-5 1-1-1 10 2v-4H99v4h3v-1Zm62 2-1-1v3l2-1-1-1Zm16 1v-1h-8v3h9l-1-1Zm-97 2h-1v1h1v-1Zm96 1h-7 9-2Zm-72-1h1v1h-1v-1Zm5 2v-1h-3l6-2 1 1h4v-3h-16v3h3l-3 1v3h8v-2Zm-9 0v-1h-9l-3 1v2h12v-2Zm-12 0v-1h-2v2h-2l1-2-3-1h18v-3H85l-1 7h6l1-2Zm-6 3h-1v1h1v-1Zm93 5v-1h-2v2h2v-1Zm-1 3v-1l-2 1 1 2h1v-2Zm-1-7v-1l-3-1h3l3 3h-3v-1Zm-1 3 1-1h4v-5h-8l1 15 1-8 1-1Zm4 11 1-1-2 2-3-3-3 2 3-1 1 3h2l1-1Zm-11 0h1v1h-1v-1Zm3-8v-10h-4v20l3 1h1v-11Zm-54-7v-1l2 2h-3l1-1Zm0 4v-1l2 2h-3l1-1Zm0 12-1-1h3v-8h-2l2-3v-7h-6v4h2v17l2-2Zm59 2h-1v1h1v-1Zm-60 1h-1v1h1v-1Zm-15-11h-1v1h1v-1Zm-6 2v-1h-2v2h1l1-1Zm13 1 1-2-4-2-3 3 1 3h4l1-2Zm1 5h-1v1h1v-1Zm-22-6v-9h24l1 4v13l-25 1v-9Zm26 8v-15l-1-3H88l-3 2v15l3 3h24l1-2Zm61 3-2-1v2h2v-1Zm-57 0h-1v1h1v-1Zm53 1-1-1 3-1h-5l3 3h1l-1-1Zm-56 0v-2l-1 4 1-1v-1Zm-28 2-2-2 1 3h1v-1Zm80 1 1-2h-1l-4 3h3l1-1Zm-9 0h-14 19-5Zm-16 0h-6 8-2Zm-7 0-1-1-1 2h3l-1-1Zm-4 0h-6 8-2Zm34-12h1v1h-1v-1Zm0 3h1v1h-1v-1Zm0 3v-2l2 3-2 1v-2Zm-42 5-1-1 42 1 3-3 1-26h2l2-1h-3l-4 3v-2h-41l-3 3 1 26v2h1v-2Zm31 6h-1v1h1v-1Zm-16 0h-1v1h1v-1Zm24 2h1-4v3l2-2h1Zm-9 1h1v1h-1v-1Zm5 0v-1h-7l1 2h-1l-1-3-1 4h9v-2Zm-14 0h1l3 1h-6l2-1Zm4 0v-1h-11l4 1-4 2h12l-1-2Zm-12 0v-1h-2v3h2v-2Zm4 11-1-2-2 3-9-6v-1h-11l-6-6h-8l-2 2H86l-1-3h-6v-38l6-2h8l5-6h14l5 5h4l7-7h37l4 4v4h13v34l-4 4v3h-2v6h-11v2l-6 2h-4l-1 2-9 1-2-2-2 3h-1l-1-2Z" style="fill:';
    string private constant PART_10 =
        '"/><path d="M134 106h1v1h-1v-1Zm30 2v-3h-37l2 2 1-1-4 4 2-3h-1l-4 4h41v-3Zm-66 1v-1l2 3h11v-3l2 3v-4H98l-3 4h3v-1Zm73 6v-1h-5v2h5v-1Zm5 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm7-1v-2h-8v5h8v-2Zm-89 2h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm16 0v-2l1 5h7v-3h8v-4l2 3 2-2-1-1H87l-3 2 2-3-4 3v2l2-1v4h19v-2h1Zm-21 5-1-1v3l2-1-1-1Zm0 3h-1v1h1v-1Zm0 3h-1v1h1v-1Zm94 0-1-1 3 1v1h-2v-1Zm3 4v-1l-1-6h-4v8h4l1-1Zm-61-4v-10h-6v5h2v15l4 1v-11Zm53 1v-10 21h5l3-5v-1l-6-1-1-6 2-3h5v-5h-6l-7-1v22h4l1-10Zm-66-3h-1v1h1v-1Zm-16 2h-1v1h1v-1Zm20 3v-2l-1 4 1-1v-1Zm-8 4h-1v1h1v-1Zm-4-2 1-1-4 2v-6h-4v2l2-1v4l1 3 4-3Zm13 2-1-1v3l2-1-1-1Zm-4 1-2-1 4-1-1-6 1 1 3-2-2-2-1 2-6 1 2-3-2 2v2h-3v4l3-1v4h5-2Zm2 2v-1l-4 1v1h4v-1Zm-7 0v-1h-3l1 2h1l1-1Zm-15-7v-9h24l1 4v13l-25 1v-9Zm26 8v-15l-1-3H84l2 1-1 17 3 2h24l1-2Zm-30 1h-1v1h1v-1Zm73-25h1v1h-1v-1Zm-23 0h23-31 8Zm32 29 1-2v-25l-8-2h7l-1-2h-40v3l-4 1v25l3 3h41l1-1Zm6-1h1v1h-1v-1Zm4 0 3-2h-11v5h5l3-3Zm-56 0v-3h-5l-2 4-3 1 10 1v-3Zm-12 2h-8 10-2Zm-13 0h-5v-3l-3 3-1-1h2v-2l-2-1v5l14-1h-5Zm72 0v-2l-4 4h4v-2Zm-9 1h-14 19-5Zm-17 0h-8 11-3Zm-10 0h-6 8-2Zm-8-1-1-1h-1l3 5v-2l-1-2Zm32 6-1-1-1 2h3l-1-1Zm-17-1-1-1v3l2-1-1-1Zm-48 1h-1v1h1v-1Zm42 1h-1v1h1v-1Zm-14 0h-1v1h1v-1Zm2 1h-1v1h1v-1Zm16 1v-1l-2-3v5l-3 1h5v-1Zm27 2h2l-1-3h-5l1 5 1-2h2Zm-13-2h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm2 2h1l3 1h-5l1-1Zm-7 0h6-8 2Zm13 1-2-1h4v-3h-21v5l22-1h-3Zm-24 6-3-2-1-2h-11l-6-6h-9l-1 2H86l-1-3h-6v-38l5-2h9l5-6h14l5 5h4l7-7h37l4 4v4h12v33l-4 4v4h-2v5h-8l-7 5h-5l-1 2h-10l-1-2-2 3-4-2-1 2-1-1-4-2Z" style="fill:';
    string private constant PART_11 =
        '"/><path d="m96 111 2-1 1-2v3l15-1 2 2H95l1-1Zm64 3h1l3 1h-6l2-1Zm-4 0h1v1h-1v-1Zm-5 0h5-7 2Zm-13 0h10-13 3Zm-10 0h7-9 2Zm-25 1h1v1h-1v-1Zm-12 1h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm25 0 1-1 6 1v-4l2 3-2 2h-8l1-1Zm6 4v-2l2 2-2 1v-1Zm0 3h1v1h-1v-1Zm1 5v-3l1 4-1 2v-3Zm47-19v-2h-2v4h2v-2Zm-3-2v-3h-35l-6 5v2h41v-3Zm6 5h-1v1h1v-1Zm3 3h1v1h-1v-1Zm7-1v-2h-8v5h8v-2Zm-97 4h-1v1h1v-1Zm18 8v-1h-2v2h1l1-1Zm75 0h1v1h-1v-1Zm4 4 1-1-2-5h-4v8h4l1-2Zm-71-3-1-2 2 2v1h-1v-2Zm2-1v-1h-8l-1 2 4-2 3 3v4l2-5v-1Zm-2 11v-1h-7v-3l-2 2v-2l2-2 2 3-1 2h5l-3-2 3-1-1 2 2-1-1-6-3-1-3 1-1-1-2 6v5h10v-1Zm-14-10-1-1 3 1v2h-1l-1-2Zm3 7v-2h-3l3-1v-5l-3-1-4 2v2l2-1v3l1 3 2 2h-4v-1l-3 1 3-4-2-5 3-2h-3l-1 11 2 2 7-1v-2Zm-15-10v-5 19-14Zm0 15v-1 5l1-2-1-1Zm91 3h1v1h-1v-1Zm-2 4 1-1-1-1h3l5-6v-5l-6-1-1-6 3-3h5v-5h-7l-6-1v22h4v-21l1 21h6l-12 1v8h4l1-2Zm-49 0v-1l-3-3v6h3v-2Zm-19-6v-1l2 2h-3l1-1Zm-3 0h1v1h-1v-1Zm0 3v-1h6l-3 2h-3v-1Zm-9-1v-1l7-1v4h-2v-2h-4l3 2h-3l-1-2Zm-3 0v-2l-1 2-3-2 2-2 1 2h2l1 4h-2v-2Zm-3 1h1v1h-1v-1Zm27 3v-2l2 2v1h-2v-2Zm-2 0h1v1h-1v-1Zm-20 0h1v1h-1v-1Zm-5 0-1-1h3l1 2h-3v-1Zm12 0v-2l1 4h9v-7h2l-1 7h10v-9h-4l-3 2v-3l-25 1v-18h24l1 2v13l-1-4-2 2 1 3h3v-14l-1-4-28 1 2 1-1 1v19l-2 4 4 2h11v-1Zm24 3h-1v1h1v-1Zm33 1-1-1-2 2h4l-1-1Zm-4 0h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-3 0h-7 9-2Zm-9-1-1-1v3l2-1-1-1Zm-23 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm-16-1-1-1v3l2-1-1-1Zm-5 1h-1v1h1v-1Zm-2 0h-1v1h1v-1Zm83 2v-1l-5-1v3h5v-1Zm-43-1v-2l-1 4 2-1-1-1Zm-2 1v-1l-10-1-1 1 1 2 10 1v-2Zm42 3h-1v1h1v-1Zm-49 0-1-1-1 2h3l-1-1Zm38-1v-2l1 5h5l-5-2h5v-2l-3-1h-25v5h21v-2h1Zm-34 2v-1h-1l-1 2h1l1-1Zm8-3h1v1h-1v-1Zm0 3-1-2 3 3h1v-8h-2v3l-1-2h-2v8h2v-2Zm-1 6-3-2-1-2h-11l-4-4 1-2-11-1-2 3H86l-1-3h-6v-37l5-3h1v2l-3-1v5l2-3v5h19l1-3v3h9l2 5v13h4l1-6v10l3 3h12l-11 1v3h7l1-3v3h10v-3l3 3 16-1 1-2v3h4v-6l-2 3-29-1h29l2-3v-25l-2-1 7 1v-2h-5l1-2h-43v3l-1-3h-6l-5-5H98l-5 5-7-1h7l5-6h14l5 5h4l7-7h37l4 4v4h12v34l-4 2v4l-2 1v5h-8l-7 5h-5l-1 2h-10l-1-2-2 3-4-2-1 2-1-1-4-2Z" style="fill:';
    string private constant PART_12 =
        '"/><path d="M155 111h1v1h-1v-1Zm-5 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-11 0h1v1h-1v-1Zm43 4v-2l2 2-2 1v-1Zm-12 1h1v1h-1v-1Zm-50 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-2 0h1v1h-1v-1Zm-22 0h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm90 1h1v1h-1v-1Zm-3 0h1v1h-1v-1Zm-3-1-1-2h-4l1-6-5-4h-34l-8 8-4-1-7-5H98l-1 2-4 3 5-6h14l5 5h4l7-7h37l5 5-2 2 2 3 2-1 1 6h-1v-2Zm-60 4h1v1h-1v-1Zm62 6h1v1h-1v-1Zm-70 0v-1l2 2h-3l1-1Zm-9 1h1v1h-1v-1Zm-4 0v-1h1l-1 2h-1l1-1Zm-12 0h1v1h-1v-1Zm99 5h1v1h-1v-1Zm-3 0-1-1 3 1v1h-2v-1Zm-68 1 2-1-1-7h1v9h-3l1-1Zm-7 0-1-2 1-4 1 7v1l-1-2Zm-9 0v-5l2 2v4h-3l1-1Zm11 1v-2l2 3-2 1v-2Zm-4 1v-2l2 2-2 1v-1Zm8 1v-1l2 2h-3l1-1Zm11 2h1v1h-1v-1Zm-16 0h6-8 2Zm-14-8v-8h25v13l-1-1v-11l-7 2 1-2-5 1-2 2v-3h-9l-1 15h11l-12 1v-9Zm-4 8h1v1h-1v-1Zm89-9v-11 22-11Zm-59 10v-1l2 2h-3l1-1Zm41 9h1l3 1h-5l1-1Zm-7 0h5-7 2Zm-6 0h1l3 1h-5l1-1Zm-3 0h1v1h-1v-1Zm-12 0h1v1h-1v-1Zm9 1h1v1h-1v-1Zm40 1h1v1h-1v-1Zm-23 1-1-2 2 2v1h-1v-2Zm-37 1h1v1h-1v-1Zm59 3h1v1h-1v-1Zm-44-2v-4 7-3Zm27 4h1v1h-1v-1Zm22-13v-1h-1l-1 2h2v-1Zm-4 3-1-1-1 2h3l-1-1Zm-17 14-1-1v-2l2 3 5-4v-4l-2-1 2-3h-6l1-1h12l9-8 1-23v23l-2 1 3 2-7 6h-2v3h2v2h-3v-5h-5v2l-2-2 1 7 1-5v6l-8 5-1-1Zm-3 0h1v1h-1v-1Zm-45-11-1-1h-6v2h7v-1Zm-9 1 2-3-10 1v2l-1-2h-5v4h12l2-3Zm30 8-2-2 1 3h1v-1Zm22 4v-1h-3v2h2l1-1Zm-6 0v-1h-3l1 2h1l1-1Zm-9 0-2-1-7-1-2-3h-11l-6-6h-9l-1 2H86l-1-3h-6v-6l3-11-3-2 2-1v-7l-2 1 2-8-2-2 5-4 1 1-3 2 1 33h-3v3h3l2-2h38l2 1h-14v2l6 6h13l4 3h20v2l-2 2h-8l-2-2h-3l1 2 2-1v2h-2l-2-2Zm-4 1-1-1h2l1 2h-2v-1Z" style="fill:';
    string private constant PART_13 = '"/>';
    string private constant COLOR_1 = "hsl(180, 94%, 74%)";
    string private constant COLOR_2 = "hsl(185, 85%, 64%)";
    string private constant COLOR_3 = "hsl(220, 3%, 63%)";
    string private constant COLOR_4 = "hsl(198, 77%, 42%)";
    string private constant COLOR_5 = "hsl(215, 4%, 52%)";
    string private constant COLOR_6 = "hsl(200, 83%, 36%)";
    string private constant COLOR_7 = "hsl(220, 2%, 43%)";
    string private constant COLOR_8 = "hsl(205, 9%, 37%)";
    string private constant COLOR_9 = "hsl(213, 9%, 24%)";
    string private constant COLOR_10 = "hsl(213, 10%, 20%)";
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
