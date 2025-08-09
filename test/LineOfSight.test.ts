import { expect } from "chai";
import { ethers } from "hardhat";
import {
  Game,
  Ships,
  ShipAttributes,
  Fleets,
  Lobbies,
} from "../typechain-types";

describe("Line of Sight System", function () {
  let game: Game;
  let ships: Ships;
  let shipAttributes: ShipAttributes;
  let fleets: Fleets;
  let lobbies: Lobbies;
  let owner: any;
  let player1: any;
  let player2: any;
  let gameId: number;

  beforeEach(async function () {
    [owner, player1, player2] = await ethers.getSigners();

    // Deploy contracts (simplified for testing)
    const ShipsFactory = await ethers.getContractFactory("Ships");
    ships = await ShipsFactory.deploy();

    const ShipAttributesFactory = await ethers.getContractFactory(
      "ShipAttributes"
    );
    shipAttributes = await ShipAttributesFactory.deploy();

    const FleetsFactory = await ethers.getContractFactory("Fleets");
    fleets = await FleetsFactory.deploy();

    const LobbiesFactory = await ethers.getContractFactory("Lobbies");
    lobbies = await LobbiesFactory.deploy();

    const GameFactory = await ethers.getContractFactory("Game");
    game = await GameFactory.deploy(
      await ships.getAddress(),
      await shipAttributes.getAddress()
    );

    // Set up addresses
    await game.setLobbiesAddress(await lobbies.getAddress());
    await game.setFleetsAddress(await fleets.getAddress());

    // Create a test game
    gameId = 1;
    // Note: In a real test, you'd need to set up the full game infrastructure
    // This is a simplified version for testing LOS
  });

  describe("Basic Line of Sight", function () {
    it("should allow clear line of sight on empty grid", async function () {
      // Test clear line of sight from (0,0) to (5,5)
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 5);
      expect(hasLOS).to.be.true;
    });

    it("should block line of sight when wall is directly on path", async function () {
      // Set a blocking tile at (2,2)
      await game.setBlockedTile(gameId, 2, 2, true);

      // Test line of sight from (0,0) to (5,5) - should be blocked
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 5);
      expect(hasLOS).to.be.false;
    });

    it("should allow line of sight when wall is not on path", async function () {
      // Set a blocking tile at (10,10) - not on the path
      await game.setBlockedTile(gameId, 10, 10, true);

      // Test line of sight from (0,0) to (5,5) - should be clear
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 5);
      expect(hasLOS).to.be.true;
    });
  });

  describe("Corner Cases", function () {
    it("should handle permissive corner mode correctly", async function () {
      // Set up a diagonal line with one flanking tile blocked
      await game.setBlockedTile(gameId, 1, 0, true); // Block one flanker

      // Test diagonal line from (0,0) to (2,2) - should be clear in permissive mode
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 2, 2);
      expect(hasLOS).to.be.true;
    });

    it("should block when both flankers are blocked", async function () {
      // Set up a diagonal line with both flanking tiles blocked
      await game.setBlockedTile(gameId, 1, 0, true); // Block first flanker
      await game.setBlockedTile(gameId, 0, 1, true); // Block second flanker

      // Test diagonal line from (0,0) to (2,2) - should be blocked
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 2, 2);
      expect(hasLOS).to.be.false;
    });
  });

  describe("Start/End Position Checks", function () {
    it("should block when start position is blocked", async function () {
      // Set start position as blocked
      await game.setBlockedTile(gameId, 0, 0, true);

      // Test line of sight - should be blocked
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 5);
      expect(hasLOS).to.be.false;
    });

    it("should block when end position is blocked", async function () {
      // Set end position as blocked
      await game.setBlockedTile(gameId, 5, 5, true);

      // Test line of sight - should be blocked
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 5);
      expect(hasLOS).to.be.false;
    });
  });

  describe("Keyhole Test", function () {
    it("should allow line of sight through keyhole", async function () {
      // Create a keyhole: walls on both sides with one open column
      for (let i = 0; i < 10; i++) {
        await game.setBlockedTile(gameId, i, 1, true); // Left wall
        await game.setBlockedTile(gameId, i, 3, true); // Right wall
        // Column 2 is open (keyhole)
      }

      // Test line of sight through the keyhole
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 9, 4);
      expect(hasLOS).to.be.true;
    });
  });

  describe("Edge Cases", function () {
    it("should handle same start and end position", async function () {
      // Test line of sight from (0,0) to (0,0)
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 0, 0);
      expect(hasLOS).to.be.true;
    });

    it("should handle same start and end position with blocked tile", async function () {
      // Set the position as blocked
      await game.setBlockedTile(gameId, 0, 0, true);

      // Test line of sight - should be blocked
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 0, 0);
      expect(hasLOS).to.be.false;
    });

    it("should handle horizontal lines", async function () {
      // Test horizontal line from (0,0) to (5,0)
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 5, 0);
      expect(hasLOS).to.be.true;
    });

    it("should handle vertical lines", async function () {
      // Test vertical line from (0,0) to (0,5)
      const hasLOS = await game.hasLineOfSight(gameId, 0, 0, 0, 5);
      expect(hasLOS).to.be.true;
    });
  });

  describe("Grid Boundaries", function () {
    it("should reject coordinates outside grid bounds", async function () {
      // Test with coordinates outside the 255x255 grid
      await expect(
        game.hasLineOfSight(gameId, 0, 0, 256, 0)
      ).to.be.revertedWithCustomError(game, "InvalidPosition");

      await expect(
        game.hasLineOfSight(gameId, 0, 0, 0, 256)
      ).to.be.revertedWithCustomError(game, "InvalidPosition");
    });
  });
});
