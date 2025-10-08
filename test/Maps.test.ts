import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";

describe("Line of Sight System", function () {
  let maps: any;
  let userMaps: any;
  let owner: any;
  let user: any;

  async function deployMapsFixture() {
    const [ownerAccount, userAccount] = await hre.viem.getWalletClients();

    const mapsContract = await hre.viem.deployContract("Maps", []);

    // Create separate contract instances for each user
    const userMaps = await hre.viem.getContractAt(
      "Maps",
      mapsContract.address,
      {
        client: { wallet: userAccount },
      }
    );

    return {
      maps: mapsContract,
      userMaps: userMaps,
      owner: ownerAccount,
      user: userAccount,
    };
  }

  beforeEach(async function () {
    const fixture = await loadFixture(deployMapsFixture);
    maps = fixture.maps;
    userMaps = fixture.userMaps;
    owner = fixture.owner;
    user = fixture.user;
  });

  // Helper function to create visual grid diagrams
  function createGridDiagram(
    width: number,
    height: number,
    startPos: [number, number],
    endPos: [number, number],
    blockedPositions: [number, number][],
    hasLOS: boolean
  ): string {
    let diagram = `\nGrid: ${width}x${height} | LOS: ${hasLOS ? "✅" : "❌"}\n`;
    diagram += "  " + "0123456789".repeat(Math.ceil(width / 10)) + "\n";

    for (let row = 0; row < height; row++) {
      let rowStr = `${row.toString().padStart(2)} `;
      for (let col = 0; col < width; col++) {
        if (row === startPos[0] && col === startPos[1]) {
          rowStr += "S"; // Start position
        } else if (row === endPos[0] && col === endPos[1]) {
          rowStr += "E"; // End position
        } else if (blockedPositions.some(([r, c]) => r === row && c === col)) {
          rowStr += "█"; // Blocked tile
        } else {
          rowStr += "·"; // Empty tile
        }
      }
      diagram += rowStr + "\n";
    }
    diagram += "Legend: S=Start, E=End, █=Blocked, ·=Empty\n";
    return diagram;
  }

  // Helper function to set multiple blocked tiles
  async function setBlockedTiles(
    gameId: number,
    positions: [number, number][]
  ) {
    for (const [row, col] of positions) {
      await maps.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });
    }
  }

  // Helper function to set multiple scoring tiles
  async function setScoringTiles(
    gameId: number,
    positions: [number, number][]
  ) {
    for (const [row, col] of positions) {
      await maps.write.setScoringTile([BigInt(gameId), row, col, 1], {
        account: owner.address,
      });
    }
  }

  describe("Basic Functionality", function () {
    it("Should deploy with correct grid dimensions", async function () {
      const gridWidth = await maps.read.GRID_WIDTH();
      const gridHeight = await maps.read.GRID_HEIGHT();

      expect(gridWidth).to.equal(25);
      expect(gridHeight).to.equal(13);
    });

    it("Should allow owner to set blocked tiles", async function () {
      const gameId = 1;
      const row = 5;
      const col = 10;

      await maps.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });

      const isBlocked = await maps.read.isTileBlocked([
        BigInt(gameId),
        row,
        col,
      ]);
      expect(isBlocked).to.be.true;
    });

    it("Should allow owner to unblock tiles", async function () {
      const gameId = 1;
      const row = 5;
      const col = 10;

      // First block it
      await maps.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });

      // Then unblock it
      await maps.write.setBlockedTile([BigInt(gameId), row, col, false], {
        account: owner.address,
      });

      const isBlocked = await maps.read.isTileBlocked([
        BigInt(gameId),
        row,
        col,
      ]);
      expect(isBlocked).to.be.false;
    });

    it("Should revert when non-owner tries to set blocked tiles", async function () {
      const gameId = 1;
      const row = 5;
      const col = 10;

      await expect(
        userMaps.write.setBlockedTile([BigInt(gameId), row, col, true])
      ).to.be.rejected;
    });
  });

  describe("Boundary Validation", function () {
    it("Should revert when setting tiles outside grid bounds", async function () {
      const gameId = 1;

      // Test negative coordinates
      await expect(
        maps.write.setBlockedTile([BigInt(gameId), -1, 0, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      await expect(
        maps.write.setBlockedTile([BigInt(gameId), 0, -1, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      // Test coordinates beyond grid size
      await expect(
        maps.write.setBlockedTile([BigInt(gameId), 50, 0, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      await expect(
        maps.write.setBlockedTile([BigInt(gameId), 0, 100, true], {
          account: owner.address,
        })
      ).to.be.rejected;
    });

    it("Should revert when checking LOS outside grid bounds", async function () {
      const gameId = 1;

      // Test negative coordinates
      await expect(maps.read.hasMaps([BigInt(gameId), -1, 0, 5, 5])).to.be
        .rejected;

      await expect(maps.read.hasMaps([BigInt(gameId), 0, -1, 5, 5])).to.be
        .rejected;

      // Test coordinates beyond grid size
      await expect(maps.read.hasMaps([BigInt(gameId), 50, 0, 5, 5])).to.be
        .rejected;

      await expect(maps.read.hasMaps([BigInt(gameId), 0, 100, 5, 5])).to.be
        .rejected;
    });
  });

  describe("Line of Sight Scenarios", function () {
    describe("Clear Line of Sight", function () {
      it("Should have clear LOS on horizontal line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [5, 2];
        const endPos: [number, number] = [5, 8];

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should have clear LOS on vertical line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 5];
        const endPos: [number, number] = [8, 5];

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should have clear LOS on diagonal line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 2];
        const endPos: [number, number] = [6, 6];

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should have clear LOS on same position", async function () {
        const gameId = 1;
        const pos: [number, number] = [5, 5];

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          pos[0],
          pos[1],
          pos[0],
          pos[1],
        ]);

        console.log(createGridDiagram(10, 10, pos, pos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });
    });

    describe("Blocked Line of Sight", function () {
      it("Should be blocked by single obstacle on horizontal line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [5, 2];
        const endPos: [number, number] = [5, 8];
        const blockedPositions: [number, number][] = [[5, 5]];

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(10, 10, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });

      it("Should be blocked by single obstacle on vertical line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 5];
        const endPos: [number, number] = [8, 5];
        const blockedPositions: [number, number][] = [[5, 5]];

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(10, 10, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });

      it("Should be blocked by single obstacle on diagonal line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 2];
        const endPos: [number, number] = [6, 6];
        const blockedPositions: [number, number][] = [[4, 4]];

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(10, 10, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });
    });

    describe("Corner Cases and Edge Scenarios", function () {
      it("Should handle permissive corner mode - single flanker blocked", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 2];
        const endPos: [number, number] = [4, 4];
        // Block only one flanker - should still have LOS due to permissive mode
        const blockedPositions: [number, number][] = [[3, 2]]; // Only left flanker blocked

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(6, 6, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.true;
      });

      it("Should block LOS when both flankers are blocked (corner case)", async function () {
        const gameId = 1;
        const startPos: [number, number] = [2, 2];
        const endPos: [number, number] = [4, 4];
        // Block both flankers - should block LOS
        const blockedPositions: [number, number][] = [
          [3, 2],
          [2, 3],
        ]; // Both flankers blocked

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(6, 6, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });

      it("Should handle steep diagonal lines", async function () {
        const gameId = 1;
        const startPos: [number, number] = [1, 1];
        const endPos: [number, number] = [8, 2]; // Very steep diagonal

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should handle shallow diagonal lines", async function () {
        const gameId = 1;
        const startPos: [number, number] = [1, 1];
        const endPos: [number, number] = [2, 8]; // Very shallow diagonal

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });
    });

    describe("Complex Obstacle Patterns", function () {
      it("Should navigate around L-shaped obstacle", async function () {
        const gameId = 1;
        const startPos: [number, number] = [1, 1];
        const endPos: [number, number] = [5, 5];
        const blockedPositions: [number, number][] = [
          [2, 2],
          [2, 3],
          [2, 4], // Horizontal part of L
          [3, 2],
          [4, 2], // Vertical part of L
        ];

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(7, 7, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });

      it("Should be blocked by wall with gap but diagonal path blocked", async function () {
        const gameId = 1;
        const startPos: [number, number] = [1, 1];
        const endPos: [number, number] = [5, 5];
        const blockedPositions: [number, number][] = [
          [2, 2],
          [2, 3],
          [2, 4], // Wall with gap
          [3, 3], // Diagonal path blocked
          [4, 2],
          [4, 3],
          [4, 4], // Wall with gap
        ];

        await setBlockedTiles(gameId, blockedPositions);

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(
          createGridDiagram(7, 7, startPos, endPos, blockedPositions, hasLOS)
        );
        expect(hasLOS).to.be.false;
      });
    });

    describe("Grid Boundary Scenarios", function () {
      it("Should handle LOS to grid edge", async function () {
        const gameId = 1;
        const startPos: [number, number] = [5, 5];
        const endPos: [number, number] = [0, 0]; // Top-left corner

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should handle LOS from grid edge", async function () {
        const gameId = 1;
        const startPos: [number, number] = [0, 0]; // Top-left corner
        const endPos: [number, number] = [5, 5];

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });

      it("Should handle LOS along grid edges", async function () {
        const gameId = 1;
        const startPos: [number, number] = [0, 0];
        const endPos: [number, number] = [0, 9]; // Along top edge

        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          startPos[0],
          startPos[1],
          endPos[0],
          endPos[1],
        ]);

        console.log(createGridDiagram(10, 10, startPos, endPos, [], hasLOS));
        expect(hasLOS).to.be.true;
      });
    });
  });

  describe("Bresenham Algorithm Edge Cases", function () {
    it("Should handle perfect diagonal with even dimensions", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [4, 4]; // Perfect diagonal

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(6, 6, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle perfect diagonal with odd dimensions", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [5, 5]; // Perfect diagonal with odd dimensions

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(7, 7, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle tie case in Bresenham algorithm", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [6, 3]; // Creates tie case in algorithm

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(7, 7, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle tie case with obstacle on diagonal path", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [6, 3]; // Creates tie case
      const blockedPositions: [number, number][] = [[3, 1]]; // Block diagonal path

      await setBlockedTiles(gameId, blockedPositions);

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(
        createGridDiagram(7, 7, startPos, endPos, blockedPositions, hasLOS)
      );
      expect(hasLOS).to.be.false;
    });
  });

  describe("Game Isolation", function () {
    it("Should isolate blocked tiles between different games", async function () {
      const game1Id = 1;
      const game2Id = 2;
      const row = 5;
      const col = 5;

      // Block tile in game 1
      await maps.write.setBlockedTile([BigInt(game1Id), row, col, true], {
        account: owner.address,
      });

      // Check that game 2 is not affected
      const isBlockedInGame1 = await maps.read.isTileBlocked([
        BigInt(game1Id),
        row,
        col,
      ]);
      const isBlockedInGame2 = await maps.read.isTileBlocked([
        BigInt(game2Id),
        row,
        col,
      ]);

      expect(isBlockedInGame1).to.be.true;
      expect(isBlockedInGame2).to.be.false;
    });

    it("Should have different LOS results for same positions in different games", async function () {
      const game1Id = 1;
      const game2Id = 2;
      const startPos: [number, number] = [1, 1];
      const endPos: [number, number] = [3, 3];

      // Block diagonal path in game 1 only
      await maps.write.setBlockedTile([BigInt(game1Id), 2, 2, true], {
        account: owner.address,
      });

      const hasLOSInGame1 = await maps.read.hasMaps([
        BigInt(game1Id),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);
      const hasLOSInGame2 = await maps.read.hasMaps([
        BigInt(game2Id),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      expect(hasLOSInGame1).to.be.false;
      expect(hasLOSInGame2).to.be.true;
    });
  });

  describe("Stress Tests", function () {
    it("Should handle long horizontal line", async function () {
      const gameId = 1;
      const startPos: [number, number] = [10, 0];
      const endPos: [number, number] = [10, 24]; // Full width of grid

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(40, 20, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle long vertical line", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 24];
      const endPos: [number, number] = [12, 20]; // Full height of grid

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(40, 20, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle long diagonal line", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [12, 12]; // Full diagonal

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(40, 20, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle zigzag obstacle pattern", async function () {
      const gameId = 1;
      const startPos: [number, number] = [1, 1];
      const endPos: [number, number] = [8, 8];
      const blockedPositions: [number, number][] = [
        [2, 2],
        [2, 3],
        [2, 4],
        [2, 5],
        [2, 6], // Horizontal wall
        [4, 2],
        [4, 3],
        [4, 4],
        [4, 5],
        [4, 6], // Horizontal wall
        [6, 2],
        [6, 3],
        [6, 4],
        [6, 5],
        [6, 6], // Horizontal wall
      ];

      await setBlockedTiles(gameId, blockedPositions);

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(
        createGridDiagram(10, 10, startPos, endPos, blockedPositions, hasLOS)
      );
      expect(hasLOS).to.be.false;
    });
  });

  describe("Preset Maps", function () {
    describe("Map Creation", function () {
      it("Should allow owner to create preset maps", async function () {
        const blockedPositions = [
          { row: 5, col: 5 },
          { row: 5, col: 6 },
          { row: 6, col: 5 },
          { row: 6, col: 6 },
        ];

        // Get initial map count
        const initialMapCount = await maps.read.mapCount();
        expect(initialMapCount).to.equal(0n);

        // Create the map (this returns a transaction hash, not the map ID)
        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        // Check that map count increased
        const newMapCount = await maps.read.mapCount();
        expect(newMapCount).to.equal(1n);

        // The new map ID should be the new map count
        const newMapId = newMapCount;

        // Verify the map was created by checking if it exists
        expect(await maps.read.mapExists([newMapId])).to.be.true;
      });

      it("Should create multiple maps with sequential IDs", async function () {
        const positions1 = [{ row: 1, col: 1 }];
        const positions2 = [{ row: 2, col: 2 }];

        // Create first map
        await maps.write.createPresetMap([positions1], {
          account: owner.address,
        });

        // Check first map was created
        const mapCount1 = await maps.read.mapCount();
        expect(mapCount1).to.equal(1n);
        expect(await maps.read.mapExists([1n])).to.be.true;

        // Create second map
        await maps.write.createPresetMap([positions2], {
          account: owner.address,
        });

        // Check second map was created
        const mapCount2 = await maps.read.mapCount();
        expect(mapCount2).to.equal(2n);
        expect(await maps.read.mapExists([2n])).to.be.true;
      });

      it("Should revert when non-owner tries to create preset maps", async function () {
        const blockedPositions = [{ row: 5, col: 5 }];

        await expect(userMaps.write.createPresetMap([blockedPositions])).to.be
          .rejected;
      });

      it("Should validate positions when creating maps", async function () {
        const invalidPositions = [
          { row: -1, col: 5 }, // Invalid row
          { row: 5, col: 100 }, // Invalid col
        ];

        await expect(
          maps.write.createPresetMap([invalidPositions], {
            account: owner.address,
          })
        ).to.be.rejected;
      });
    });

    describe("Map Retrieval", function () {
      it("Should retrieve preset map correctly", async function () {
        const blockedPositions = [
          { row: 5, col: 5 },
          { row: 5, col: 6 },
          { row: 6, col: 5 },
        ];

        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const retrievedPositions = await maps.read.getPresetMap([mapId]);

        expect(retrievedPositions.length).to.equal(3);

        // Check that all positions are present
        const positionStrings = retrievedPositions.map(
          (p: any) => `${p.row},${p.col}`
        );
        expect(positionStrings).to.include("5,5");
        expect(positionStrings).to.include("5,6");
        expect(positionStrings).to.include("6,5");
      });

      it("Should return empty array for map with no blocked positions", async function () {
        const emptyPositions: any[] = [];

        await maps.write.createPresetMap([emptyPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const retrievedPositions = await maps.read.getPresetMap([mapId]);
        expect(retrievedPositions.length).to.equal(0);
      });

      it("Should revert when retrieving non-existent map", async function () {
        await expect(maps.read.getPresetMap([999])).to.be.rejected;
      });
    });

    describe("Map Updates", function () {
      it("Should allow owner to update existing preset maps", async function () {
        const initialPositions = [{ row: 5, col: 5 }];
        const updatedPositions = [{ row: 6, col: 6 }];

        await maps.write.createPresetMap([initialPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        await maps.write.updatePresetMap([mapId, updatedPositions], {
          account: owner.address,
        });

        const retrievedPositions = await maps.read.getPresetMap([mapId]);

        expect(retrievedPositions.length).to.equal(1);
        expect(retrievedPositions[0].row).to.equal(6);
        expect(retrievedPositions[0].col).to.equal(6);
      });

      it("Should clear all positions when updating map", async function () {
        const initialPositions = [
          { row: 5, col: 5 },
          { row: 5, col: 6 },
        ];

        await maps.write.createPresetMap([initialPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        // Update with fewer positions
        const updatedPositions = [{ row: 6, col: 6 }];
        await maps.write.updatePresetMap([mapId, updatedPositions], {
          account: owner.address,
        });

        const retrievedPositions = await maps.read.getPresetMap([mapId]);
        expect(retrievedPositions.length).to.equal(1);
        expect(retrievedPositions[0].row).to.equal(6);
        expect(retrievedPositions[0].col).to.equal(6);
      });

      it("Should revert when non-owner tries to update maps", async function () {
        const positions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        await expect(userMaps.write.updatePresetMap([mapId, positions])).to.be
          .rejected;
      });

      it("Should revert when updating non-existent map", async function () {
        const positions = [{ row: 5, col: 5 }];

        await expect(
          maps.write.updatePresetMap([999, positions], {
            account: owner.address,
          })
        ).to.be.rejected;
      });

      it("Should allow owner to update map with both blocked and scoring tiles", async function () {
        // Create initial map with some tiles
        const initialBlocked = [{ row: 5, col: 5 }];
        const initialScoring = [
          { row: 10, col: 10, points: 5, onlyOnce: false },
        ];
        await maps.write.createPresetMap([initialBlocked, initialScoring], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();

        // Update with new blocked and scoring tiles
        const newBlocked = [
          { row: 10, col: 10 },
          { row: 12, col: 12 },
        ];
        const newScoring = [
          { row: 5, col: 5, points: 10, onlyOnce: true },
          { row: 12, col: 12, points: 15, onlyOnce: false },
        ];

        await maps.write.updatePresetMap([mapId, newBlocked, newScoring], {
          account: owner.address,
        });

        // Verify old tiles are cleared
        const retrievedBlocked = await maps.read.getPresetMap([mapId]);
        const retrievedScoring = await maps.read.getPresetScoringMap([mapId]);

        expect(retrievedBlocked).to.have.length(2);
        expect(retrievedBlocked[0]).to.deep.equal({ row: 10, col: 10 });
        expect(retrievedBlocked[1]).to.deep.equal({ row: 12, col: 12 });

        expect(retrievedScoring).to.have.length(2);
        expect(retrievedScoring[0]).to.deep.equal({
          row: 5,
          col: 5,
          points: 10,
          onlyOnce: true,
        });
        expect(retrievedScoring[1]).to.deep.equal({
          row: 12,
          col: 12,
          points: 15,
          onlyOnce: false,
        });
      });

      it("Should allow owner to update map with only blocked tiles", async function () {
        // Create initial map
        const initialBlocked = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([initialBlocked], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();

        // Update with new blocked tiles only
        const newBlocked = [
          { row: 10, col: 10 },
          { row: 12, col: 12 },
        ];

        await maps.write.updatePresetMap([mapId, newBlocked, []], {
          account: owner.address,
        });

        // Verify update
        const retrievedBlocked = await maps.read.getPresetMap([mapId]);
        const retrievedScoring = await maps.read.getPresetScoringMap([mapId]);

        expect(retrievedBlocked).to.have.length(2);
        expect(retrievedScoring).to.have.length(0);
      });

      it("Should allow owner to update map with only scoring tiles", async function () {
        // Create initial map
        const initialScoring = [
          { row: 10, col: 10, points: 5, onlyOnce: false },
        ];
        await maps.write.createPresetScoringMap([initialScoring], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();

        // Update with new scoring tiles only
        const newScoring = [
          { row: 5, col: 5, points: 10, onlyOnce: true },
          { row: 12, col: 12, points: 15, onlyOnce: false },
        ];

        await maps.write.updatePresetMap([mapId, [], newScoring], {
          account: owner.address,
        });

        // Verify update
        const retrievedBlocked = await maps.read.getPresetMap([mapId]);
        const retrievedScoring = await maps.read.getPresetScoringMap([mapId]);

        expect(retrievedBlocked).to.have.length(0);
        expect(retrievedScoring).to.have.length(2);
      });
    });

    describe("Map Application to Games", function () {
      it("Should apply preset map to game correctly", async function () {
        const blockedPositions = [
          { row: 5, col: 5 },
          { row: 5, col: 6 },
        ];

        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;
        await maps.write.applyPresetMapToGame([BigInt(gameId), mapId], {
          account: owner.address,
        });

        // Check that the game now has the blocked tiles
        expect(await maps.read.isTileBlocked([BigInt(gameId), 5, 5])).to.be
          .true;
        expect(await maps.read.isTileBlocked([BigInt(gameId), 5, 6])).to.be
          .true;
        expect(await maps.read.isTileBlocked([BigInt(gameId), 6, 6])).to.be
          .false; // Not blocked
      });

      it("Should apply map without affecting other games", async function () {
        const blockedPositions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const game1Id = 123;
        const game2Id = 456;

        // Apply map to game 1
        await maps.write.applyPresetMapToGame([BigInt(game1Id), mapId], {
          account: owner.address,
        });

        // Check that game 1 has blocked tile
        expect(await maps.read.isTileBlocked([BigInt(game1Id), 5, 5])).to.be
          .true;

        // Check that game 2 is unaffected
        expect(await maps.read.isTileBlocked([BigInt(game2Id), 5, 5])).to.be
          .false;
      });

      it("Should revert when non-owner tries to apply map to game", async function () {
        const blockedPositions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;
        await expect(
          userMaps.write.applyPresetMapToGame([BigInt(gameId), mapId])
        ).to.be.rejected;
      });

      it("Should revert when applying non-existent map to game", async function () {
        const gameId = 123;
        await expect(
          maps.write.applyPresetMapToGame([BigInt(gameId), 999], {
            account: owner.address,
          })
        ).to.be.rejected;
      });
    });

    describe("Map Existence Checks", function () {
      it("Should correctly identify existing maps", async function () {
        const positions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        expect(await maps.read.mapExists([mapId])).to.be.true;
        expect(await maps.read.mapExists([999])).to.be.false;
        expect(await maps.read.mapExists([0])).to.be.false;
      });

      it("Should handle edge cases for map existence", async function () {
        // No maps created yet
        expect(await maps.read.mapExists([1])).to.be.false;
        expect(await maps.read.mapExists([0])).to.be.false;
      });
    });

    describe("Get All Preset Maps", function () {
      it("Should return all preset map IDs", async function () {
        // Create first map with both blocked and scoring tiles
        const blockedPositions1 = [
          { row: 5, col: 5 },
          { row: 6, col: 6 },
        ];
        const scoringPositions1 = [
          { row: 10, col: 10, points: 5, onlyOnce: false },
        ];
        await maps.write.createPresetMap(
          [blockedPositions1, scoringPositions1],
          {
            account: owner.address,
          }
        );

        // Create second map with only blocked tiles
        const blockedPositions2 = [{ row: 12, col: 12 }];
        await maps.write.createPresetMap([blockedPositions2], {
          account: owner.address,
        });

        // Create third map with only scoring tiles
        const scoringPositions3 = [
          { row: 10, col: 10, points: 10, onlyOnce: true },
          { row: 11, col: 11, points: 15, onlyOnce: false },
        ];
        await maps.write.createPresetScoringMap([scoringPositions3], {
          account: owner.address,
        });

        // Get all map IDs
        const mapIds = await maps.read.getAllPresetMapIds();

        // Verify we have 3 maps
        expect(mapIds).to.have.length(3);

        // Verify map IDs
        expect(mapIds[0]).to.equal(1n);
        expect(mapIds[1]).to.equal(2n);
        expect(mapIds[2]).to.equal(3n);

        // Verify individual maps can be retrieved
        const map1Blocked = await maps.read.getPresetMap([1n]);
        const map1Scoring = await maps.read.getPresetScoringMap([1n]);
        expect(map1Blocked).to.have.length(2);
        expect(map1Scoring).to.have.length(1);

        const map2Blocked = await maps.read.getPresetMap([2n]);
        const map2Scoring = await maps.read.getPresetScoringMap([2n]);
        expect(map2Blocked).to.have.length(1);
        expect(map2Scoring).to.have.length(0);

        const map3Blocked = await maps.read.getPresetMap([3n]);
        const map3Scoring = await maps.read.getPresetScoringMap([3n]);
        expect(map3Blocked).to.have.length(0);
        expect(map3Scoring).to.have.length(2);
      });

      it("Should return empty array when no maps exist", async function () {
        const mapIds = await maps.read.getAllPresetMapIds();
        expect(mapIds).to.have.length(0);
      });
    });

    describe("Integration with Line of Sight", function () {
      it("Should respect preset map when calculating line of sight", async function () {
        const blockedPositions = [
          { row: 5, col: 5 },
          { row: 5, col: 6 },
        ];

        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;
        await maps.write.applyPresetMapToGame([BigInt(gameId), mapId], {
          account: owner.address,
        });

        // Test line of sight that should be blocked by the preset map
        const hasLOS = await maps.read.hasMaps([
          BigInt(gameId),
          5,
          2, // Start position
          5,
          8, // End position (horizontal line through blocked tiles)
        ]);

        expect(hasLOS).to.be.false;
      });

      it("Should allow additional blocked tiles after applying preset map", async function () {
        const presetPositions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([presetPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;
        await maps.write.applyPresetMapToGame([BigInt(gameId), mapId], {
          account: owner.address,
        });

        // Add additional blocked tile
        await maps.write.setBlockedTile([BigInt(gameId), 6, 6, true], {
          account: owner.address,
        });

        // Check that both preset and additional blocked tiles are active
        expect(await maps.read.isTileBlocked([BigInt(gameId), 5, 5])).to.be
          .true; // Preset
        expect(await maps.read.isTileBlocked([BigInt(gameId), 6, 6])).to.be
          .true; // Additional
      });
    });
  });

  describe("Scoring Tiles", function () {
    describe("Basic Scoring Tile Operations", function () {
      it("Should allow owner to set scoring tiles", async function () {
        const gameId = 1;
        const row = 5;
        const col = 10;

        await maps.write.setScoringTile([BigInt(gameId), row, col, 1], {
          account: owner.address,
        });

        const isScoring = await maps.read.isTileScoring([
          BigInt(gameId),
          row,
          col,
        ]);
        expect(isScoring).to.equal(1);
      });

      it("Should allow owner to unset scoring tiles", async function () {
        const gameId = 1;
        const row = 5;
        const col = 10;

        // First set it as scoring
        await maps.write.setScoringTile([BigInt(gameId), row, col, 1], {
          account: owner.address,
        });

        // Then unset it
        await maps.write.setScoringTile([BigInt(gameId), row, col, 0], {
          account: owner.address,
        });

        const isScoring = await maps.read.isTileScoring([
          BigInt(gameId),
          row,
          col,
        ]);
        expect(isScoring).to.equal(0);
      });

      it("Should revert when non-owner tries to set scoring tiles", async function () {
        const gameId = 1;
        const row = 5;
        const col = 10;

        await expect(
          userMaps.write.setScoringTile([BigInt(gameId), row, col, 1])
        ).to.be.rejected;
      });

      it("Should revert when setting scoring tiles outside grid bounds", async function () {
        const gameId = 1;

        // Test negative coordinates
        await expect(
          maps.write.setScoringTile([BigInt(gameId), -1, 0, 1], {
            account: owner.address,
          })
        ).to.be.rejected;

        await expect(
          maps.write.setScoringTile([BigInt(gameId), 0, -1, 1], {
            account: owner.address,
          })
        ).to.be.rejected;

        // Test coordinates beyond grid size
        await expect(
          maps.write.setScoringTile([BigInt(gameId), 50, 0, 1], {
            account: owner.address,
          })
        ).to.be.rejected;

        await expect(
          maps.write.setScoringTile([BigInt(gameId), 0, 100, 1], {
            account: owner.address,
          })
        ).to.be.rejected;
      });
    });

    describe("Preset Scoring Maps", function () {
      it("Should allow owner to create preset scoring maps", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
          { row: 10, col: 10, points: 2, onlyOnce: true },
          { row: 12, col: 12, points: 3, onlyOnce: false },
        ];

        const initialMapCount = await maps.read.mapCount();
        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });

        const newMapCount = await maps.read.mapCount();
        expect(newMapCount).to.equal(initialMapCount + 1n);

        // Verify scoring positions are set
        const mapId = newMapCount;
        expect(await maps.read.presetScoringMaps([mapId, 5, 5])).to.equal(1);
        expect(await maps.read.presetScoringMaps([mapId, 10, 10])).to.equal(2);
        expect(await maps.read.presetScoringMaps([mapId, 12, 12])).to.equal(3);

        // Verify other positions are not scoring
        expect(await maps.read.presetScoringMaps([mapId, 0, 0])).to.equal(0);
      });

      it("Should allow owner to create multiple preset scoring maps", async function () {
        const positions1 = [{ row: 1, col: 1, points: 1, onlyOnce: false }];
        const positions2 = [{ row: 2, col: 2, points: 1, onlyOnce: true }];

        await maps.write.createPresetScoringMap([positions1], {
          account: owner.address,
        });
        await maps.write.createPresetScoringMap([positions2], {
          account: owner.address,
        });

        const mapCount = await maps.read.mapCount();
        expect(mapCount).to.equal(2n);
      });

      it("Should revert when non-owner tries to create preset scoring maps", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
        ];

        await expect(userMaps.write.createPresetScoringMap([scoringPositions]))
          .to.be.rejected;
      });

      it("Should revert when creating preset scoring map with invalid positions", async function () {
        const invalidPositions = [
          { row: 20, col: 40, points: 1, onlyOnce: false },
        ];

        await expect(
          maps.write.createPresetScoringMap([invalidPositions], {
            account: owner.address,
          })
        ).to.be.rejected;
      });

      it("Should retrieve preset scoring map correctly", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
          { row: 10, col: 10, points: 2, onlyOnce: true },
        ];

        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const retrievedPositions = await maps.read.getPresetScoringMap([mapId]);

        expect(retrievedPositions).to.have.length(2);
        expect(retrievedPositions[0].row).to.equal(5);
        expect(retrievedPositions[0].col).to.equal(5);
        expect(retrievedPositions[0].onlyOnce).to.equal(false);
        expect(retrievedPositions[1].row).to.equal(10);
        expect(retrievedPositions[1].col).to.equal(10);
        expect(retrievedPositions[1].onlyOnce).to.equal(true);
      });

      it("Should handle empty preset scoring maps", async function () {
        const emptyPositions: { row: number; col: number }[] = [];

        await maps.write.createPresetScoringMap([emptyPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const retrievedPositions = await maps.read.getPresetScoringMap([mapId]);

        expect(retrievedPositions).to.have.length(0);
      });

      it("Should revert when retrieving non-existent preset scoring map", async function () {
        await expect(maps.read.getPresetScoringMap([999])).to.be.rejected;
      });

      it("Should allow owner to update existing preset scoring maps", async function () {
        const initialPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
        ];
        await maps.write.createPresetScoringMap([initialPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const updatedPositions = [
          { row: 10, col: 10, points: 2, onlyOnce: true },
        ];

        await maps.write.updatePresetScoringMap([mapId, updatedPositions], {
          account: owner.address,
        });

        const retrievedPositions = await maps.read.getPresetScoringMap([mapId]);
        expect(retrievedPositions).to.have.length(1);
        expect(retrievedPositions[0].row).to.equal(10);
        expect(retrievedPositions[0].col).to.equal(10);
        expect(retrievedPositions[0].points).to.equal(2);
        expect(retrievedPositions[0].onlyOnce).to.equal(true);
      });

      it("Should clear all positions when updating preset scoring map", async function () {
        const initialPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
          { row: 10, col: 10, points: 1, onlyOnce: true },
        ];
        await maps.write.createPresetScoringMap([initialPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const updatedPositions = [
          { row: 12, col: 12, points: 2, onlyOnce: false },
        ];

        await maps.write.updatePresetScoringMap([mapId, updatedPositions], {
          account: owner.address,
        });

        const retrievedPositions = await maps.read.getPresetScoringMap([mapId]);
        expect(retrievedPositions).to.have.length(1);
        expect(retrievedPositions[0].row).to.equal(12);
        expect(retrievedPositions[0].col).to.equal(12);
        expect(retrievedPositions[0].onlyOnce).to.equal(false);
      });

      it("Should revert when non-owner tries to update preset scoring maps", async function () {
        const positions = [{ row: 5, col: 5, points: 1, onlyOnce: false }];
        await maps.write.createPresetScoringMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        await expect(userMaps.write.updatePresetScoringMap([mapId, positions]))
          .to.be.rejected;
      });

      it("Should revert when updating non-existent preset scoring map", async function () {
        const positions = [{ row: 5, col: 5, points: 1, onlyOnce: false }];

        await expect(
          maps.write.updatePresetScoringMap([999, positions], {
            account: owner.address,
          })
        ).to.be.rejected;
      });

      it("Should apply preset scoring map to game correctly", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
          { row: 10, col: 10, points: 1, onlyOnce: true },
        ];

        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;

        await maps.write.applyPresetScoringMapToGame([BigInt(gameId), mapId], {
          account: owner.address,
        });

        // Verify scoring tiles are applied to the game
        expect(await maps.read.isTileScoring([BigInt(gameId), 5, 5])).to.equal(
          1
        );
        expect(
          await maps.read.isTileScoring([BigInt(gameId), 10, 10])
        ).to.equal(1);
        expect(await maps.read.isTileScoring([BigInt(gameId), 0, 0])).to.equal(
          0
        );
      });

      it("Should apply preset scoring map to multiple games independently", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
        ];

        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const game1Id = 123;
        const game2Id = 456;

        await maps.write.applyPresetScoringMapToGame([BigInt(game1Id), mapId], {
          account: owner.address,
        });

        // Game 2 should not have scoring tiles yet
        expect(await maps.read.isTileScoring([BigInt(game2Id), 5, 5])).to.equal(
          0
        );

        // Apply to game 2
        await maps.write.applyPresetScoringMapToGame([BigInt(game2Id), mapId], {
          account: owner.address,
        });

        // Now both games should have scoring tiles
        expect(await maps.read.isTileScoring([BigInt(game1Id), 5, 5])).to.equal(
          1
        );
        expect(await maps.read.isTileScoring([BigInt(game2Id), 5, 5])).to.equal(
          1
        );
      });

      it("Should revert when non-owner tries to apply scoring map to game", async function () {
        const scoringPositions = [
          { row: 5, col: 5, points: 1, onlyOnce: false },
        ];
        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        const gameId = 123;
        await expect(
          userMaps.write.applyPresetScoringMapToGame([BigInt(gameId), mapId])
        ).to.be.rejected;
      });

      it("Should revert when applying non-existent scoring map to game", async function () {
        const gameId = 123;
        await expect(
          maps.write.applyPresetScoringMapToGame([BigInt(gameId), 999], {
            account: owner.address,
          })
        ).to.be.rejected;
      });
    });

    describe("Integration with Blocked Tiles", function () {
      it("Should allow tiles to be both blocked and scoring", async function () {
        const gameId = 1;
        const row = 5;
        const col = 5;

        // Set tile as both blocked and scoring
        await maps.write.setBlockedTile([BigInt(gameId), row, col, true], {
          account: owner.address,
        });
        await maps.write.setScoringTile([BigInt(gameId), row, col, 1], {
          account: owner.address,
        });

        // Verify both properties
        expect(await maps.read.isTileBlocked([BigInt(gameId), row, col])).to.be
          .true;
        expect(
          await maps.read.isTileScoring([BigInt(gameId), row, col])
        ).to.equal(1);
      });

      it("Should handle preset maps with both blocked and scoring tiles", async function () {
        const blockedPositions = [{ row: 5, col: 5, points: 1 }];
        const scoringPositions = [
          { row: 10, col: 10, points: 1, onlyOnce: false },
        ];

        // Create preset blocked map
        await maps.write.createPresetMap([blockedPositions], {
          account: owner.address,
        });
        const blockedMapId = await maps.read.mapCount();

        // Create preset scoring map
        await maps.write.createPresetScoringMap([scoringPositions], {
          account: owner.address,
        });
        const scoringMapId = await maps.read.mapCount();

        const gameId = 123;

        // Apply blocked map to the game
        await maps.write.applyPresetMapToGame([BigInt(gameId), blockedMapId], {
          account: owner.address,
        });

        // Apply scoring map to the game
        await maps.write.applyPresetScoringMapToGame(
          [BigInt(gameId), scoringMapId],
          {
            account: owner.address,
          }
        );

        // Verify both blocked and scoring tiles are applied
        expect(await maps.read.isTileBlocked([BigInt(gameId), 5, 5])).to.be
          .true;
        expect(
          await maps.read.isTileScoring([BigInt(gameId), 10, 10])
        ).to.equal(1);
      });

      it("Should maintain separate state for blocked and scoring tiles", async function () {
        const gameId = 1;
        const row = 5;
        const col = 5;

        // Set tile as blocked only
        await maps.write.setBlockedTile([BigInt(gameId), row, col, true], {
          account: owner.address,
        });

        // Verify blocked but not scoring
        expect(await maps.read.isTileBlocked([BigInt(gameId), row, col])).to.be
          .true;
        expect(
          await maps.read.isTileScoring([BigInt(gameId), row, col])
        ).to.equal(0);

        // Set tile as scoring only
        await maps.write.setBlockedTile([BigInt(gameId), row, col, false], {
          account: owner.address,
        });
        await maps.write.setScoringTile([BigInt(gameId), row, col, 1], {
          account: owner.address,
        });

        // Verify scoring but not blocked
        expect(await maps.read.isTileBlocked([BigInt(gameId), row, col])).to.be
          .false;
        expect(
          await maps.read.isTileScoring([BigInt(gameId), row, col])
        ).to.equal(1);
      });
    });

    describe("Safe Scoring Tile Checks", function () {
      it("Should handle out-of-bounds coordinates safely", async function () {
        const gameId = 1;

        // These should not revert and should return 0 for out-of-bounds
        // Note: We can't directly test _isTileScoringSafe as it's internal,
        // but we can test the behavior through public functions
        expect(
          await maps.read.isTileScoringSafe([BigInt(gameId), -1, 0])
        ).to.equal(0);
        expect(
          await maps.read.isTileScoringSafe([BigInt(gameId), 0, -1])
        ).to.equal(0);
        expect(
          await maps.read.isTileScoringSafe([BigInt(gameId), 50, 0])
        ).to.equal(0);
        expect(
          await maps.read.isTileScoringSafe([BigInt(gameId), 0, 100])
        ).to.equal(0);
      });
    });
  });
});
