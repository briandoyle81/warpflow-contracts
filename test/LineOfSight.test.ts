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

  describe("Basic Functionality", function () {
    it("Should deploy with correct grid dimensions", async function () {
      const gridWidth = await maps.read.GRID_WIDTH();
      const gridHeight = await maps.read.GRID_HEIGHT();

      expect(gridWidth).to.equal(100);
      expect(gridHeight).to.equal(50);
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
      const startPos: [number, number] = [25, 0];
      const endPos: [number, number] = [25, 99]; // Full width of grid

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(100, 50, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle long vertical line", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 50];
      const endPos: [number, number] = [49, 50]; // Full height of grid

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(100, 50, startPos, endPos, [], hasLOS));
      expect(hasLOS).to.be.true;
    });

    it("Should handle long diagonal line", async function () {
      const gameId = 1;
      const startPos: [number, number] = [0, 0];
      const endPos: [number, number] = [49, 49]; // Full diagonal

      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);

      console.log(createGridDiagram(100, 50, startPos, endPos, [], hasLOS));
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
    });

    describe("Map Deletion", function () {
      it("Should allow owner to delete preset maps", async function () {
        const positions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        await maps.write.deletePresetMap([mapId], {
          account: owner.address,
        });

        await expect(maps.read.getPresetMap([mapId])).to.be.rejected;
      });

      it("Should decrement map count when deleting last map", async function () {
        const positions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        expect(await maps.read.mapCount()).to.equal(1n);

        await maps.write.deletePresetMap([mapId], {
          account: owner.address,
        });

        expect(await maps.read.mapCount()).to.equal(0n);
      });

      it("Should not decrement map count when deleting non-last map", async function () {
        const positions1 = [{ row: 1, col: 1 }];
        const positions2 = [{ row: 2, col: 2 }];

        await maps.write.createPresetMap([positions1], {
          account: owner.address,
        });
        const mapId1 = await maps.read.mapCount();
        await maps.write.createPresetMap([positions2], {
          account: owner.address,
        });
        const mapId2 = await maps.read.mapCount();

        expect(await maps.read.mapCount()).to.equal(2n);

        // Delete first map
        await maps.write.deletePresetMap([mapId1], {
          account: owner.address,
        });

        expect(await maps.read.mapCount()).to.equal(2n); // Count stays the same
      });

      it("Should revert when non-owner tries to delete maps", async function () {
        const positions = [{ row: 5, col: 5 }];
        await maps.write.createPresetMap([positions], {
          account: owner.address,
        });

        const mapId = await maps.read.mapCount();
        await expect(userMaps.write.deletePresetMap([mapId])).to.be.rejected;
      });

      it("Should revert when deleting non-existent map", async function () {
        await expect(
          maps.write.deletePresetMap([999], {
            account: owner.address,
          })
        ).to.be.rejected;
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
});
