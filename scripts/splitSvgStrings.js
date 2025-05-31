const fs = require("fs");
const path = require("path");

function processFile(filePath) {
  console.log(`Processing ${filePath}...`);

  const content = fs.readFileSync(filePath, "utf8");

  // Find the constant declaration and contract name
  const constantRegex = /string\s+private\s+constant\s+(\w+)\s*=\s*'([^']+)'/;
  const contractRegex = /contract\s+(\w+)/;
  const match = content.match(constantRegex);
  const contractMatch = content.match(contractRegex);

  if (!match || !contractMatch) {
    console.log("No SVG constant or contract found in file");
    return;
  }

  const [_, constantName, svgString] = match;
  const [__, contractName] = contractMatch;

  // Split the SVG into parts and colors
  const parts = [];
  const colors = [];
  let currentPart = "";
  let inStyle = false;

  // Regular expression to match fill colors
  const fillRegex = /style="fill:([^"]+)"/g;
  let fillMatch;
  let lastIndex = 0;

  while ((fillMatch = fillRegex.exec(svgString)) !== null) {
    // Add the part before the style
    const partBeforeStyle = svgString.substring(lastIndex, fillMatch.index);
    if (partBeforeStyle) {
      parts.push(partBeforeStyle);
    }

    // Add the color
    colors.push(fillMatch[1]);

    // Add the closing part
    const closingPart = svgString.substring(
      fillMatch.index + fillMatch[0].length,
      fillMatch.index + fillMatch[0].length + 2
    );
    if (closingPart) {
      parts.push(closingPart);
    }

    lastIndex = fillMatch.index + fillMatch[0].length + 2;
  }

  // Add any remaining part
  if (lastIndex < svgString.length) {
    parts.push(svgString.substring(lastIndex));
  }

  // Generate the new content
  let newContent =
    "// SPDX-License-Identifier: UNLICENSED\npragma solidity ^0.8.28;\n\n";

  // Add imports if they exist
  const importRegex = /import\s+[^;]+;/g;
  const imports = content.match(importRegex);
  if (imports) {
    newContent += imports.join("\n") + "\n\n";
  }

  // Add the contract declaration
  newContent += `contract ${contractName} {\n`;

  // Add the parts
  parts.forEach((part, index) => {
    newContent += `    string private constant PART_${
      index + 1
    } = '${part}';\n`;
  });

  // Add the colors
  colors.forEach((color, index) => {
    newContent += `    string private constant COLOR_${
      index + 1
    } = '${color}';\n`;
  });

  // Add the render function
  newContent +=
    "\n    function render() public pure returns (string memory) {\n        return string.concat(\n";

  // Add all parts and colors in order
  let concatParts = [];
  for (let i = 0; i < parts.length; i++) {
    concatParts.push(`            PART_${i + 1}`);
    if (i < colors.length) {
      concatParts.push(`            COLOR_${i + 1}`);
    }
  }

  newContent += concatParts.join(",\n") + "\n        );\n    }\n}\n";

  // Write the new content back to the file
  fs.writeFileSync(filePath, newContent);
  console.log(`Updated ${filePath}`);
}

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

  console.log("SVG string splitting complete!");
}

main();
