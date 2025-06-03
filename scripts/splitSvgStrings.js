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

  // First pass: Split the string by HSL colors and collect the parts
  const hslRegex = /hsl\([^)]+\)/g;
  const parts = svgString.split(hslRegex);

  // Second pass: Collect all HSL colors
  const colors = [];
  let hslMatch;
  while ((hslMatch = hslRegex.exec(svgString)) !== null) {
    colors.push(hslMatch[0]);
  }

  // Generate the new content
  let newContent =
    "// SPDX-License-Identifier: UNLICENSED\npragma solidity ^0.8.28;\n\n";

  // Add imports if they exist
  const importRegex = /import\s+[^;]+;/g;
  const imports = content.match(importRegex);
  if (imports) {
    newContent += imports.join("\n") + "\n";
  }

  // Add RenderUtils import
  newContent += 'import "./RenderUtils.sol";\n\n';

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

  // Add the render function with chunked concatenation and shiny handling
  newContent +=
    "\n    function render(Ship memory ship) external pure returns (string memory) {\n";

  // Create an array of all parts and colors in order
  let allParts = [];
  for (let i = 0; i < parts.length; i++) {
    allParts.push(`PART_${i + 1}`);
    if (i < colors.length) {
      // Add color with shiny check
      allParts.push(
        `ship.shipData.shiny ? blendHSL(ship.traits.colors.h1, ship.traits.colors.s1, ship.traits.colors.l1, COLOR_${
          i + 1
        }) : COLOR_${i + 1}`
      );
    }
  }

  // Split into chunks of 8
  const chunks = [];
  for (let i = 0; i < allParts.length; i += 8) {
    chunks.push(allParts.slice(i, i + 8));
  }

  // Generate intermediate concatenation functions if needed
  if (chunks.length > 1) {
    chunks.forEach((chunk, index) => {
      newContent += `        string memory chunk${
        index + 1
      } = string.concat(\n`;
      newContent += chunk.map((part) => `            ${part}`).join(",\n");
      newContent += "\n        );\n";
    });

    // Combine all chunks
    newContent += "        return string.concat(\n";
    newContent += chunks
      .map((_, index) => `            chunk${index + 1}`)
      .join(",\n");
    newContent += "\n        );\n";
  } else {
    // If only one chunk, just return it directly
    newContent += "        return string.concat(\n";
    newContent += chunks[0].map((part) => `            ${part}`).join(",\n");
    newContent += "\n        );\n";
  }

  newContent += "    }\n}\n";

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
