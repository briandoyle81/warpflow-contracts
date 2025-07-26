import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther, zeroAddress } from "viem";
import {
  LobbyStatus,
  PlayerLobbyState,
  ShipTuple,
  tupleToShip,
  ActionType,
} from "./types";
import DeployModule from "../ignition/modules/DeployAndConfig";

describe("Game", function () {
  async function deployGameFixture() {
    const [owner, creator, joiner, other] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy all contracts using the module
    const deployed = await hre.ignition.deploy(DeployModule);

    // Create separate contract instances for each user
    const creatorLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      {
        client: { wallet: creator },
      }
    );
    const joinerLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      {
        client: { wallet: joiner },
      }
    );
    const otherLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      {
        client: { wallet: other },
      }
    );

    // Create Fleets contract instances
    const creatorFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      {
        client: { wallet: creator },
      }
    );
    const joinerFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      {
        client: { wallet: joiner },
      }
    );

    return {
      lobbies: deployed.lobbies,
      creatorLobbies,
      joinerLobbies,
      otherLobbies,
      fleets: deployed.fleets,
      creatorFleets,
      joinerFleets,
      ships: deployed.ships,
      game: deployed.game,
      randomManager: deployed.randomManager,
      owner,
      creator,
      joiner,
      other,
      publicClient,
    };
  }

  describe("Game Ship Attributes", function () {
    it("should calculate correct hull points for ships", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Get the constructed ship to see its traits
      const constructedShipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const constructedShip = tupleToShip(constructedShipTuple);

      // Calculate expected hull points: baseHull (100) + (traits.hull * 10)
      const expectedHullPoints = 100 + constructedShip.traits.hull * 10;

      // Create a game and calculate attributes
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get the ship attributes
      const attributes = await game.read.getShipAttributes([1n, 1n]);

      expect(attributes.hullPoints).to.equal(expectedHullPoints);
    });

    it("should calculate correct movement for ships with different equipment", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get ship attributes for both players
      const creatorAttributes = await game.read.getShipAttributes([1n, 1n]);
      const joinerAttributes = await game.read.getShipAttributes([1n, 6n]);

      // Verify movement calculations
      // Base speed is 5, plus trait bonus, plus equipment modifiers
      expect(creatorAttributes.movement).to.be.greaterThan(0);
      expect(joinerAttributes.movement).to.be.greaterThan(0);

      // Movement should be calculated as: baseSpeed + traits.speed + equipment modifiers
      // We can't predict exact values due to randomness, but they should be reasonable
      expect(creatorAttributes.movement).to.be.lessThan(20); // Reasonable upper bound
      expect(joinerAttributes.movement).to.be.lessThan(20);
    });

    it("should calculate correct weapon range and damage", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Get the constructed ship to see its equipment
      const constructedShipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const constructedShip = tupleToShip(constructedShipTuple);

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get the ship attributes
      const attributes = await game.read.getShipAttributes([1n, 1n]);

      // Verify weapon attributes based on equipment
      const mainWeapon = constructedShip.equipment.mainWeapon;

      // Expected values based on the Game contract's initialization
      const expectedRanges = [10, 50, 40, 4]; // Laser, Railgun, MissileLauncher, PlasmaCannon
      const expectedDamages = [15, 10, 15, 25];

      expect(attributes.range).to.equal(expectedRanges[mainWeapon]);
      expect(attributes.gunDamage).to.equal(expectedDamages[mainWeapon]);
    });

    it("should handle negative movement correctly", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get ship attributes for both players
      const creatorAttributes = await game.read.getShipAttributes([1n, 1n]);
      const joinerAttributes = await game.read.getShipAttributes([1n, 6n]);

      // Movement should never be negative (clamped to 0)
      expect(creatorAttributes.movement).to.be.greaterThanOrEqual(0);
      expect(joinerAttributes.movement).to.be.greaterThanOrEqual(0);
    });

    it("should calculate attributes for multiple ships in a fleet", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Get attributes for all ships in creator's fleet
      const creatorShipIds = [1n, 2n, 3n];
      const creatorAttributes = await game.read.getPlayerShipAttributes([
        1n,
        creatorShipIds,
      ]);

      // Get attributes for all ships in joiner's fleet
      const joinerShipIds = [6n, 7n, 8n];
      const joinerAttributes = await game.read.getPlayerShipAttributes([
        1n,
        joinerShipIds,
      ]);

      // Verify we got attributes for all ships
      expect(creatorAttributes.length).to.equal(3);
      expect(joinerAttributes.length).to.equal(3);

      // Verify each ship has valid attributes
      for (let i = 0; i < 3; i++) {
        expect(creatorAttributes[i].version).to.equal(1);
        expect(creatorAttributes[i].hullPoints).to.be.greaterThan(0);
        expect(creatorAttributes[i].movement).to.be.greaterThanOrEqual(0);
        expect(creatorAttributes[i].range).to.be.greaterThan(0);
        expect(creatorAttributes[i].gunDamage).to.be.greaterThan(0);

        expect(joinerAttributes[i].version).to.equal(1);
        expect(joinerAttributes[i].hullPoints).to.be.greaterThan(0);
        expect(joinerAttributes[i].movement).to.be.greaterThanOrEqual(0);
        expect(joinerAttributes[i].range).to.be.greaterThan(0);
        expect(joinerAttributes[i].gunDamage).to.be.greaterThan(0);
      }
    });

    it("should return correct game data with ship attributes", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get complete game data
      const gameData = (await game.read.getGame([1n, [1n], [6n]])) as any;

      // Verify game data structure
      expect(gameData.gameId).to.equal(1n);
      expect(gameData.lobbyId).to.equal(1n);
      expect(gameData.creator.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
      expect(gameData.joiner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(gameData.creatorGoesFirst).to.be.true;
      expect(Number(gameData.startedAt)).to.be.greaterThan(0);
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ship attributes arrays
      expect(gameData.shipAttributes.length).to.equal(2); // 1 creator + 1 joiner ship

      // Verify creator ship attributes (first in the array)
      const creatorAttrs = gameData.shipAttributes[0];
      expect(creatorAttrs.version).to.equal(1);
      expect(creatorAttrs.hullPoints).to.be.greaterThan(0);
      expect(creatorAttrs.movement).to.be.greaterThanOrEqual(0);
      expect(creatorAttrs.range).to.be.greaterThan(0);
      expect(creatorAttrs.gunDamage).to.be.greaterThan(0);
      expect(creatorAttrs.statusEffects.length).to.equal(0);

      // Verify joiner ship attributes (second in the array)
      const joinerAttrs = gameData.shipAttributes[1];
      expect(joinerAttrs.version).to.equal(1);
      expect(joinerAttrs.hullPoints).to.be.greaterThan(0);
      expect(joinerAttrs.movement).to.be.greaterThanOrEqual(0);
      expect(joinerAttrs.range).to.be.greaterThan(0);
      expect(joinerAttrs.gunDamage).to.be.greaterThan(0);
      expect(joinerAttrs.statusEffects.length).to.equal(0);
    });

    it("should revert when trying to get attributes for non-existent game", async function () {
      const { game } = await loadFixture(deployGameFixture);

      await expect(game.read.getShipAttributes([999n, 1n])).to.be.rejectedWith(
        "GameNotFound"
      );
    });

    it("should revert when trying to get attributes for non-existent ship", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try to get attributes for non-existent ship
      await expect(game.read.getShipAttributes([1n, 999n])).to.be.rejectedWith(
        "ShipNotFound"
      );
    });
  });

  describe("Game Grid", function () {
    it("should initialize grid with correct dimensions", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get complete game data
      const gridGameData = (await game.read.getGame([1n, [1n], [6n]])) as any;

      // Verify grid dimensions (50 rows x 100 columns)
      expect(gridGameData.gridWidth).to.equal(100); // Number of columns
      expect(gridGameData.gridHeight).to.equal(50); // Number of rows
    });

    it("should place both players' ships correctly at the start of a game", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships for both players
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Get ship positions
      const shipPositions = (await game.read.getAllShipPositions([1n])) as any;

      // Separate creator and joiner ships
      const creatorShips = shipPositions
        .filter((pos: any) => pos.isCreator)
        .sort((a: any, b: any) => a.position.row - b.position.row);
      const joinerShips = shipPositions
        .filter((pos: any) => !pos.isCreator)
        .sort((a: any, b: any) => b.position.row - a.position.row); // Sort descending

      // Verify we have the expected number of ships
      expect(creatorShips.length).to.equal(3);
      expect(joinerShips.length).to.equal(3);

      // Verify creator ships are on the left side (column 0) and placed from top to bottom
      for (let i = 0; i < creatorShips.length; i++) {
        expect(creatorShips[i].position.col).to.equal(0); // Left side
        expect(creatorShips[i].position.row).to.equal(i * 2); // Top to bottom with spacing (rows 0, 2, 4)
        expect(creatorShips[i].position.row).to.be.lessThan(50); // Within grid height
      }

      // Verify joiner ships are on the right side (column 99) and placed from bottom to top
      for (let i = 0; i < joinerShips.length; i++) {
        expect(joinerShips[i].position.col).to.equal(99); // Right side
        expect(joinerShips[i].position.row).to.equal(49 - i * 2); // Bottom to top with spacing (rows 49, 47, 45)
        expect(joinerShips[i].position.row).to.be.lessThan(50); // Within grid height
      }

      // Verify specific ship positions using grid queries
      // Creator ships should be at (row 0, col 0), (row 2, col 0), (row 4, col 0)
      expect((await game.read.getShipAtPosition([1n, 0, 0])) as any).to.equal(
        1n
      );
      expect((await game.read.getShipAtPosition([1n, 2, 0])) as any).to.equal(
        2n
      );
      expect((await game.read.getShipAtPosition([1n, 4, 0])) as any).to.equal(
        3n
      );

      // Joiner ships should be at (row 49, col 99), (row 47, col 99), (row 45, col 99)
      expect((await game.read.getShipAtPosition([1n, 49, 99])) as any).to.equal(
        6n
      );
      expect((await game.read.getShipAtPosition([1n, 47, 99])) as any).to.equal(
        7n
      );
      expect((await game.read.getShipAtPosition([1n, 45, 99])) as any).to.equal(
        8n
      );

      // Verify empty positions return 0
      expect((await game.read.getShipAtPosition([1n, 25, 50])) as any).to.equal(
        0n
      );
      expect((await game.read.getShipAtPosition([1n, 10, 10])) as any).to.equal(
        0n
      );

      // Verify individual ship position queries
      const creatorShip1Position = (await game.read.getShipPosition([
        1n,
        1n,
      ])) as any;
      expect(creatorShip1Position.row).to.equal(0);
      expect(creatorShip1Position.col).to.equal(0);

      const joinerShip1Position = (await game.read.getShipPosition([
        1n,
        6n,
      ])) as any;
      expect(joinerShip1Position.row).to.equal(49);
      expect(joinerShip1Position.col).to.equal(99);
    });

    it("should allow querying ship at specific grid position", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Check that creator ship is at position (row 0, column 0)
      const shipAtOrigin = (await game.read.getShipAtPosition([
        1n,
        0,
        0,
      ])) as any;
      expect(shipAtOrigin).to.equal(1n);

      // Check that joiner ship is at position (row 49, column 99)
      const shipAtEnd = (await game.read.getShipAtPosition([
        1n,
        49,
        99,
      ])) as any;
      expect(shipAtEnd).to.equal(6n);

      // Check that empty positions return 0
      const emptyPosition = (await game.read.getShipAtPosition([
        1n,
        25,
        50,
      ])) as any;
      expect(emptyPosition).to.equal(0n);
    });

    it("should allow querying individual ship positions", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get individual ship positions
      const creatorShipPosition = (await game.read.getShipPosition([
        1n,
        1n,
      ])) as any;
      expect(creatorShipPosition.row).to.equal(0);
      expect(creatorShipPosition.col).to.equal(0);

      const joinerShipPosition = (await game.read.getShipPosition([
        1n,
        6n,
      ])) as any;
      expect(joinerShipPosition.row).to.equal(49);
      expect(joinerShipPosition.col).to.equal(99);
    });
  });

  describe("Ship Movement", function () {
    it("should allow valid ship movement within movement range", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get creator's ship attributes to check movement range
      const creatorAttributes = await game.read.getShipAttributes([1n, 1n]);
      const movementRange = creatorAttributes.movement;

      // Verify initial position
      const initialPosition = (await game.read.getShipPosition([
        1n,
        1n,
      ])) as any;
      expect(initialPosition.row).to.equal(0);
      expect(initialPosition.col).to.equal(0);

      // Move ship within its movement range (e.g., 2 spaces to the right)
      if (movementRange >= 2) {
        await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
          account: creator.account,
        });

        // Verify new position
        const newPosition = (await game.read.getShipPosition([1n, 1n])) as any;
        expect(newPosition.row).to.equal(0);
        expect(newPosition.col).to.equal(2);

        // Verify grid is updated
        expect((await game.read.getShipAtPosition([1n, 0, 0])) as any).to.equal(
          0n
        );
        expect((await game.read.getShipAtPosition([1n, 0, 2])) as any).to.equal(
          1n
        );

        // Verify turn switched to joiner
        const gameData = (await game.read.getGame([1n, [1n], [6n]])) as any;
        expect(gameData.currentTurn.toLowerCase()).to.equal(
          joiner.account.address.toLowerCase()
        );
      }
    });

    it("should prevent movement beyond ship's movement range", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get creator's ship attributes
      const creatorAttributes = await game.read.getShipAttributes([1n, 1n]);
      const movementRange = creatorAttributes.movement;

      // Try to move beyond movement range
      await expect(
        game.write.moveShip(
          [1n, 1n, 0, movementRange + 1, ActionType.Pass, 0n],
          {
            account: creator.account,
          }
        )
      ).to.be.rejectedWith("MovementExceeded");
    });

    it("should prevent movement when it's not the player's turn", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try to move joiner's ship when it's creator's turn
      await expect(
        game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
          account: joiner.account,
        })
      ).to.be.rejectedWith("NotYourTurn");
    });

    it("should prevent moving a ship that doesn't belong to the player", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try to move joiner's ship with creator's account
      await expect(
        game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("ShipNotOwned");
    });

    it("should prevent moving a ship twice in the same round", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Move ship once
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Try to move the same ship again (should fail because turn switched)
      await expect(
        game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("NotYourTurn");
    });

    it("should switch turns correctly with equal fleet sizes", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Check initial turn
      let gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Joiner moves first ship
      await game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn switched back to creator
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Joiner moves second ship (completing the round)
      await game.write.moveShip([1n, 7n, 47, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });

    it("should prevent moving to an occupied position", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Try to move ship to position occupied by another ship
      await expect(
        game.write.moveShip([1n, 1n, 2, 0, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("PositionOccupied");
    });

    it("should prevent diagonal movement", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try diagonal movement (both row and column change)
      await expect(
        game.write.moveShip([1n, 1n, 1, 1, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("InvalidMove");
    });

    it("should handle different fleet sizes correctly", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with different sizes: creator has 3 ships, joiner has 5 ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n, 9n, 10n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves second ship
      await game.write.moveShip([1n, 7n, 47, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Creator moves third ship
      await game.write.moveShip([1n, 3n, 4, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves third ship
      await game.write.moveShip([1n, 8n, 45, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Joiner moves fourth ship (creator has no more ships, so joiner continues)
      await game.write.moveShip([1n, 9n, 43, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Joiner moves fifth ship (completing the round)
      await game.write.moveShip([1n, 10n, 41, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      let gameData = (await game.read.getGame([
        1n,
        [1n, 2n, 3n],
        [6n, 7n, 8n, 9n, 10n],
      ])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });

    it("should prevent destroyed ships from moving", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Destroy creator's ship
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Try to move the destroyed ship
      await expect(
        game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("ShipDestroyed");
    });

    it("should exclude destroyed ships from round completion", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Destroy one of creator's ships
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Move the remaining creator ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Move both joiner ships
      await game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });
      await game.write.moveShip([1n, 7n, 47, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      const gameData = (await game.read.getGame([
        1n,
        [1n, 2n],
        [6n, 7n],
      ])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 2n, 2, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });

    it("should remove destroyed ships from grid positions", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Verify ship is initially on the grid
      expect((await game.read.getShipAtPosition([1n, 0, 0])) as any).to.equal(
        1n
      );

      // Destroy the ship
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Verify ship is removed from grid
      expect((await game.read.getShipAtPosition([1n, 0, 0])) as any).to.equal(
        0n
      );
    });

    it("should exclude destroyed ships from getAllShipPositions", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Get initial ship positions
      const initialPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(initialPositions.length).to.equal(4);

      // Destroy one ship
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Get updated ship positions
      const updatedPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(updatedPositions.length).to.equal(3);

      // Verify the destroyed ship is not in the positions
      const shipIds = updatedPositions.map((pos: any) => pos.shipId);
      expect(shipIds).to.not.include(1n);
      expect(shipIds).to.include(2n);
      expect(shipIds).to.include(6n);
      expect(shipIds).to.include(7n);
    });

    it("should prevent destroying already destroyed ships", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Destroy the ship once
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Try to destroy the same ship again
      await expect(
        (game.write as any).debugDestroyShip([1n, 1n], {
          account: owner.account,
        })
      ).to.be.rejectedWith("ShipDestroyed");
    });

    it("should keep turn with player who has more ships", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: creator has 2 ships, joiner has 3 ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      let gameData = (await game.read.getGame([
        1n,
        [1n, 2n],
        [6n, 7n, 8n],
      ])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn switched back to creator
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n, 8n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Round 1: Creator moves second ship (last ship)
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn stays with joiner (creator has no more ships)
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n, 8n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves second ship
      await game.write.moveShip([1n, 7n, 47, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn stays with joiner (creator still has no more ships)
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n, 8n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await game.write.moveShip([1n, 8n, 45, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      gameData = (await game.read.getGame([1n, [1n, 2n], [6n, 7n, 8n]])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });

    it("should handle turn switching correctly when ships are destroyed", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: both have 3 ships initially
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 49, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Destroy creator's last unmoved ship (ship 3)
      await (game.write as any).debugDestroyShip([1n, 3n], {
        account: owner.account,
      });

      // Round 1: Joiner moves second ship
      await game.write.moveShip([1n, 7n, 47, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // After this move, creator has no unmoved ships, so the turn should remain with the joiner
      let gameData = (await game.read.getGame([
        1n,
        [1n, 2n, 3n],
        [6n, 7n, 8n],
      ])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await game.write.moveShip([1n, 8n, 45, 98, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Now, round should increment and turn should go back to creator
      gameData = (await game.read.getGame([
        1n,
        [1n, 2n, 3n],
        [6n, 7n, 8n],
      ])) as any;
      expect(gameData.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });
  });

  describe("Shooting", function () {
    it("should allow a ship to shoot another ship when in range", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 2; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get initial positions and attributes
      let creatorPos = await game.read.getShipPosition([1n, 1n]);
      let joinerPos = await game.read.getShipPosition([1n, 6n]);
      let creatorAttrs = await game.read.getShipAttributes([1n, 1n]);
      let joinerAttrs = await game.read.getShipAttributes([1n, 6n]);
      const range = creatorAttrs.range;
      const creatorMovement = creatorAttrs.movement;
      const joinerMovement = joinerAttrs.movement;

      // Move ships toward each other until in range
      let turn = "creator";
      let round = 0;
      while (true) {
        // Re-fetch positions each loop
        creatorPos = await game.read.getShipPosition([1n, 1n]);
        joinerPos = await game.read.getShipPosition([1n, 6n]);
        // Manhattan distance
        const manhattan =
          Math.abs(creatorPos.row - joinerPos.row) +
          Math.abs(creatorPos.col - joinerPos.col);
        if (manhattan <= range) break;
        if (turn === "creator") {
          // Move creator's ship down or right
          let newRow = creatorPos.row;
          let newCol = creatorPos.col;
          if (creatorPos.row < joinerPos.row) {
            newRow = Math.min(creatorPos.row + creatorMovement, joinerPos.row);
          } else if (creatorPos.row > joinerPos.row) {
            newRow = Math.max(creatorPos.row - creatorMovement, joinerPos.row);
          } else if (creatorPos.col < joinerPos.col) {
            newCol = Math.min(creatorPos.col + creatorMovement, joinerPos.col);
          } else if (creatorPos.col > joinerPos.col) {
            newCol = Math.max(creatorPos.col - creatorMovement, joinerPos.col);
          }
          await game.write.moveShip(
            [1n, 1n, newRow, newCol, ActionType.Pass, 0n],
            {
              account: creator.account,
            }
          );
          turn = "joiner";
        } else {
          // Move joiner's ship up or left
          let newRow = joinerPos.row;
          let newCol = joinerPos.col;
          if (joinerPos.row > creatorPos.row) {
            newRow = Math.max(joinerPos.row - joinerMovement, creatorPos.row);
          } else if (joinerPos.row < creatorPos.row) {
            newRow = Math.min(joinerPos.row + joinerMovement, creatorPos.row);
          } else if (joinerPos.col > creatorPos.col) {
            newCol = Math.max(joinerPos.col - joinerMovement, creatorPos.col);
          } else if (joinerPos.col < creatorPos.col) {
            newCol = Math.min(joinerPos.col + joinerMovement, creatorPos.col);
          }
          await game.write.moveShip(
            [1n, 6n, newRow, newCol, ActionType.Pass, 0n],
            {
              account: joiner.account,
            }
          );
          turn = "creator";
        }
        round++;
        if (round > 100)
          throw new Error("Failed to get in range after 100 rounds");
      }

      // Now in range, ensure it's the creator's turn before shooting
      let gameData = (await game.read.getGame([1n, [1n], [6n]])) as any;
      if (
        gameData.currentTurn.toLowerCase() !==
        creator.account.address.toLowerCase()
      ) {
        // Let joiner pass their turn (move in place)
        joinerPos = await game.read.getShipPosition([1n, 6n]);
        await game.write.moveShip(
          [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );
      }
      // Get joiner's hull before
      joinerAttrs = await game.read.getShipAttributes([1n, 6n]);
      const hullBefore = joinerAttrs.hullPoints;
      // Move creator's ship (no movement, just shoot)
      creatorPos = await game.read.getShipPosition([1n, 1n]);
      await game.write.moveShip(
        [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Shoot, 6n],
        {
          account: creator.account,
        }
      );
      // Get joiner's hull after
      joinerAttrs = await game.read.getShipAttributes([1n, 6n]);
      const hullAfter = joinerAttrs.hullPoints;
      expect(hullAfter).to.be.lessThan(hullBefore);
    });
  });
});
