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

function blendHSL(
    uint h,
    uint s,
    uint l,
    string memory hslString
) pure returns (string memory) {
    // Parse the HSL string (format: "hsl(200, 40%, 47%)")
    bytes memory b = bytes(hslString);
    require(b.length >= 10, "Invalid HSL string format");

    // Find the numbers in the string
    uint start = 4; // Skip "hsl("
    uint end = start;
    while (end < b.length && b[end] != ",") end++;
    uint h2 = parseUint(b, start, end);

    start = end + 1;
    while (start < b.length && (b[start] == " " || b[start] == ",")) start++;
    end = start;
    while (end < b.length && b[end] != "%") end++;
    uint s2 = parseUint(b, start, end);

    start = end + 1;
    while (start < b.length && (b[start] == " " || b[start] == ",")) start++;
    end = start;
    while (end < b.length && b[end] != "%") end++;
    uint l2 = parseUint(b, start, end);

    // Blend the values according to the specified ratios
    // H: 50/50 blend
    // Don't change hue too much if saturation is > 40
    uint blendedH;
    if (s2 > 40) {
        blendedH = (h2 * 95 + h * 5) / 100;
    } else {
        blendedH = (h2 * 50 + h * 50) / 100;
    }

    // S: Blend the two values with different ratios based on base saturation
    uint blendedS;
    if (s2 > 40) {
        blendedS = (s2 * 95 + s * 5) / 100;
    } else {
        blendedS = (s2 * 35 + s * 65) / 100;
    }

    // L: 95% old, 5% new
    uint blendedL = (l2 * 85 + l * 15) / 100;

    // Return the blended HSL string
    return
        string(
            abi.encodePacked(
                "hsl(",
                uintToString(blendedH),
                ", ",
                uintToString(blendedS),
                "%, ",
                uintToString(blendedL),
                "%)"
            )
        );
}

function parseUint(bytes memory b, uint start, uint end) pure returns (uint) {
    uint result = 0;
    for (uint i = start; i < end; i++) {
        if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
            result = result * 10 + (uint8(b[i]) - 48);
        }
    }
    return result;
}

function uintToString(uint value) pure returns (string memory) {
    if (value == 0) {
        return "0";
    }

    uint temp = value;
    uint digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }

    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
        value /= 10;
    }

    return string(buffer);
}
