// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

function hexToUint24(string memory hexColor) pure returns (uint24) {
    bytes memory b = bytes(hexColor);
    require(b.length == 7 && b[0] == "#", "Invalid hex color format");

    uint24 result = 0;
    for (uint i = 1; i < 7; i++) {
        uint8 digit = uint8(b[i]);
        if (digit >= 48 && digit <= 57) {
            // 0-9
            result = (result << 4) | (digit - 48);
        } else if (digit >= 97 && digit <= 102) {
            // a-f
            result = (result << 4) | (digit - 87);
        } else if (digit >= 65 && digit <= 70) {
            // A-F
            result = (result << 4) | (digit - 55);
        } else {
            revert("Invalid hex character");
        }
    }
    return result;
}

function blendColors(
    uint8 r1,
    uint8 g1,
    uint8 b1,
    string memory hexColor
) pure returns (string memory) {
    // Modify the hex color with the rgb values using a 75% blend
    uint24 color = hexToUint24(hexColor);
    uint8 r2 = uint8(color >> 16);
    uint8 g2 = uint8((color >> 8) & 0xFF);
    uint8 b2 = uint8(color & 0xFF);

    uint8 r = (r1 * 25 + r2 * 75) / 100;
    uint8 g = (g1 * 25 + g2 * 75) / 100;
    uint8 b = (b1 * 25 + b2 * 75) / 100;

    return
        string(
            abi.encodePacked(
                "#",
                toHexString(r),
                toHexString(g),
                toHexString(b)
            )
        );
}

function toHexString(uint8 value) pure returns (string memory) {
    bytes memory buffer = new bytes(2);
    buffer[0] = bytes1(uint8((value >> 4) + (value >> 4 < 10 ? 48 : 87)));
    buffer[1] = bytes1(uint8((value & 0x0F) + ((value & 0x0F) < 10 ? 48 : 87)));
    return string(buffer);
}
