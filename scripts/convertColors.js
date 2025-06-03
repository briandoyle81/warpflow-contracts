const fs = require("fs");
const path = require("path");

// Convert hex to RGB
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) throw new Error("Invalid hex color");
  return {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16),
  };
}

// Convert RGB to HSL
function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }

    h /= 6;
  }

  return {
    h: Math.round(h * 360),
    s: Math.round(s * 100),
    l: Math.round(l * 100),
  };
}

// Convert hex to HSL string
function hexToHslString(hex) {
  const rgb = hexToRgb(hex);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  return `hsl(${hsl.h}, ${hsl.s}%, ${hsl.l}%)`;
}

// Process a single file
function processFile(filePath) {
  console.log(`Processing ${filePath}...`);

  const content = fs.readFileSync(filePath, "utf8");

  let newContent = content;
  let match;
  let replacements = 0;

  // First pass: handle style="fill:#fff;" pattern
  newContent = newContent.replace(
    /style="fill:#([a-fA-F0-9]{3});"/g,
    (match, hexColor) => {
      try {
        // Convert 3-character hex to 6-character hex
        hexColor =
          "#" +
          hexColor[0] +
          hexColor[0] +
          hexColor[1] +
          hexColor[1] +
          hexColor[2] +
          hexColor[2];
        const hslColor = hexToHslString(hexColor);
        replacements++;
        return `style="fill:${hslColor};"`;
      } catch (e) {
        console.error(`Error converting color #${hexColor} in ${filePath}:`, e);
        return match;
      }
    }
  );

  // Second pass: handle style attributes
  newContent = newContent.replace(
    /style="[^"]*fill:([^"]*#[a-fA-F0-9]{3,6})[^"]*"/g,
    (match, hexColor) => {
      try {
        // Convert 3-character hex to 6-character hex
        if (hexColor.length === 4) {
          hexColor =
            "#" +
            hexColor[1] +
            hexColor[1] +
            hexColor[2] +
            hexColor[2] +
            hexColor[3] +
            hexColor[3];
        }
        const hslColor = hexToHslString(hexColor);
        replacements++;
        return match.replace(hexColor, hslColor);
      } catch (e) {
        console.error(`Error converting color ${hexColor} in ${filePath}:`, e);
        return match;
      }
    }
  );

  // Second pass: handle fill attributes
  newContent = newContent.replace(
    /fill="([^"]*#[a-fA-F0-9]{3,6})[^"]*"/g,
    (match, hexColor) => {
      try {
        // Convert 3-character hex to 6-character hex
        if (hexColor.length === 4) {
          hexColor =
            "#" +
            hexColor[1] +
            hexColor[1] +
            hexColor[2] +
            hexColor[2] +
            hexColor[3] +
            hexColor[3];
        }
        const hslColor = hexToHslString(hexColor);
        replacements++;
        return `fill="${hslColor}"`;
      } catch (e) {
        console.error(`Error converting color ${hexColor} in ${filePath}:`, e);
        return match;
      }
    }
  );

  if (replacements > 0) {
    fs.writeFileSync(filePath, newContent);
    console.log(`Made ${replacements} replacements in ${filePath}`);
  } else {
    console.log(`No color replacements needed in ${filePath}`);
  }
}

// Main function
function main() {
  const renderersDir = path.join(__dirname, "../contracts/Renderers");

  // Get all .sol files
  const files = fs
    .readdirSync(renderersDir)
    .filter((file) => file.endsWith(".sol"));

  console.log(`Found ${files.length} Solidity files to process`);

  // Process each file
  files.forEach((file) => {
    const filePath = path.join(renderersDir, file);
    processFile(filePath);
  });

  console.log("Color conversion complete!");
}

main();
