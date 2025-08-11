import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";

describe("Line of Sight System", function () {
  let lineOfSight: any;
  let userLineOfSight: any;
  let owner: any;
  let user: any;

  async function deployLineOfSightFixture() {
    const [ownerAccount, userAccount] = await hre.viem.getWalletClients();

    const lineOfSightContract = await hre.viem.deployContract(
      "LineOfSight",
      []
    );

    // Create separate contract instances for each user
    const userLineOfSight = await hre.viem.getContractAt(
      "LineOfSight",
      lineOfSightContract.address,
      {
        client: { wallet: userAccount },
      }
    );

    return {
      lineOfSight: lineOfSightContract,
      userLineOfSight: userLineOfSight,
      owner: ownerAccount,
      user: userAccount,
    };
  }

  beforeEach(async function () {
    const fixture = await loadFixture(deployLineOfSightFixture);
    lineOfSight = fixture.lineOfSight;
    userLineOfSight = fixture.userLineOfSight;
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
      await lineOfSight.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });
    }
  }

  describe("Basic Functionality", function () {
    it("Should deploy with correct grid dimensions", async function () {
      const gridWidth = await lineOfSight.read.GRID_WIDTH();
      const gridHeight = await lineOfSight.read.GRID_HEIGHT();

      expect(gridWidth).to.equal(100);
      expect(gridHeight).to.equal(50);
    });

    it("Should allow owner to set blocked tiles", async function () {
      const gameId = 1;
      const row = 5;
      const col = 10;

      await lineOfSight.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });

      const isBlocked = await lineOfSight.read.isTileBlocked([
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
      await lineOfSight.write.setBlockedTile([BigInt(gameId), row, col, true], {
        account: owner.address,
      });

      // Then unblock it
      await lineOfSight.write.setBlockedTile(
        [BigInt(gameId), row, col, false],
        {
          account: owner.address,
        }
      );

      const isBlocked = await lineOfSight.read.isTileBlocked([
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
        userLineOfSight.write.setBlockedTile([BigInt(gameId), row, col, true])
      ).to.be.rejected;
    });
  });

  describe("Boundary Validation", function () {
    it("Should revert when setting tiles outside grid bounds", async function () {
      const gameId = 1;

      // Test negative coordinates
      await expect(
        lineOfSight.write.setBlockedTile([BigInt(gameId), -1, 0, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      await expect(
        lineOfSight.write.setBlockedTile([BigInt(gameId), 0, -1, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      // Test coordinates beyond grid size
      await expect(
        lineOfSight.write.setBlockedTile([BigInt(gameId), 50, 0, true], {
          account: owner.address,
        })
      ).to.be.rejected;

      await expect(
        lineOfSight.write.setBlockedTile([BigInt(gameId), 0, 100, true], {
          account: owner.address,
        })
      ).to.be.rejected;
    });

    it("Should revert when checking LOS outside grid bounds", async function () {
      const gameId = 1;

      // Test negative coordinates
      await expect(
        lineOfSight.read.hasLineOfSight([BigInt(gameId), -1, 0, 5, 5])
      ).to.be.rejected;

      await expect(
        lineOfSight.read.hasLineOfSight([BigInt(gameId), 0, -1, 5, 5])
      ).to.be.rejected;

      // Test coordinates beyond grid size
      await expect(
        lineOfSight.read.hasLineOfSight([BigInt(gameId), 50, 0, 5, 5])
      ).to.be.rejected;

      await expect(
        lineOfSight.read.hasLineOfSight([BigInt(gameId), 0, 100, 5, 5])
      ).to.be.rejected;
    });
  });

  describe("Line of Sight Scenarios", function () {
    describe("Clear Line of Sight", function () {
      it("Should have clear LOS on horizontal line", async function () {
        const gameId = 1;
        const startPos: [number, number] = [5, 2];
        const endPos: [number, number] = [5, 8];

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

        const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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
      await lineOfSight.write.setBlockedTile(
        [BigInt(game1Id), row, col, true],
        {
          account: owner.address,
        }
      );

      // Check that game 2 is not affected
      const isBlockedInGame1 = await lineOfSight.read.isTileBlocked([
        BigInt(game1Id),
        row,
        col,
      ]);
      const isBlockedInGame2 = await lineOfSight.read.isTileBlocked([
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
      await lineOfSight.write.setBlockedTile([BigInt(game1Id), 2, 2, true], {
        account: owner.address,
      });

      const hasLOSInGame1 = await lineOfSight.read.hasLineOfSight([
        BigInt(game1Id),
        startPos[0],
        startPos[1],
        endPos[0],
        endPos[1],
      ]);
      const hasLOSInGame2 = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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

      const hasLOS = await lineOfSight.read.hasLineOfSight([
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
});
