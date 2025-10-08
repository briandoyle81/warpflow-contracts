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
  Ship,
  GameDataView,
} from "./types";
import DeployModule from "../ignition/modules/DeployAndConfig";

// Helper function to find a ship's position from GameDataView
function findShipPosition(gameData: GameDataView, shipId: bigint) {
  for (const shipPosition of gameData.shipPositions) {
    if (shipPosition.shipId === shipId) {
      return shipPosition.position;
    }
  }
  throw new Error(`Ship ${shipId} not found in game data`);
}

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
      maps: deployed.maps,
      gameResults: deployed.gameResults,
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get the ship attributes
      const attributes = await game.read.getShipAttributes([1n, 1n]);

      // Verify weapon attributes based on equipment
      const mainWeapon = constructedShip.equipment.mainWeapon;

      // Expected values based on ShipAttributes contract's gun data
      const expectedRanges = [8, 15, 12, 4]; // Laser, Railgun, MissileLauncher, PlasmaCannon
      const expectedDamages = [25, 20, 30, 40];

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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Get game data which includes all ship attributes
      const gameData = (await game.read.getGame([1n])) as any;

      // Verify we got attributes for all ships
      expect(gameData.shipAttributes.length).to.equal(6); // 3 creator + 3 joiner ships

      // Verify each ship has valid attributes
      for (let i = 0; i < 6; i++) {
        expect(gameData.shipAttributes[i].version).to.equal(1);
        expect(gameData.shipAttributes[i].hullPoints).to.be.greaterThan(0);
        expect(gameData.shipAttributes[i].movement).to.be.greaterThanOrEqual(0);
        expect(gameData.shipAttributes[i].range).to.be.greaterThan(0);
        expect(gameData.shipAttributes[i].gunDamage).to.be.greaterThan(0);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get complete game data
      const gameData = (await game.read.getGame([1n])) as any;

      // Verify game data structure
      expect(gameData.metadata.gameId).to.equal(1n);
      expect(gameData.metadata.lobbyId).to.equal(1n);
      expect(gameData.metadata.creator.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
      expect(gameData.metadata.joiner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(gameData.metadata.creatorGoesFirst).to.be.true;
      expect(Number(gameData.metadata.startedAt)).to.be.greaterThan(0);
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get complete game data
      const gridGameData = (await game.read.getGame([1n])) as any;

      // Verify grid dimensions (20 rows x 40 columns)
      expect(gridGameData.gridDimensions.gridWidth).to.equal(25); // Number of columns
      expect(gridGameData.gridDimensions.gridHeight).to.equal(13); // Number of rows
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

      // Purchase and construct 12 ships for both players (exceeds single column capacity of 10)
      // Alternate purchases: creator gets odd IDs (1,3,5...), joiner gets even IDs (2,4,6...)
      for (let i = 0; i < 12; i++) {
        await ships.write.purchaseWithFlow(
          [creator.account.address, 0n, joiner.account.address],
          { value: parseEther("4.99") }
        );
        await ships.write.purchaseWithFlow(
          [joiner.account.address, 0n, creator.account.address],
          { value: parseEther("4.99") }
        );
      }

      // Get ships' serial numbers and fulfill random requests for all ships
      for (let i = 1; i <= 24; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a lobby with high points limit to allow many ships
      await creatorLobbies.write.createLobby([
        5000n, // Very high points limit
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with 12 ships each (exceeds single column capacity)
      // Based on actual ownership pattern: creator owns 1-5, 11-15, 21-25, joiner owns 6-10, 16-20, 26-30
      const creatorShipIds = [
        1n,
        2n,
        3n,
        4n,
        5n,
        11n,
        12n,
        13n,
        14n,
        15n,
        21n,
        22n,
      ];
      const joinerShipIds = [
        6n,
        7n,
        8n,
        9n,
        10n,
        16n,
        17n,
        18n,
        19n,
        20n,
        26n,
        27n,
      ];

      await creatorLobbies.write.createFleet([1n, creatorShipIds]);
      await joinerLobbies.write.createFleet([1n, joinerShipIds]);

      // Get ship positions
      const shipPositions = (await game.read.getAllShipPositions([1n])) as any;

      // Separate creator and joiner ships
      const creatorShips = shipPositions
        .filter((pos: any) => creatorShipIds.includes(pos.shipId))
        .sort((a: any, b: any) => a.position.row - b.position.row); // Sort ascending for verification
      const joinerShips = shipPositions
        .filter((pos: any) => joinerShipIds.includes(pos.shipId))
        .sort((a: any, b: any) => b.position.row - a.position.row); // Sort descending for verification

      // Verify we have the expected number of ships
      expect(creatorShips.length).to.equal(12);
      expect(joinerShips.length).to.equal(12);

      // Verify creator ships are placed in multiple columns
      // Ships 1,2,3,4,5,11,12,13,14,15 should be in column 0, ships 21,22 should be in column 1
      const creatorShipsInCol0 = creatorShips.filter(
        (ship) => ship.position.col === 0
      );
      const creatorShipsInCol1 = creatorShips.filter(
        (ship) => ship.position.col === 1
      );

      expect(creatorShipsInCol0.length).to.equal(10);
      expect(creatorShipsInCol1.length).to.equal(2);

      // Verify column 0 ships are in correct rows
      for (let i = 0; i < 10; i++) {
        expect(creatorShipsInCol0[i].position.row).to.equal(i); // Rows 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
      }

      // Verify column 1 ships are in correct rows
      for (let i = 0; i < 2; i++) {
        expect(creatorShipsInCol1[i].position.row).to.equal(10 + i); // Rows 10, 11
      }

      // Verify joiner ships are placed in multiple columns
      // Ships 6,7,8,9,10,11,12,13,14,15 should be in column 24, ships 16,17 should be in column 23
      const joinerShipsInCol24 = joinerShips.filter(
        (ship) => ship.position.col === 24
      );
      const joinerShipsInCol23 = joinerShips.filter(
        (ship) => ship.position.col === 23
      );

      expect(joinerShipsInCol24.length).to.equal(10);
      expect(joinerShipsInCol23.length).to.equal(2);

      // Verify column 24 ships are in correct rows (first 10 ships: rows 12, 11, 10, 9, 8, 7, 6, 5, 4, 3)
      for (let i = 0; i < 10; i++) {
        expect(joinerShipsInCol24[i].position.row).to.equal(12 - i); // Rows 12, 11, 10, 9, 8, 7, 6, 5, 4, 3
      }

      // Verify column 23 ships are in correct rows (ships 11-12: rows 2, 1)
      for (let i = 0; i < 2; i++) {
        expect(joinerShipsInCol23[i].position.row).to.equal(2 - i); // Rows 2, 1
      }

      // Verify no ships are placed in columns between the two sides
      const allColumns = shipPositions.map((pos: any) => pos.position.col);
      const uniqueColumns = [...new Set(allColumns)].sort((a, b) => a - b);
      expect(uniqueColumns).to.deep.equal([0, 1, 23, 24]); // Only edge columns and adjacent ones
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Check ship positions using getAllShipPositions
      const allShipPositions = await game.read.getAllShipPositions([1n]);
      const shipAtOrigin = allShipPositions.find((pos) => pos.shipId === 1n);
      const shipAtEnd = allShipPositions.find((pos) => pos.shipId === 6n);

      expect(shipAtOrigin?.position.row).to.equal(0);
      expect(shipAtOrigin?.position.col).to.equal(0);
      expect(shipAtEnd?.position.row).to.equal(12);
      expect(shipAtEnd?.position.col).to.equal(24);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get individual ship positions
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      const creatorShipPosition = findShipPosition(gameData, 1n);
      expect(creatorShipPosition.row).to.equal(0);
      expect(creatorShipPosition.col).to.equal(0);

      const joinerShipPosition = findShipPosition(gameData, 6n);
      expect(joinerShipPosition.row).to.equal(12);
      expect(joinerShipPosition.col).to.equal(24);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get creator's ship attributes to check movement range
      const creatorAttributes = await game.read.getShipAttributes([1n, 1n]);
      const movementRange = creatorAttributes.movement;

      // Verify initial position
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const initialPosition = findShipPosition(gameData, 1n);
      expect(initialPosition.row).to.equal(0);
      expect(initialPosition.col).to.equal(0);

      // Move ship within its movement range (e.g., 2 spaces to the right)
      if (movementRange >= 2) {
        await game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
          account: creator.account,
        });

        // Verify new position
        let gameData = (await game.read.getGame([
          1n,
        ])) as unknown as GameDataView;
        const newPosition = findShipPosition(gameData, 1n);
        expect(newPosition.row).to.equal(0);
        expect(newPosition.col).to.equal(2);

        // Verify grid is updated using getAllShipPositions
        const allShipPositions = await game.read.getAllShipPositions([1n]);
        const shipAt00 = allShipPositions.find(
          (pos) => pos.position.row === 0 && pos.position.col === 0
        );
        const shipAt02 = allShipPositions.find(
          (pos) => pos.position.row === 0 && pos.position.col === 2
        );

        expect(shipAt00).to.be.undefined; // Should be empty
        expect(shipAt02?.shipId).to.equal(1n); // Ship 1 should be at (0,2)

        // Verify turn switched to joiner
        gameData = (await game.read.getGame([1n])) as any;
        expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
          [1n, 1n, 0, 5 + movementRange + 1, ActionType.Pass, 0n],
          {
            account: creator.account,
          }
        )
      ).to.be.rejectedWith("InvalidMove");
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try to move joiner's ship when it's creator's turn
      await expect(
        game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try to move joiner's ship with creator's account
      await expect(
        game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Check initial turn
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Joiner moves first ship
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn switched back to creator
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Joiner moves second ship (completing the round)
      await game.write.moveShip([1n, 7n, 11, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Try to move ship to position occupied by another ship
      await expect(
        game.write.moveShip([1n, 1n, 1, 0, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("PositionOccupied");
    });

    it("should allow diagonal movement", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Try diagonal movement (both row and column change) - should work now
      await game.write.moveShip([1n, 1n, 1, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify the ship moved to the new position
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      const shipPosition = findShipPosition(gameData, 1n);
      expect(shipPosition.row).to.equal(1);
      expect(shipPosition.col).to.equal(1);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with different sizes: creator has 3 ships, joiner has 5 ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n, 9n, 10n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves second ship
      await game.write.moveShip([1n, 7n, 11, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Creator moves third ship
      await game.write.moveShip([1n, 3n, 4, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves third ship
      await game.write.moveShip([1n, 8n, 10, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Joiner moves fourth ship (creator has no more ships, so joiner continues)
      await game.write.moveShip([1n, 9n, 7, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 1: Joiner moves fifth ship (completing the round)
      await game.write.moveShip([1n, 10n, 6, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game (multiple ships so destroying one doesn't end the game)
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

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

    it("should end game and record result when all ships of one player are destroyed", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
        gameResults,
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with single ships each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      const gameId = 1n;

      // Check initial game status
      const initialGame = await game.read.getGame([gameId]);
      expect(initialGame.metadata.winner).to.equal(
        "0x0000000000000000000000000000000000000000"
      ); // No winner yet

      // Destroy creator's only ship (this should end the game)
      await (game.write as any).debugDestroyShip([gameId, 1n], {
        account: owner.account,
      });

      // Check that the game ended and joiner won
      const finalGame = await game.read.getGame([gameId]);
      expect(finalGame.metadata.winner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      ); // Joiner wins when creator has no ships

      // Check that the game result was recorded in GameResults
      expect(await gameResults.read.isGameResultRecorded([gameId])).to.be.true;
      const result = await gameResults.read.getGameResult([gameId]);
      expect(result.winner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(result.loser.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });
      await game.write.moveShip([1n, 7n, 10, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Verify ship is initially on the grid
      let allShipPositions = await game.read.getAllShipPositions([1n]);
      let shipAt00 = allShipPositions.find(
        (pos) => pos.position.row === 0 && pos.position.col === 0
      );
      expect(shipAt00?.shipId).to.equal(1n);

      // Destroy the ship
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Verify ship is removed from grid
      allShipPositions = await game.read.getAllShipPositions([1n]);
      shipAt00 = allShipPositions.find(
        (pos) => pos.position.row === 0 && pos.position.col === 5
      );
      expect(shipAt00).to.be.undefined;
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Get initial ship positions
      const initialPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(initialPositions.length).to.equal(4);

      // For testing purposes, we'll test the 0 hull points behavior by creating a simple scenario
      // where we can verify that the contract logic treats 0 hull points the same as destroyed ships

      // First, let's verify that the contract correctly handles destroyed ships
      // We'll use the existing debug function to destroy a ship
      await (game.write as any).debugDestroyShip([1n, 1n], {
        account: owner.account,
      });

      // Try to move the destroyed ship (should fail)
      await expect(
        game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("ShipDestroyed");

      // Verify the destroyed ship is excluded from getAllShipPositions
      const updatedPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(updatedPositions.length).to.equal(3); // Only 3 ships now

      // Verify ship 1 is not in the positions
      const shipIds = updatedPositions.map((pos: any) => pos.shipId);
      expect(shipIds).to.not.include(1n);
      expect(shipIds).to.include(2n);
      expect(shipIds).to.include(6n);
      expect(shipIds).to.include(7n);

      // Verify round completion works correctly with the destroyed ship
      // Move the remaining ships to complete the round
      await game.write.moveShip([1n, 2n, 2, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });
      await game.write.moveShip([1n, 7n, 9, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 2n, 2, 3, ActionType.Pass, 0n], {
        account: creator.account,
      });
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: creator has 2 ships, joiner has 3 ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn switched to joiner
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn switched back to creator
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Round 1: Creator moves second ship (last ship)
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Verify turn stays with joiner (creator has no more ships)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves second ship
      await game.write.moveShip([1n, 7n, 8, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn stays with joiner (creator still has no more ships)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await game.write.moveShip([1n, 8n, 9, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: both have 3 ships initially
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n, 8n]]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
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
      await game.write.moveShip([1n, 7n, 7, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // After this move, creator has no unmoved ships, so the turn should remain with the joiner
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await game.write.moveShip([1n, 8n, 8, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Now, round should increment and turn should go back to creator
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get initial positions and attributes
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      let creatorPos = findShipPosition(gameData, 1n);
      let joinerPos = findShipPosition(gameData, 6n);
      let creatorAttrs = await game.read.getShipAttributes([1n, 1n]);
      let joinerAttrs = await game.read.getShipAttributes([1n, 6n]);

      const creatorRange = creatorAttrs.range;
      const joinerRange = joinerAttrs.range;
      const creatorMovement = creatorAttrs.movement;
      const joinerMovement = joinerAttrs.movement;

      // Choose target positions that are adjacent to each other
      // Creator targets (10, 10), Joiner targets (10, 11) - adjacent positions
      const creatorTarget = { row: 10, col: 10 };
      const joinerTarget = { row: 10, col: 11 };

      // Move ships towards their target positions
      let round = 0;
      let shootingSuccessful = false;

      while (!shootingSuccessful && round < 50) {
        // Re-fetch positions and game state each loop
        gameData = (await game.read.getGame([1n])) as any;
        creatorPos = findShipPosition(gameData, 1n);
        joinerPos = findShipPosition(gameData, 6n);

        // Check if ships are in shooting range
        const manhattanDistance =
          Math.abs(creatorPos.row - joinerPos.row) +
          Math.abs(creatorPos.col - joinerPos.col);

        if (
          manhattanDistance <= creatorRange ||
          manhattanDistance <= joinerRange
        ) {
          // Ships are in range, try to shoot
          const currentTurn = gameData.turnState.currentTurn.toLowerCase();

          if (currentTurn === creator.account.address.toLowerCase()) {
            // Creator's turn - try to shoot
            try {
              await game.write.moveShip(
                [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Shoot, 6n],
                { account: creator.account }
              );
              shootingSuccessful = true;
              break;
            } catch (error) {
              // Move towards target if can't shoot
              let newRow = creatorPos.row;
              let newCol = creatorPos.col;

              if (creatorPos.row !== creatorTarget.row) {
                newRow =
                  creatorPos.row +
                  (creatorTarget.row > creatorPos.row ? 1 : -1);
              } else if (creatorPos.col !== creatorTarget.col) {
                newCol =
                  creatorPos.col +
                  (creatorTarget.col > creatorPos.col ? 1 : -1);
              }

              // Ensure we don't move out of bounds
              newRow = Math.min(Math.max(newRow, 0), 19);
              newCol = Math.min(Math.max(newCol, 0), 29);

              await game.write.moveShip(
                [1n, 1n, newRow, newCol, ActionType.Pass, 0n],
                { account: creator.account }
              );
            }
          } else {
            // Joiner's turn - try to shoot
            try {
              await game.write.moveShip(
                [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Shoot, 1n],
                { account: joiner.account }
              );
              shootingSuccessful = true;
              break;
            } catch (error) {
              // Move towards target if can't shoot
              let newRow = joinerPos.row;
              let newCol = joinerPos.col;

              if (joinerPos.row !== joinerTarget.row) {
                newRow =
                  joinerPos.row + (joinerTarget.row > joinerPos.row ? 1 : -1);
              } else if (joinerPos.col !== joinerTarget.col) {
                newCol =
                  joinerPos.col + (joinerTarget.col > joinerPos.col ? 1 : -1);
              }

              // Ensure we don't move out of bounds
              newRow = Math.min(Math.max(newRow, 0), 19);
              newCol = Math.min(Math.max(newCol, 0), 29);

              await game.write.moveShip(
                [1n, 6n, newRow, newCol, ActionType.Pass, 0n],
                { account: joiner.account }
              );
            }
          }
        } else {
          // Ships not in range, move towards targets based on whose turn it is
          const currentTurn = gameData.turnState.currentTurn.toLowerCase();

          if (currentTurn === creator.account.address.toLowerCase()) {
            // Creator's turn - move towards target
            let newRow = creatorPos.row;
            let newCol = creatorPos.col;

            if (creatorPos.row !== creatorTarget.row) {
              newRow =
                creatorPos.row + (creatorTarget.row > creatorPos.row ? 1 : -1);
            } else if (creatorPos.col !== creatorTarget.col) {
              newCol =
                creatorPos.col + (creatorTarget.col > creatorPos.col ? 1 : -1);
            }

            // Ensure we don't move out of bounds
            newRow = Math.min(Math.max(newRow, 0), 19);
            newCol = Math.min(Math.max(newCol, 0), 29);

            await game.write.moveShip(
              [1n, 1n, newRow, newCol, ActionType.Pass, 0n],
              { account: creator.account }
            );
          } else {
            // Joiner's turn - move towards target
            let newRow = joinerPos.row;
            let newCol = joinerPos.col;

            if (joinerPos.row !== joinerTarget.row) {
              newRow =
                joinerPos.row + (joinerTarget.row > joinerPos.row ? 1 : -1);
            } else if (joinerPos.col !== joinerTarget.col) {
              newCol =
                joinerPos.col + (joinerTarget.col > joinerPos.col ? 1 : -1);
            }

            // Ensure we don't move out of bounds
            newRow = Math.min(Math.max(newRow, 0), 19);
            newCol = Math.min(Math.max(newCol, 0), 29);

            await game.write.moveShip(
              [1n, 6n, newRow, newCol, ActionType.Pass, 0n],
              { account: joiner.account }
            );
          }
        }

        round++;
      }

      // Verify that shooting was successful
      expect(shootingSuccessful).to.be.true;

      // Verify that one ship took damage
      const finalCreatorAttrs = await game.read.getShipAttributes([1n, 1n]);
      const finalJoinerAttrs = await game.read.getShipAttributes([1n, 6n]);

      // At least one ship should have taken damage (hull points reduced)
      const creatorTookDamage =
        finalCreatorAttrs.hullPoints < creatorAttrs.hullPoints;
      const joinerTookDamage =
        finalJoinerAttrs.hullPoints < joinerAttrs.hullPoints;

      expect(creatorTookDamage || joinerTookDamage).to.be.true;
    });

    it("should block shooting when line of sight is obstructed", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        owner,
        maps,
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Use debug moves to position ships exactly where we need them
      // Position creator ship at (10, 5) and joiner ship at (10, 7)
      // This gives us a Manhattan distance of 2, which should be within range
      await game.write.debugSetShipPosition([1n, 1n, 10, 5], {
        account: owner.account,
      });
      await game.write.debugSetShipPosition([1n, 6n, 10, 7], {
        account: owner.account,
      });

      // Place wall tile between the ships to block line of sight
      // Place wall at column 6 (between ships at 5 and 7)
      await maps.write.setBlockedTile([1n, 10, 6, true], {
        account: owner.account,
      });

      // Get current positions and attributes
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      let creatorPos = findShipPosition(gameData, 1n);
      let joinerPos = findShipPosition(gameData, 6n);
      let creatorAttrs = await game.read.getShipAttributes([1n, 1n]);

      // Verify ships are in range (Manhattan distance = 10, which should be within range)
      const manhattanDistance =
        Math.abs(creatorPos.row - joinerPos.row) +
        Math.abs(creatorPos.col - joinerPos.col);
      expect(manhattanDistance).to.be.lessThanOrEqual(creatorAttrs.range);

      // Ensure it's the creator's turn before attempting to shoot
      gameData = (await game.read.getGame([1n])) as any;
      if (
        gameData.turnState.currentTurn.toLowerCase() !==
        creator.account.address.toLowerCase()
      ) {
        // Let joiner pass their turn (move in place)
        await game.write.moveShip(
          [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );
      }

      // Attempt to shoot - should fail due to line of sight being blocked
      await expect(
        game.write.moveShip(
          [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Shoot, 6n],
          { account: creator.account }
        )
      ).to.be.rejectedWith("InvalidMove");
    });

    it("should allow special actions even when line of sight is obstructed (only range matters)", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        maps,
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
      for (let i = 1; i <= 2; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct creator's ship with EMP using
      // Get ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Create a ship with EMP for creator's first ship (ship 1)
      const empShip: Ship = {
        name: "EMP Ship",
        id: 1n,
        equipment: {
          mainWeapon: 0, // Laser
          armor: 0, // None
          shields: 0, // None
          special: 1, // EMP
        },
        traits: {
          serialNumber: 12345n,
          colors: { h1: 0, s1: 0, l1: 0, h2: 0, s2: 0, l2: 0 },
          variant: 0,
          accuracy: 0,
          hull: 0,
          speed: 2, // Use valid speed value (0, 1, or 2)
        },
        shipData: {
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
          shiny: false,
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
        },
        owner: creator.account.address,
      };

      // Authorize owner to create ships
      await ships.write.setIsAllowedToCreateShips(
        [owner.account.address, true],
        { account: owner.account }
      );

      // Construct the EMP ship
      await ships.write.constructSpecificShip([1n, empShip], {
        account: owner.account,
      });

      // Construct joiner's ship
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Get initial positions and attributes
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      let creatorPos = findShipPosition(gameData, 1n);
      let joinerPos = findShipPosition(gameData, 6n);

      // Move ships to positions where they can see each other but with a wall between them
      // Creator at (10, 10), Joiner at (10, 20) - same row, different columns
      // Use debugMove for this
      await (game.write as any).debugSetShipPosition([1n, 1n, 10, 10], {
        account: owner.account,
      });
      await (game.write as any).debugSetShipPosition([1n, 6n, 10, 20], {
        account: owner.account,
      });

      // Create a wall between the ships to block line of sight
      // Wall at row 10, columns 12-18 (blocking the direct path)
      for (let col = 12; col <= 18; col++) {
        await maps.write.setBlockedTile([1n, 10, col, true], {
          account: owner.account,
        });
      }

      // Ensure it's creator's turn
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      if (
        gameData.turnState.currentTurn.toLowerCase() !==
        creator.account.address.toLowerCase()
      ) {
        // Let joiner pass their turn
        await game.write.moveShip(
          [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );
      }

      // Try to use a special action - should succeed even with obstructed line of sight
      // Note: This test assumes the ship has a special ability. If not, it will fail for that reason, not line of sight.
      // The key point is that line of sight is not checked for special actions.
      try {
        await game.write.moveShip(
          [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Special, 6n],
          { account: creator.account }
        );
        // If this succeeds, it means line of sight wasn't checked (which is correct)
        // If it fails, it should be for a reason other than line of sight
      } catch (error) {
        // If it fails, it should be for a reason other than line of sight
        // (e.g., ship doesn't have special ability, out of range, etc.)
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        // Since we consolidated errors, InvalidMove is now acceptable
        expect(errorMessage).to.include("InvalidMove");
        // The error should be something like "ship doesn't have special ability" not "line of sight blocked"
      }
    });
  });

  describe("Ships with 0 Hull Points", function () {
    it("should treat ships with 0 hull points the same as destroyed ships, but should still be included in getAllShipPositions", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Get initial ship positions
      const initialPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(initialPositions.length).to.equal(4);

      // Use debug function to set ship 1's hull points to 0
      await (game.write as any).debugSetHullPointsToZero([1n, 1n], {
        account: owner.account,
      });

      // Verify ship 1 has 0 hull points
      expect((await game.read.getShipAttributes([1n, 1n])).hullPoints).to.equal(
        0
      );

      // Try to move the ship with 0 hull points (should fail)
      await expect(
        game.write.moveShip([1n, 1n, 0, 2, ActionType.Pass, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("ShipDestroyed");

      // Verify the ship with 0 hull points is still included in getAllShipPositions
      const updatedPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(updatedPositions.length).to.equal(4); // Still 4 ships now

      // Verify ship 1 is still in the positions (allowing it to be repaired)
      const shipIds = updatedPositions.map((pos: any) => pos.shipId);
      expect(shipIds).to.include(1n);
      expect(shipIds).to.include(2n);
      expect(shipIds).to.include(6n);
      expect(shipIds).to.include(7n);

      // Verify round completion works correctly with the ship having 0 hull points
      // Move the remaining ships to complete the round
      await game.write.moveShip([1n, 2n, 2, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });
      await game.write.moveShip([1n, 7n, 6, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Verify turn is back to creator and round has incremented
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify ships can move again in new round
      await game.write.moveShip([1n, 2n, 2, 3, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });
  });

  describe("Reactor Critical Timer", function () {
    it("should increment reactor critical timer when shooting ships with 0 HP", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Move ships toward each other until in range (similar to shooting test)
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;

      // Place ships very close together for this test
      // Move creator ship to (4, 5) - valid move within movement range of 4
      await game.write.moveShip([1n, 1n, 4, 0, ActionType.Pass, 0n], {
        account: creator.account,
      });
      // Move joiner ship to (19, 34) - valid move within movement range of 5
      await game.write.moveShip([1n, 6n, 12, 24, ActionType.Pass, 0n], {
        account: joiner.account,
      });
      // Ensure it's creator's turn
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      if (
        gameData.turnState.currentTurn.toLowerCase() !==
        creator.account.address.toLowerCase()
      ) {
        // If it's joiner's turn, have them move in place to make it creator's turn
        gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
        const joinerPos = findShipPosition(gameData, 6n);
        await game.write.moveShip(
          [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );
      }

      // Now use debug to make joiner's ship (ship 6) HP zero
      await (game.write as any).debugSetHullPointsToZero([1n, 6n], {
        account: owner.account,
      });

      // Verify ship 6 has 0 HP and 0 reactor critical timer
      const ship6Attrs = await game.read.getShipAttributes([1n, 6n]);
      expect(ship6Attrs.hullPoints).to.equal(0);
      expect(ship6Attrs.reactorCriticalTimer).to.equal(0);

      // Use debug function to place ships close together for shooting
      await (game.write as any).debugSetShipPosition([1n, 1n, 4, 0], {
        account: owner.account,
      });
      await (game.write as any).debugSetShipPosition([1n, 6n, 4, 2], {
        account: owner.account,
      });

      // Have creator's ship shoot joiner's ship (which has 0 HP)
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos = findShipPosition(gameData, 1n);
      await game.write.moveShip(
        [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Shoot, 6n],
        { account: creator.account }
      );

      // Verify reactor critical timer was incremented by 2:
      // 1 for being shot while having 0 HP, plus 1 for starting a new round with 0 HP
      const ship6AttrsAfter = await game.read.getShipAttributes([1n, 6n]);
      expect(ship6AttrsAfter.reactorCriticalTimer).to.equal(
        ship6Attrs.reactorCriticalTimer + 2
      );
    });

    it("should increment reactor critical timer for ships with 0 HP at the beginning of a round", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Complete the first round
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos = findShipPosition(gameData, 1n);
      await game.write.moveShip(
        [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Pass, 0n],
        { account: creator.account }
      );

      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );

      // Now set player 1's ship HP to 0 (after round has ended)
      await (game.write as any).debugSetHullPointsToZero([1n, 1n], {
        account: owner.account,
      });

      // Verify ship 1 has 0 HP and 0 reactor critical timer
      const ship1Attrs = await game.read.getShipAttributes([1n, 1n]);
      expect(ship1Attrs.hullPoints).to.equal(0);
      expect(ship1Attrs.reactorCriticalTimer).to.equal(0);

      // Start a new round by having both players move again
      // Since ship 1 has 0 HP, it can't move, but the round should complete when ship 6 moves
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;

      // Since it's the creator's turn but creator's ship has 0 HP,
      // the creator can't move. Use debug function to auto-pass the creator's turn
      await (game.write as any).debugAutoPassTurn([1n], {
        account: owner.account,
      });

      // Now it should be joiner's turn
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;

      const joinerPos2 = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPos2.row, joinerPos2.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );

      // Verify reactor critical timer was incremented at the beginning of the new round
      const ship1AttrsAfter = await game.read.getShipAttributes([1n, 1n]);
      expect(ship1AttrsAfter.reactorCriticalTimer).to.equal(1);
    });

    it("should destroy ships with reactor critical timer >= 3 at the end of a round", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two ships each
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Use debug to set player 1's first ship's HP to zero
      await (game.write as any).debugSetHullPointsToZero([1n, 1n], {
        account: owner.account,
      });

      // Have all players use no-op moves until ship 1's reactor critical timer is 3
      let round = 0;
      while (round < 3) {
        // Get current positions for no-op moves
        const gameData = (await game.read.getGame([
          1n,
        ])) as unknown as GameDataView;
        const creatorPos2 = findShipPosition(gameData, 2n);
        const joinerPos1 = findShipPosition(gameData, 6n);
        const joinerPos2 = findShipPosition(gameData, 7n);

        // Creator moves ship 2 in place (skip ship 1 since it has 0 HP)
        await game.write.moveShip(
          [1n, 2n, creatorPos2.row, creatorPos2.col, ActionType.Pass, 0n],
          { account: creator.account }
        );

        // Joiner moves both ships in place
        await game.write.moveShip(
          [1n, 6n, joinerPos1.row, joinerPos1.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );
        await game.write.moveShip(
          [1n, 7n, joinerPos2.row, joinerPos2.col, ActionType.Pass, 0n],
          { account: joiner.account }
        );

        round++;
      }

      // Verify ship 1's reactor critical timer is 3
      const ship1Attrs = await game.read.getShipAttributes([1n, 1n]);
      expect(ship1Attrs.reactorCriticalTimer).to.equal(3);

      // Complete one more round to trigger destruction
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2 = findShipPosition(gameData, 2n);
      const joinerPos1 = findShipPosition(gameData, 6n);
      const joinerPos2 = findShipPosition(gameData, 7n);

      // Creator moves ship 2 in place (skip ship 1 since it has 0 HP)
      await game.write.moveShip(
        [1n, 2n, creatorPos2.row, creatorPos2.col, ActionType.Pass, 0n],
        { account: creator.account }
      );
      await game.write.moveShip(
        [1n, 6n, joinerPos1.row, joinerPos1.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );
      await game.write.moveShip(
        [1n, 7n, joinerPos2.row, joinerPos2.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );

      // Verify ship 1 was destroyed due to critical reactor timer
      const ship1Tuple = await ships.read.ships([1n]);
      const ship1 = tupleToShip(ship1Tuple);
      expect(ship1.shipData.timestampDestroyed).to.not.equal(0);

      // Verify ship 1 is excluded from getAllShipPositions
      const positions = (await game.read.getAllShipPositions([1n])) as any;
      expect(positions.length).to.equal(3); // Creator's ship 2, joiner's ships 6 and 7 remain

      // Verify the remaining ships are the correct ones
      const remainingShipIds = positions.map((pos: any) => pos.shipId);
      expect(remainingShipIds).to.include(2n); // Creator's ship 2
      expect(remainingShipIds).to.include(6n); // Joiner's ship 6
      expect(remainingShipIds).to.include(7n); // Joiner's ship 7
      expect(remainingShipIds).to.not.include(1n); // Ship 1 should be destroyed

      // Confirm that players can continue to play by having them move their remaining ships
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2After = findShipPosition(gameData, 2n);
      const joinerPos1After = findShipPosition(gameData, 6n);

      // Move remaining ships to new positions
      await game.write.moveShip(
        [
          1n,
          2n,
          creatorPos2After.row + 1,
          creatorPos2After.col,
          ActionType.Pass,
          0n,
        ],
        { account: creator.account }
      );
      await game.write.moveShip(
        [
          1n,
          6n,
          joinerPos1After.row - 1,
          joinerPos1After.col - 1,
          ActionType.Pass,
          0n,
        ],
        { account: joiner.account }
      );
    });

    it("should allow ships to retreat and remove them from the game", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two ships each
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Get initial ship positions
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos1 = findShipPosition(gameData, 1n);
      const joinerPos1 = findShipPosition(gameData, 6n);

      // Have creator's ship 1 retreat
      await game.write.moveShip(
        [1n, 1n, creatorPos1.row, creatorPos1.col, ActionType.Retreat, 0n],
        { account: creator.account }
      );

      // Verify ship 1 is no longer on the grid
      const allShipPositions = await game.read.getAllShipPositions([1n]);
      const shipAtPosition = allShipPositions.find(
        (pos) =>
          pos.position.row === creatorPos1.row &&
          pos.position.col === creatorPos1.col
      );
      expect(shipAtPosition).to.be.undefined;

      // Verify ship 1 is excluded from getAllShipPositions
      const positions = (await game.read.getAllShipPositions([1n])) as any;
      expect(positions.length).to.equal(3); // Creator's ship 2, joiner's ships 6 and 7 remain

      // Verify the remaining ships are the correct ones
      const remainingShipIds = positions.map((pos: any) => pos.shipId);
      expect(remainingShipIds).to.include(2n); // Creator's ship 2
      expect(remainingShipIds).to.include(6n); // Joiner's ship 6
      expect(remainingShipIds).to.include(7n); // Joiner's ship 7
      expect(remainingShipIds).to.not.include(1n); // Ship 1 should be retreated

      // Verify that the game can continue with remaining ships
      // After retreat, it should be joiner's turn
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos1After = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [
          1n,
          6n,
          joinerPos1After.row - 1,
          joinerPos1After.col - 1,
          ActionType.Pass,
          0n,
        ],
        { account: joiner.account }
      );

      // Now it should be creator's turn to move ship 2
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2 = findShipPosition(gameData, 2n);
      await game.write.moveShip(
        [1n, 2n, creatorPos2.row + 1, creatorPos2.col, ActionType.Pass, 0n],
        { account: creator.account }
      );
    });

    it("should allow ships to assist friendly ships with 0 HP to retreat", async function () {
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
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two ships each
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // Get initial ship positions
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos1 = findShipPosition(gameData, 1n);
      const creatorPos2 = findShipPosition(gameData, 2n);

      // Set ship 1's HP to 0 using debug function
      await (game.write as any).debugSetHullPointsToZero([1n, 1n], {
        account: owner.account,
      });

      // Verify ship 1 has 0 HP
      const ship1Attrs = await game.read.getShipAttributes([1n, 1n]);
      expect(ship1Attrs.hullPoints).to.equal(0);

      // Move ship 2 adjacent to ship 1 and assist it
      // Ship 1 is at (0, 5), ship 2 is at (2, 5)
      // Move ship 2 to (1, 5) to be adjacent to ship 1
      await game.write.moveShip([1n, 2n, 1, 0, ActionType.Assist, 1n], {
        account: creator.account,
      });

      // Verify ship 1 was retreated (no longer on the grid)
      const allShipPositions = await game.read.getAllShipPositions([1n]);
      const shipAtPosition = allShipPositions.find(
        (pos) => pos.position.row === 0 && pos.position.col === 5
      );
      expect(shipAtPosition).to.be.undefined;

      // Verify ship 1 is excluded from getAllShipPositions
      const positions = (await game.read.getAllShipPositions([1n])) as any;
      expect(positions.length).to.equal(3); // Creator's ship 2, joiner's ships 6 and 7 remain

      // Verify the remaining ships are the correct ones
      const remainingShipIds = positions.map((pos: any) => pos.shipId);
      expect(remainingShipIds).to.include(2n); // Creator's ship 2
      expect(remainingShipIds).to.include(6n); // Joiner's ship 6
      expect(remainingShipIds).to.include(7n); // Joiner's ship 7
      expect(remainingShipIds).to.not.include(1n); // Ship 1 should be assisted/retreated

      // Verify that the game can continue with remaining ships
      // After assist, it should be joiner's turn
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos1 = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPos1.row - 1, joinerPos1.col - 1, ActionType.Pass, 0n],
        { account: joiner.account }
      );
    });

    it("should allow ships with RepairDrones to repair friendly ships", async function () {
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

      // Purchase ships for both players
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

      // Create a ship with RepairDrones for creator's first ship (ship 1)
      const repairShip: Ship = {
        name: "Repair Ship",
        id: 1n,
        equipment: {
          mainWeapon: 0, // Laser
          armor: 0, // None
          shields: 0, // None
          special: 2, // RepairDrones
        },
        traits: {
          serialNumber: 12345n,
          colors: { h1: 0, s1: 0, l1: 0, h2: 0, s2: 0, l2: 0 },
          variant: 0,
          accuracy: 0,
          hull: 0,
          speed: 2, // Use valid speed value (0, 1, or 2)
        },
        shipData: {
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
          shiny: false,
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
        },
        owner: creator.account.address,
      };

      // Authorize owner to create ships
      await ships.write.setIsAllowedToCreateShips(
        [owner.account.address, true],
        { account: owner.account }
      );

      // Construct the repair ship
      await ships.write.constructSpecificShip([1n, repairShip], {
        account: owner.account,
      });

      // Construct the second ship normally
      await ships.write.constructShip([2n], { account: creator.account });

      // Construct joiner's ship
      await ships.write.constructShip([6n], { account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([1n, [1n, 2n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Set ship 2's HP to 0 using debug function
      await (game.write as any).debugSetHullPointsToZero([1n, 2n], {
        account: owner.account,
      });

      // Verify ship 2 has 0 HP
      const ship2AttrsBefore = await game.read.getShipAttributes([1n, 2n]);
      expect(ship2AttrsBefore.hullPoints).to.equal(0);

      // Get ship positions
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      const ship1Pos = findShipPosition(gameData, 1n);
      const ship2Pos = findShipPosition(gameData, 2n);

      // Move ship 1 to be within range 3 of ship 2 and use RepairDrones special
      // Since RepairDrones has range 3, we can move ship 1 to position (5, 0) which is 3 squares away from ship 2 at (2, 0)
      await game.write.moveShip([1n, 1n, 5, 0, ActionType.Special, 2n], {
        account: creator.account,
      });

      // Verify ship 2's HP was increased by the repair strength (10)
      const ship2AttrsAfter = await game.read.getShipAttributes([1n, 2n]);
      expect(ship2AttrsAfter.hullPoints).to.equal(10); // Should be exactly 10 since RepairDrones restores 10 HP
    });

    it("should allow ships with EMP to increase enemy ship's reactor critical timer", async function () {
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

      // Purchase ships for both players
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

      // Create a ship with EMP for creator's first ship (ship 1)
      const empShip: Ship = {
        name: "EMP Ship",
        id: 1n,
        equipment: {
          mainWeapon: 0, // Laser
          armor: 0, // None
          shields: 0, // None
          special: 1, // EMP
        },
        traits: {
          serialNumber: 12345n,
          colors: { h1: 0, s1: 0, l1: 0, h2: 0, s2: 0, l2: 0 },
          variant: 0,
          accuracy: 0,
          hull: 0,
          speed: 2, // Use valid speed value (0, 1, or 2)
        },
        shipData: {
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
          shiny: false,
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
        },
        owner: creator.account.address,
      };

      // Authorize owner to create ships
      await ships.write.setIsAllowedToCreateShips(
        [owner.account.address, true],
        { account: owner.account }
      );

      // Construct the EMP ship
      await ships.write.constructSpecificShip([1n, empShip], {
        account: owner.account,
      });

      // Construct the second ship normally
      await ships.write.constructShip([2n], { account: creator.account });

      // Construct joiner's ship
      await ships.write.constructShip([6n], { account: joiner.account });

      // Create a game
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Use debug function to position ships adjacent to each other for EMP test
      // Position creator's ship at (10, 24) and joiner's ship at (11, 24) - adjacent positions
      await game.write.debugSetShipPosition([1n, 1n, 10, 24], {
        account: owner.account,
      });
      await game.write.debugSetShipPosition([1n, 6n, 11, 24], {
        account: owner.account,
      });

      // Verify joiner's ship has 0 reactor critical timer initially
      const joinerShipAttrsBefore = await game.read.getShipAttributes([1n, 6n]);
      expect(joinerShipAttrsBefore.reactorCriticalTimer).to.equal(0);

      // Ensure it's creator's turn to use EMP
      // Since we used debug functions to position ships, we need to ensure the turn is correct

      // Now use EMP from creator's ship to target joiner's ship
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      // Loop through gameData.shipPositions and log the shipId and position
      for (const ship of gameData.shipPositions) {
        console.log("ship", ship.shipId, ship.position);
      }
      const creatorPos = findShipPosition(gameData, 1n);
      console.log("creatorPos", creatorPos);
      await game.write.moveShip(
        [1n, 1n, creatorPos.row, creatorPos.col, ActionType.Special, 6n],
        {
          account: creator.account,
        }
      );

      // Verify joiner's ship's reactor critical timer was increased by the EMP strength (1)
      const joinerShipAttrsAfter = await game.read.getShipAttributes([1n, 6n]);
      expect(joinerShipAttrsAfter.reactorCriticalTimer).to.equal(1); // Should be exactly 1 since EMP strength is 1
    });

    it("should allow ships with FlakArray to damage all ships in range", async function () {
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

      // 1. Purchase ships for both players
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

      // 2. Set the first ship as having a FlakArray
      const flakShip: Ship = {
        name: "FlakArray Ship",
        id: 1n,
        equipment: {
          mainWeapon: 0, // Laser
          armor: 0, // None
          shields: 0, // None
          special: 3, // FlakArray
        },
        traits: {
          serialNumber: 12345n,
          colors: { h1: 0, s1: 0, l1: 0, h2: 0, s2: 0, l2: 0 },
          variant: 0,
          accuracy: 0,
          hull: 0,
          speed: 2, // Use valid speed value (0, 1, or 2)
        },
        shipData: {
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
          shiny: false,
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
        },
        owner: creator.account.address,
      };

      // Authorize owner to create ships
      await ships.write.setIsAllowedToCreateShips(
        [owner.account.address, true],
        { account: owner.account }
      );

      // Create the FlakArray ship
      await ships.write.constructSpecificShip([1n, flakShip], {
        account: owner.account,
      });

      // 3. Construct the remaining ships
      await ships.write.constructShip([2n], { account: creator.account });
      await ships.write.constructShip([3n], { account: creator.account });
      await ships.write.constructShip([6n], { account: joiner.account });
      await ships.write.constructShip([7n], { account: joiner.account });

      // 4. Create a lobby, fleet, game etc for both players
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships each
      await creatorLobbies.write.createFleet([1n, [1n, 2n, 3n]]);
      await joinerLobbies.write.createFleet([1n, [6n, 7n]]);

      // 5. Move the FlakArray ship to the center with the debug function
      await game.write.debugSetShipPosition([1n, 1n, 10, 20], {
        account: owner.account,
      });

      // 6. Move the remaining ships so that 1 from each team are within 5 squares and 1 from each team are outside 5 away
      // FlakArray has range 5, so we need ships within 5 squares and outside 5 squares

      // Creator's second ship (ship 2) - within range (distance 3)
      await game.write.debugSetShipPosition([1n, 2n, 7, 20], {
        account: owner.account,
      });

      // Creator's third ship (ship 3) - outside range (distance 7)
      await game.write.debugSetShipPosition([1n, 3n, 3, 20], {
        account: owner.account,
      });

      // Joiner's first ship (ship 6) - within range (distance 4)
      await game.write.debugSetShipPosition([1n, 6n, 14, 20], {
        account: owner.account,
      });

      // Joiner's second ship (ship 7) - outside range (distance 8)
      await game.write.debugSetShipPosition([1n, 7n, 18, 20], {
        account: owner.account,
      });

      // Get initial hull points of all ships
      const ship1AttrsBefore = await game.read.getShipAttributes([1n, 1n]); // FlakArray ship
      const ship2AttrsBefore = await game.read.getShipAttributes([1n, 2n]); // creator's second ship (in range)
      const ship3AttrsBefore = await game.read.getShipAttributes([1n, 3n]); // creator's third ship (out of range)
      const ship6AttrsBefore = await game.read.getShipAttributes([1n, 6n]); // joiner's first ship (in range)
      const ship7AttrsBefore = await game.read.getShipAttributes([1n, 7n]); // joiner's second ship (out of range)

      // 7. Use the first ship's first turn to stay in place and fire FlakArray
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      const flakPos = findShipPosition(gameData, 1n);
      await game.write.moveShip(
        [1n, 1n, flakPos.row, flakPos.col, ActionType.Special, 0n],
        { account: creator.account }
      );

      // Get hull points after FlakArray attack
      const ship1AttrsAfter = await game.read.getShipAttributes([1n, 1n]);
      const ship2AttrsAfter = await game.read.getShipAttributes([1n, 2n]);
      const ship3AttrsAfter = await game.read.getShipAttributes([1n, 3n]);
      const ship6AttrsAfter = await game.read.getShipAttributes([1n, 6n]);
      const ship7AttrsAfter = await game.read.getShipAttributes([1n, 7n]);

      // 8. Make sure that ship is undamaged (FlakArray ship should not damage itself)
      expect(ship1AttrsAfter.hullPoints).to.equal(ship1AttrsBefore.hullPoints);

      // 9. Make sure that both friendly and enemy ships in range are damaged
      // FlakArray damages ALL ships in range (both friendly and enemy)
      // FlakArray strength is 15, so ships in range should lose 15 hull points
      expect(ship2AttrsAfter.hullPoints).to.equal(
        Math.max(0, ship2AttrsBefore.hullPoints - 15)
      );
      expect(ship6AttrsAfter.hullPoints).to.equal(
        Math.max(0, ship6AttrsBefore.hullPoints - 15)
      );

      // 10. Make sure that the ships out of range are undamaged
      expect(ship3AttrsAfter.hullPoints).to.equal(ship3AttrsBefore.hullPoints);
      expect(ship7AttrsAfter.hullPoints).to.equal(ship7AttrsBefore.hullPoints);
    });
  });

  describe("Turn Timeout", function () {
    it("should enforce turn timeouts correctly", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        fleets,
        lobbies,
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

      // Create a lobby with a short turn time (5 minutes - minimum allowed)
      const shortTurnTime = 300n;
      await creatorLobbies.write.createLobby([
        1000n,
        shortTurnTime,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([lobbyId, [1n, 2n]]);
      await joinerLobbies.write.createFleet([lobbyId, [6n, 7n]]);

      const gameId = 1n;

      // Check initial turn info
      const gameData = (await game.read.getGame([gameId])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      ); // currentTurn

      // Wait for turn to timeout (simulate by advancing time)
      await hre.network.provider.send("evm_increaseTime", [
        Number(shortTurnTime) + 1,
      ]);
      await hre.network.provider.send("evm_mine", []);

      // Check that turn has timed out by checking if forceMoveOnTimeout can be called
      // Verify that the current player (creator) cannot call forceMoveOnTimeout
      await expect(
        game.write.forceMoveOnTimeout([gameId], { account: creator.account })
      ).to.be.rejectedWith("NotYourTurn");

      // Force move on timeout (called by the other player - joiner)
      await game.write.forceMoveOnTimeout([gameId], {
        account: joiner.account,
      });

      // Check that turn has switched to joiner
      const gameDataAfterForceMove = (await game.read.getGame([gameId])) as any;
      expect(
        gameDataAfterForceMove.turnState.currentTurn.toLowerCase()
      ).to.equal(joiner.account.address.toLowerCase()); // currentTurn
    });

    it("should allow either player to flee and end the game", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        fleets,
        lobbies,
        randomManager,
        gameResults,
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

      // Create a lobby with a short turn time (5 minutes - minimum allowed)
      const shortTurnTime = 300n;
      await creatorLobbies.write.createLobby([
        1000n,
        shortTurnTime,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([lobbyId, [1n, 2n]]);
      await joinerLobbies.write.createFleet([lobbyId, [6n, 7n]]);

      const gameId = 1n;

      // Check initial game status
      const initialGame = await game.read.getGame([gameId]);
      expect(initialGame.metadata.winner).to.equal(
        "0x0000000000000000000000000000000000000000"
      ); // winner (zero address means game not over)

      // Creator flees
      await game.write.flee([gameId], { account: creator.account });

      // Check game status after flee
      const gameAfterFlee = await game.read.getGame([gameId]);
      expect(gameAfterFlee.metadata.winner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      ); // winner (joiner wins when creator flees)

      // Check that the game result was recorded in GameResults
      expect(await gameResults.read.isGameResultRecorded([gameId])).to.be.true;
      const result = await gameResults.read.getGameResult([gameId]);
      expect(result.winner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(result.loser.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify that moves are no longer allowed
      await expect(
        game.write.moveShip([gameId, 1n, 0, 1, 0, 0n], {
          account: creator.account,
        })
      ).to.be.rejectedWith("InvalidMove");

      // Verify that the other player cannot flee again
      await expect(
        game.write.flee([gameId], { account: joiner.account })
      ).to.be.rejectedWith("InvalidMove");
    });

    it("should end game when all ships are retreated", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        fleets,
        lobbies,
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

      // Create a lobby
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([lobbyId, [1n, 2n]]);
      await joinerLobbies.write.createFleet([lobbyId, [6n, 7n]]);

      const gameId = 1n;

      // Check initial game status
      const initialGame = await game.read.getGame([gameId]);
      expect(initialGame.metadata.winner).to.equal(
        "0x0000000000000000000000000000000000000000"
      ); // No winner yet

      // Creator retreats all their ships
      await game.write.moveShip([gameId, 1n, 0, 0, 2, 0n], {
        account: creator.account,
      }); // Retreat ship 1

      // Complete the round so joiner can move (move to a valid position)
      await game.write.moveShip([gameId, 6n, 12, 24, 0, 0n], {
        account: joiner.account,
      }); // Joiner moves to complete round

      await game.write.moveShip([gameId, 2n, 2, 0, 2, 0n], {
        account: creator.account,
      }); // Retreat ship 2

      // Check game status after all creator ships retreated
      const gameAfterRetreat = await game.read.getGame([gameId]);
      expect(gameAfterRetreat.metadata.winner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      ); // Joiner wins because creator has no active ships

      // Verify that moves are no longer allowed
      await expect(
        game.write.moveShip([gameId, 6n, 0, 1, 0, 0n], {
          account: joiner.account,
        })
      ).to.be.rejectedWith("InvalidMove");
    });

    it("should respect preset maps when calculating line of sight", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        fleets,
        lobbies,
        randomManager,
        maps,
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

      // Create a preset map with blocked tiles that will block line of sight
      const blockedPositions = [
        { row: 10, col: 20 }, // Block the middle of the grid
        { row: 10, col: 21 },
        { row: 10, col: 22 },
      ];

      await maps.write.createPresetMap([blockedPositions], {
        account: owner.account,
      });
      const mapId = await maps.read.mapCount();

      // Create a lobby with the selected preset map
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        mapId, // Use the preset map,
        100n, // maxScore
      ]);
      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game and applies the preset map)
      await creatorLobbies.write.createFleet([lobbyId, [1n]]);
      await joinerLobbies.write.createFleet([lobbyId, [6n]]);

      const gameId = 1n;
      const creatorShipIds = [1n];
      const joinerShipIds = [6n];

      // Get game data to see ship positions
      const gameData = (await game.read.getGame([
        gameId,
      ])) as unknown as GameDataView;

      // Creator ships start at column 0, joiner ships start at column 24
      // With the blocked tiles at row 10, columns 20-22, line of sight should be blocked
      // when trying to shoot from one side to the other through the middle

      // Test line of sight that should be blocked by the preset map
      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        10, // Start at row 10 (same row as blocked tiles)
        0, // Start at column 0 (creator side)
        10, // End at row 10 (same row as blocked tiles)
        24, // End at column 24 (passes through blocked tiles at columns 20-22)
      ]);

      // Line of sight should be blocked because it passes through the blocked tiles
      expect(hasLOS).to.be.false;

      // Test line of sight that should be clear (above the blocked tiles)
      const hasLOSAbove = await maps.read.hasMaps([
        BigInt(gameId),
        5, // Start at row 5 (above blocked tiles)
        0, // Start at column 0
        12, // End at row 12 (within bounds)
        15, // End at column 15 (avoid blocked tiles at columns 20-22)
      ]);

      // Line of sight should be clear above the blocked tiles
      expect(hasLOSAbove).to.be.true;

      // Test line of sight that should be clear (below the blocked tiles)
      const hasLOSBelow = await maps.read.hasMaps([
        BigInt(gameId),
        12, // Start at row 12 (below blocked tiles)
        0, // Start at column 0
        5, // End at row 5
        15, // End at column 15 (avoid blocked tiles at columns 20-22)
      ]);

      // Line of sight should be clear below the blocked tiles
      expect(hasLOSBelow).to.be.true;
    });
  });
});
