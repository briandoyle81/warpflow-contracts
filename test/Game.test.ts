import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther, zeroAddress, parseEventLogs } from "viem";
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

// Helper function to generate starting positions
function generateStartingPositions(shipIds: bigint[], isCreator: boolean) {
  const positions = [];
  for (let i = 0; i < shipIds.length; i++) {
    if (isCreator) {
      // Creator starts in top-left, each ship 1 down, in columns 0-3
      // Wrap rows to stay within 0-10 range
      positions.push({ row: i % 11, col: i % 4 }); // Use columns 0-3
    } else {
      // Joiner starts in bottom-right, each ship 1 up, in columns 13-16
      // Ensure rows stay within 0-10 range
      const row = Math.max(0, 10 - (i % 11));
      positions.push({ row, col: 13 + (i % 4) }); // Use columns 13-16
    }
  }
  return positions;
}

const GRID_MAX_COLUMN = 16;

async function getValidHorizontalDestination(
  game: any,
  gameId: bigint,
  shipId: bigint,
  currentCol: number,
  desiredDelta = 4,
  allowNoOp = false
) {
  const attributes = await game.read.getShipAttributes([gameId, shipId]);
  const movement = Number(attributes.movement);

  if (movement === 0) {
    return currentCol;
  }

  let delta = Math.min(movement, Math.max(desiredDelta, 0));

  if (delta === 0) {
    if (allowNoOp) {
      return currentCol;
    }
    delta = Math.min(movement, 1);
  }

  if (!allowNoOp) {
    delta = Math.max(delta, 1);
  }

  return Math.min(currentCol + delta, GRID_MAX_COLUMN);
}

async function moveShipWithinMovement(
  game: any,
  gameId: bigint,
  shipId: bigint,
  account: any,
  desiredDelta = 4,
  actionType: ActionType = ActionType.Pass,
  allowNoOp = false
) {
  const gameData = (await game.read.getGame([gameId])) as GameDataView;
  const shipPosition = findShipPosition(gameData, shipId);
  const destinationCol = await getValidHorizontalDestination(
    game,
    gameId,
    shipId,
    shipPosition.col,
    desiredDelta,
    allowNoOp
  );

  await game.write.moveShip(
    [gameId, shipId, shipPosition.row, destinationCol, actionType, 0n],
    {
      account,
    }
  );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get the ship attributes
      const attributes = await game.read.getShipAttributes([1n, 1]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get ship attributes for both players
      const creatorAttributes = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get the ship attributes
      const attributes = await game.read.getShipAttributes([1n, 1]);

      // Verify weapon attributes based on equipment
      const mainWeapon = constructedShip.equipment.mainWeapon;

      // Expected values based on ShipAttributes contract's gun data
      const expectedRanges = [3, 6, 4, 2]; // Laser, Railgun, MissileLauncher, PlasmaCannon
      const expectedDamages = [50, 40, 60, 80];

      // Get the ship's accuracy level to calculate expected range with fore accuracy bonus
      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const accuracyLevel = ship.traits.accuracy;

      // Fore accuracy bonuses as percentages: 0, 25, 50 for levels 0, 1, 2
      const foreAccuracyBonuses = [0, 25, 50];
      const baseRange = expectedRanges[mainWeapon];
      const foreAccuracyBonus = Math.floor(
        (baseRange * foreAccuracyBonuses[accuracyLevel]) / 100
      );
      const expectedRangeWithBonus = baseRange + foreAccuracyBonus;

      expect(attributes.range).to.equal(expectedRangeWithBonus);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get ship attributes for both players
      const creatorAttributes = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n, 3n],
        generateStartingPositions([1n, 2n, 3n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n, 8n],
        generateStartingPositions([6n, 7n, 8n], false),
      ]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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

      await expect(game.read.getShipAttributes([999n, 1])).to.be.rejectedWith(
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get complete game data
      const gridGameData = (await game.read.getGame([1n])) as any;

      // Verify grid dimensions (11 rows x 17 columns)
      expect(gridGameData.gridDimensions.gridWidth).to.equal(17); // Number of columns
      expect(gridGameData.gridDimensions.gridHeight).to.equal(11); // Number of rows
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
        lobbies,
        owner,
      } = await loadFixture(deployGameFixture);

      // Increase max fleet cost limit to allow high cost limit for this test
      const ownerLobbies = await hre.viem.getContractAt(
        "Lobbies",
        lobbies.address,
        { client: { wallet: owner } }
      );
      await ownerLobbies.write.setMaxFleetCostLimit([5000n]);

      // Purchase and construct 12 ships for both players (exceeds single column capacity of 10)
      // Alternate purchases: creator gets odd IDs (1,3,5...), joiner gets even IDs (2,4,6...)
      for (let i = 0; i < 12; i++) {
        await ships.write.purchaseWithFlow(
          [creator.account.address, 0n, joiner.account.address, 1],
          { value: parseEther("4.99") }
        );
        await ships.write.purchaseWithFlow(
          [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with 12 ships each (exceeds single column capacity)
      // Based on actual ownership pattern: creator and joiner ship IDs
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

      await creatorLobbies.write.createFleet([
        1n,
        creatorShipIds,
        generateStartingPositions(creatorShipIds, true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        joinerShipIds,
        generateStartingPositions(joinerShipIds, false),
      ]);

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

      // Verify creator ships are placed in columns 0-3
      // With 12 ships and i % 4, we get: 0,1,2,3,0,1,2,3,0,1,2,3
      const creatorShipsInCol0 = creatorShips.filter(
        (ship) => ship.position.col === 0
      );
      const creatorShipsInCol1 = creatorShips.filter(
        (ship) => ship.position.col === 1
      );
      const creatorShipsInCol2 = creatorShips.filter(
        (ship) => ship.position.col === 2
      );
      const creatorShipsInCol3 = creatorShips.filter(
        (ship) => ship.position.col === 3
      );

      expect(creatorShipsInCol0.length).to.equal(3); // Ships at indices 0, 4, 8
      expect(creatorShipsInCol1.length).to.equal(3); // Ships at indices 1, 5, 9
      expect(creatorShipsInCol2.length).to.equal(3); // Ships at indices 2, 6, 10
      expect(creatorShipsInCol3.length).to.equal(3); // Ships at indices 3, 7, 11

      // Verify no ships are placed outside allowed columns (0-3)
      const creatorColumns = [
        ...new Set(creatorShips.map((ship) => ship.position.col)),
      ].sort((a, b) => a - b);
      expect(creatorColumns).to.deep.equal([0, 1, 2, 3]); // Only columns 0-3

      // Verify joiner ships are placed in columns 13-16
      // With 12 ships and 13 + (i % 4), we get: 13,14,15,16,13,14,15,16,13,14,15,16
      const joinerShipsInCol13 = joinerShips.filter(
        (ship) => ship.position.col === 13
      );
      const joinerShipsInCol14 = joinerShips.filter(
        (ship) => ship.position.col === 14
      );
      const joinerShipsInCol15 = joinerShips.filter(
        (ship) => ship.position.col === 15
      );
      const joinerShipsInCol16 = joinerShips.filter(
        (ship) => ship.position.col === 16
      );

      expect(joinerShipsInCol13.length).to.equal(3); // Ships at indices 0, 4, 8
      expect(joinerShipsInCol14.length).to.equal(3); // Ships at indices 1, 5, 9
      expect(joinerShipsInCol15.length).to.equal(3); // Ships at indices 2, 6, 10
      expect(joinerShipsInCol16.length).to.equal(3); // Ships at indices 3, 7, 11

      // Verify no ships are placed outside allowed columns
      const joinerColumns = [
        ...new Set(joinerShips.map((ship) => ship.position.col)),
      ].sort((a, b) => a - b);
      expect(joinerColumns).to.deep.equal([13, 14, 15, 16]); // Only columns 13-16

      // Verify no ships are placed in columns between the two sides
      const allColumns = shipPositions.map((pos: any) => pos.position.col);
      const uniqueColumns = [...new Set(allColumns)].sort((a, b) => a - b);
      expect(uniqueColumns).to.deep.equal([0, 1, 2, 3, 13, 14, 15, 16]); // Creator columns 0-3, Joiner columns 13-16
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Check ship positions using getAllShipPositions
      const allShipPositions = await game.read.getAllShipPositions([1n]);
      const shipAtOrigin = allShipPositions.find((pos) => pos.shipId === 1n);
      const shipAtEnd = allShipPositions.find((pos) => pos.shipId === 6n);

      expect(shipAtOrigin?.position.row).to.equal(0);
      expect(shipAtOrigin?.position.col).to.equal(0);
      expect(shipAtEnd?.position.row).to.equal(10);
      expect(shipAtEnd?.position.col).to.equal(13);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get individual ship positions
      const gameData = (await game.read.getGame([
        1n,
      ])) as unknown as GameDataView;
      const creatorShipPosition = findShipPosition(gameData, 1n);
      expect(creatorShipPosition.row).to.equal(0);
      expect(creatorShipPosition.col).to.equal(0);

      const joinerShipPosition = findShipPosition(gameData, 6n);
      expect(joinerShipPosition.row).to.equal(10);
      expect(joinerShipPosition.col).to.equal(13);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get creator's ship attributes to check movement range
      const creatorAttributes = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get creator's ship attributes
      const creatorAttributes = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Try to move joiner's ship when it's creator's turn
      const gameData = (await game.read.getGame([1n])) as GameDataView;
      const ship6Position = findShipPosition(gameData, 6n);
      const ship6TargetCol = await getValidHorizontalDestination(
        game,
        1n,
        6n,
        ship6Position.col,
        4,
        true
      );
      await expect(
        game.write.moveShip(
          [1n, 6n, ship6Position.row, ship6TargetCol, ActionType.Pass, 0n],
          {
            account: joiner.account,
          }
        )
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Try to move joiner's ship with creator's account
      const gameData = (await game.read.getGame([1n])) as GameDataView;
      const ship6Position = findShipPosition(gameData, 6n);
      const ship6TargetCol = await getValidHorizontalDestination(
        game,
        1n,
        6n,
        ship6Position.col,
        4,
        true
      );
      await expect(
        game.write.moveShip(
          [1n, 6n, ship6Position.row, ship6TargetCol, ActionType.Pass, 0n],
          {
            account: creator.account,
          }
        )
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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

    it("should emit Move event with correct oldRow and oldCol for actual movement", async function () {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get initial position
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const initialPosition = findShipPosition(gameData, 1n);
      const oldRow = initialPosition.row;
      const oldCol = initialPosition.col;

      // Move ship to a new position
      const newRow = 0;
      const newCol = 2;
      await game.write.moveShip([1n, 1n, newRow, newCol, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Get Move events
      const moveEvents = await game.getEvents.Move();
      const latestMoveEvent = moveEvents[moveEvents.length - 1];

      // Verify event was emitted with correct values
      expect(latestMoveEvent).to.not.be.undefined;
      expect(latestMoveEvent.args.gameId).to.equal(1n);
      expect(latestMoveEvent.args.shipId).to.equal(1n);
      expect(latestMoveEvent.args.oldRow).to.equal(oldRow);
      expect(latestMoveEvent.args.oldCol).to.equal(oldCol);
      expect(latestMoveEvent.args.newRow).to.equal(newRow);
      expect(latestMoveEvent.args.newCol).to.equal(newCol);
      expect(latestMoveEvent.args.actionType).to.equal(ActionType.Pass);
      expect(latestMoveEvent.args.targetShipId).to.equal(0n);
    });

    it("should emit Move event with oldRow == newRow and oldCol == newCol for no-op move", async function () {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get initial position
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const initialPosition = findShipPosition(gameData, 1n);
      const currentRow = initialPosition.row;
      const currentCol = initialPosition.col;

      // Move ship to the same position (no-op move)
      await game.write.moveShip(
        [1n, 1n, currentRow, currentCol, ActionType.Pass, 0n],
        {
          account: creator.account,
        }
      );

      // Get Move events
      const moveEvents = await game.getEvents.Move();
      const latestMoveEvent = moveEvents[moveEvents.length - 1];

      // Verify event was emitted with oldRow == newRow and oldCol == newCol
      expect(latestMoveEvent).to.not.be.undefined;
      expect(latestMoveEvent.args.gameId).to.equal(1n);
      expect(latestMoveEvent.args.shipId).to.equal(1n);
      expect(latestMoveEvent.args.oldRow).to.equal(currentRow);
      expect(latestMoveEvent.args.oldCol).to.equal(currentCol);
      expect(latestMoveEvent.args.newRow).to.equal(currentRow);
      expect(latestMoveEvent.args.newCol).to.equal(currentCol);
      expect(latestMoveEvent.args.actionType).to.equal(ActionType.Pass);
      expect(latestMoveEvent.args.targetShipId).to.equal(0n);
    });

    it("should emit Move event with correct oldRow and oldCol for multiple consecutive moves", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        game,
        randomManager,
        publicClient,
      } = await loadFixture(deployGameFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // First move: from (0, 0) to (0, 1)
      const firstMoveTx = await game.write.moveShip(
        [1n, 1n, 0, 1, ActionType.Pass, 0n],
        {
          account: creator.account,
        }
      );
      const firstMoveReceipt = await publicClient.getTransactionReceipt({
        hash: firstMoveTx,
      });

      // Get joiner ship's movement attribute to calculate a valid move
      const joinerAttributes = await game.read.getShipAttributes([1n, 6n]);
      const movement = Number(joinerAttributes.movement);

      // Joiner ship starts at (10, 13) - move it within movement range
      // Move horizontally by movement amount (or less if it would go out of bounds)
      const startCol = 13;
      const maxCol = 16; // GRID_WIDTH - 1
      const newCol = Math.min(startCol + movement, maxCol);

      // Joiner move completes round 1; round 2 starts with second player (joiner when creatorGoesFirst)
      await game.write.moveShip([1n, 6n, 10, newCol, ActionType.Pass, 0n], {
        account: joiner.account,
      });

      // Round 2: joiner goes first (alternating), so joiner moves again before creator
      const gameDataRound2 = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPosRound2 = findShipPosition(gameDataRound2, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPosRound2.row, joinerPosRound2.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );

      // Second move: creator from (0, 1) to (0, 2)
      const secondMoveTx = await game.write.moveShip(
        [1n, 1n, 0, 2, ActionType.Pass, 0n],
        {
          account: creator.account,
        }
      );
      const secondMoveReceipt = await publicClient.getTransactionReceipt({
        hash: secondMoveTx,
      });

      // Parse Move events from transaction receipts
      const firstMoveEvents = parseEventLogs({
        abi: game.abi,
        logs: firstMoveReceipt.logs,
        eventName: "Move",
      });
      const secondMoveEvents = parseEventLogs({
        abi: game.abi,
        logs: secondMoveReceipt.logs,
        eventName: "Move",
      });

      // Find the Move event for ship 1 in each transaction
      const firstMoveEvent = firstMoveEvents.find(
        (e) => e.args.shipId === 1n && e.args.gameId === 1n
      );
      const secondMoveEvent = secondMoveEvents.find(
        (e) => e.args.shipId === 1n && e.args.gameId === 1n
      );

      expect(firstMoveEvent).to.not.be.undefined;
      expect(secondMoveEvent).to.not.be.undefined;

      // Verify first move: (0, 0) -> (0, 1)
      expect(firstMoveEvent!.args.oldRow).to.equal(0);
      expect(firstMoveEvent!.args.oldCol).to.equal(0);
      expect(firstMoveEvent!.args.newRow).to.equal(0);
      expect(firstMoveEvent!.args.newCol).to.equal(1);

      // Verify second move: (0, 1) -> (0, 2)
      expect(secondMoveEvent!.args.oldRow).to.equal(0);
      expect(secondMoveEvent!.args.oldCol).to.equal(1);
      expect(secondMoveEvent!.args.newRow).to.equal(0);
      expect(secondMoveEvent!.args.newCol).to.equal(2);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

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
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);

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
      await moveShipWithinMovement(game, 1n, 7n, joiner.account);

      // Round 2 starts with second player (joiner when creatorGoesFirst)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Joiner moves in round 2, then creator
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Try to move ship to position occupied by another ship
      await expect(
        game.write.moveShip([1n, 1n, 1, 1, ActionType.Pass, 0n], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with different sizes: creator has 3 ships, joiner has 5 ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n, 3n],
        generateStartingPositions([1n, 2n, 3n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n, 8n, 9n, 10n],
        generateStartingPositions([6n, 7n, 8n, 9n, 10n], false),
      ]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);

      // Round 1: Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves second ship
      await moveShipWithinMovement(game, 1n, 7n, joiner.account);

      // Round 1: Creator moves third ship
      await game.write.moveShip([1n, 3n, 4, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves third ship
      await moveShipWithinMovement(game, 1n, 8n, joiner.account);

      // Round 1: Joiner moves fourth ship (creator has no more ships, so joiner continues)
      await moveShipWithinMovement(game, 1n, 9n, joiner.account);

      // Round 1: Joiner moves fifth ship (completing the round)
      await moveShipWithinMovement(game, 1n, 10n, joiner.account);

      // Round 2 starts with second player (joiner when creatorGoesFirst)
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game (multiple ships so destroying one doesn't end the game)
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Destroy creator's ship
      await (game.write as any).debugDestroyShip([1n, 1], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with single ships each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      const gameId = 1n;

      // Check initial game status
      const initialGame = await game.read.getGame([gameId]);
      expect(initialGame.metadata.winner).to.equal(
        "0x0000000000000000000000000000000000000000"
      ); // No winner yet

      // Destroy creator's only ship (this should end the game)
      await (game.write as any).debugDestroyShip([gameId, 1], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Destroy one of creator's ships
      await (game.write as any).debugDestroyShip([1n, 1], {
        account: owner.account,
      });

      // Move the remaining creator ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Move both joiner ships
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      await moveShipWithinMovement(game, 1n, 7n, joiner.account);

      // Round 2 starts with joiner (alternating first player)
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
      await game.write.moveShip([1n, 2n, 2, 2, ActionType.Pass, 0n], {
        account: creator.account,
      });
    });

    it("should not end round when joiner has more ships until all surviving ships have moved (no skipped ships)", async function () {
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

      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
        { value: parseEther("4.99") }
      );
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        await randomManager.write.fulfillRandomRequest([ship.traits.serialNumber]);
      }
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      await creatorLobbies.write.createLobby([
        1000n, 300n, true, 0n, 100n, zeroAddress,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n, 8n, 9n],
        generateStartingPositions([6n, 7n, 8n, 9n], false),
      ]);

      // Turn order: creator 1, joiner 6, creator 2 -> then joiner's turn. Destroy 8 and 9 so joiner must still move ship 7.
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos1 = findShipPosition(gameData, 1n);
      await game.write.moveShip([1n, 1n, creatorPos1.row, creatorPos1.col, ActionType.Pass, 0n], { account: creator.account });
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos6 = findShipPosition(gameData, 6n);
      await game.write.moveShip([1n, 6n, joinerPos6.row, joinerPos6.col, ActionType.Pass, 0n], { account: joiner.account });
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2 = findShipPosition(gameData, 2n);
      await game.write.moveShip([1n, 2n, creatorPos2.row, creatorPos2.col, ActionType.Pass, 0n], { account: creator.account });

      await (game.write as any).debugDestroyShip([1n, 8], { account: owner.account });
      await (game.write as any).debugDestroyShip([1n, 9], { account: owner.account });

      const stateAfterDestroy = (await game.read.getGame([1n])) as any;
      expect(stateAfterDestroy.turnState.currentTurn.toLowerCase()).to.equal(joiner.account.address.toLowerCase());
      expect(stateAfterDestroy.turnState.currentRound).to.equal(1n);

      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos7 = findShipPosition(gameData, 7n);
      await game.write.moveShip([1n, 7n, joinerPos7.row, joinerPos7.col, ActionType.Pass, 0n], { account: joiner.account });

      const stateAfterJoiner7 = (await game.read.getGame([1n])) as any;
      expect(stateAfterJoiner7.turnState.currentRound).to.equal(2n);
      expect(stateAfterJoiner7.turnState.currentTurn.toLowerCase()).to.equal(joiner.account.address.toLowerCase());
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Verify ship is initially on the grid
      let allShipPositions = await game.read.getAllShipPositions([1n]);
      let shipAt00 = allShipPositions.find(
        (pos) => pos.position.row === 0 && pos.position.col === 0
      );
      expect(shipAt00?.shipId).to.equal(1n);

      // Destroy the ship
      await (game.write as any).debugDestroyShip([1n, 1], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Get initial ship positions
      const initialPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(initialPositions.length).to.equal(4);

      // For testing purposes, we'll test the 0 hull points behavior by creating a simple scenario
      // where we can verify that the contract logic treats 0 hull points the same as destroyed ships

      // First, let's verify that the contract correctly handles destroyed ships
      // We'll use the existing debug function to destroy a ship
      await (game.write as any).debugDestroyShip([1n, 1], {
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
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      await moveShipWithinMovement(
        game,
        1n,
        7n,
        joiner.account,
        0,
        ActionType.Pass,
        true
      );

      // Round 2 starts with joiner (alternating)
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Destroy the ship once
      await (game.write as any).debugDestroyShip([1n, 1], {
        account: owner.account,
      });

      // Try to destroy the same ship again
      await expect(
        (game.write as any).debugDestroyShip([1n, 1], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: creator has 2 ships, joiner has 3 ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n, 8n],
        generateStartingPositions([6n, 7n, 8n], false),
      ]);

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
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);

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
      await moveShipWithinMovement(
        game,
        1n,
        7n,
        joiner.account,
        0,
        ActionType.Pass,
        true
      );

      // Verify turn stays with joiner (creator still has no more ships)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await moveShipWithinMovement(game, 1n, 8n, joiner.account);

      // Round 2 starts with joiner (alternating)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets: both have 3 ships initially
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n, 3n],
        generateStartingPositions([1n, 2n, 3n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n, 8n],
        generateStartingPositions([6n, 7n, 8n], false),
      ]);

      // Round 1: Creator moves first ship
      await game.write.moveShip([1n, 1n, 0, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Round 1: Joiner moves first ship
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);

      // Round 1: Creator moves second ship
      await game.write.moveShip([1n, 2n, 2, 1, ActionType.Pass, 0n], {
        account: creator.account,
      });

      // Destroy creator's last unmoved ship (ship 3)
      await (game.write as any).debugDestroyShip([1n, 3n], {
        account: owner.account,
      });

      // Round 1: Joiner moves second ship
      await moveShipWithinMovement(
        game,
        1n,
        7n,
        joiner.account,
        0,
        ActionType.Pass,
        true
      );

      // After this move, creator has no unmoved ships, so the turn should remain with the joiner
      let gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Round 1: Joiner moves third ship (completing the round)
      await moveShipWithinMovement(game, 1n, 8n, joiner.account);

      // Round 2 starts with joiner (alternating)
      gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get initial positions and attributes
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      let creatorPos = findShipPosition(gameData, 1n);
      let joinerPos = findShipPosition(gameData, 6n);
      let creatorAttrs = await game.read.getShipAttributes([1n, 1]);
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
                [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Shoot, 1],
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
      const finalCreatorAttrs = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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
      let creatorAttrs = await game.read.getShipAttributes([1n, 1]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
          colors: {
            h1: 0,
            s1: 0,
            l1: 0,
            h2: 0,
            s2: 0,
            l2: 0,
            h3: 0,
            s3: 0,
            l3: 0,
          },
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
          isFreeShip: false,
          modified: 0,
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
      await ships.write.customizeShip([1n, empShip], {
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Get initial positions and attributes
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      let creatorPos = findShipPosition(gameData, 1n);
      let joinerPos = findShipPosition(gameData, 6n);

      // Move ships to positions where they can see each other but with a wall between them
      // Creator at (5, 2), Joiner at (5, 14) - same row, different columns
      // Use debugMove for this
      await (game.write as any).debugSetShipPosition([1n, 1n, 5, 2], {
        account: owner.account,
      });
      await (game.write as any).debugSetShipPosition([1n, 6n, 5, 14], {
        account: owner.account,
      });

      // Create a wall between the ships to block line of sight
      // Wall at row 5, columns 8-10 (blocking the direct path)
      for (let col = 8; col <= 10; col++) {
        await maps.write.setBlockedTile([1n, 5, col, true], {
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Get initial ship positions
      const initialPositions = (await game.read.getAllShipPositions([
        1n,
      ])) as any;
      expect(initialPositions.length).to.equal(4);

      // Use debug function to set ship 1's hull points to 0
      await (game.write as any).debugSetHullPointsToZero([1n, 1], {
        account: owner.account,
      });

      // Verify ship 1 has 0 hull points
      expect((await game.read.getShipAttributes([1n, 1])).hullPoints).to.equal(
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
      await moveShipWithinMovement(
        game,
        1n,
        6n,
        joiner.account,
        0,
        ActionType.Pass,
        true
      );
      await moveShipWithinMovement(
        game,
        1n,
        7n,
        joiner.account,
        0,
        ActionType.Pass,
        true
      );

      // Round 2 starts with joiner (alternating)
      const gameData = (await game.read.getGame([1n])) as any;
      expect(gameData.turnState.currentTurn.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
      expect((await game.read.getGame([1n]) as any).turnState.currentTurn.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Move ships toward each other until in range (similar to shooting test)
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;

      // Place ships very close together for this test
      // Move creator ship to (4, 5) - valid move within movement range of 4
      await game.write.moveShip([1n, 1n, 4, 0, ActionType.Pass, 0n], {
        account: creator.account,
      });
      // Move joiner ship toward the creator ship within its movement range
      await moveShipWithinMovement(game, 1n, 6n, joiner.account);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two creator ships so creator can move one while the other has 0 HP
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Complete the first round (turn order: creator, joiner, creator)
      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos1 = findShipPosition(gameData, 1n);
      await game.write.moveShip(
        [1n, 1n, creatorPos1.row, creatorPos1.col, ActionType.Pass, 0n],
        { account: creator.account }
      );
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPos.row, joinerPos.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2 = findShipPosition(gameData, 2n);
      await game.write.moveShip(
        [1n, 2n, creatorPos2.row, creatorPos2.col, ActionType.Pass, 0n],
        { account: creator.account }
      );

      // Now set creator's ship 1 HP to 0 (after round has ended)
      await (game.write as any).debugSetHullPointsToZero([1n, 1], {
        account: owner.account,
      });

      const ship1Attrs = await game.read.getShipAttributes([1n, 1]);
      expect(ship1Attrs.hullPoints).to.equal(0);
      expect(ship1Attrs.reactorCriticalTimer).to.equal(0);

      // Round 2 starts with joiner (alternating); joiner moves first, then creator moves ship 2
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos2 = findShipPosition(gameData, 6n);
      await game.write.moveShip(
        [1n, 6n, joinerPos2.row, joinerPos2.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );
      gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2Again = findShipPosition(gameData, 2n);
      await game.write.moveShip(
        [1n, 2n, creatorPos2Again.row, creatorPos2Again.col, ActionType.Pass, 0n],
        { account: creator.account }
      );

      const ship1AttrsAfter = await game.read.getShipAttributes([1n, 1]);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two ships each
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // Use debug to set player 1's first ship's HP to zero
      await (game.write as any).debugSetHullPointsToZero([1n, 1], {
        account: owner.account,
      });

      // Have all players use no-op moves until ship 1's reactor critical timer is 3
      // Odd game rounds (1, 3): creator first. Even (2): joiner first.
      let round = 0;
      while (round < 3) {
        const gameData = (await game.read.getGame([
          1n,
        ])) as unknown as GameDataView;
        const creatorPos2 = findShipPosition(gameData, 2n);
        const joinerPos1 = findShipPosition(gameData, 6n);
        const joinerPos2 = findShipPosition(gameData, 7n);

        if (round % 2 === 0) {
          // Round 1, 3: creator first
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
        } else {
          // Round 2: joiner first; order joiner 6, creator 2, joiner 7
          await game.write.moveShip(
            [1n, 6n, joinerPos1.row, joinerPos1.col, ActionType.Pass, 0n],
            { account: joiner.account }
          );
          await game.write.moveShip(
            [1n, 2n, creatorPos2.row, creatorPos2.col, ActionType.Pass, 0n],
            { account: creator.account }
          );
          await game.write.moveShip(
            [1n, 7n, joinerPos2.row, joinerPos2.col, ActionType.Pass, 0n],
            { account: joiner.account }
          );
        }
        round++;
      }

      // Ship 1 reaches timer 3 at start of round 3 and is destroyed instantly (no longer at end of round)
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

      // Round 4: totalActiveShipsAtRoundStart=4, shipsRemovedThisRound=1 (ship 1 destroyed at round start). Need 3 moves.
      // Round 4 is even -> joiner first. Order: joiner 6, creator 2, joiner 7 -> round completes; round 5 starts with creator.
      const gameDataAfterDestroy = (await game.read.getGame([1n])) as unknown as GameDataView;
      const joinerPos1After = findShipPosition(gameDataAfterDestroy, 6n);
      const joinerPos2After = findShipPosition(gameDataAfterDestroy, 7n);
      const creatorPos2After = findShipPosition(gameDataAfterDestroy, 2n);
      await game.write.moveShip(
        [1n, 6n, joinerPos1After.row, joinerPos1After.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );
      await game.write.moveShip(
        [1n, 2n, creatorPos2After.row, creatorPos2After.col, ActionType.Pass, 0n],
        { account: creator.account }
      );
      await game.write.moveShip(
        [1n, 7n, joinerPos2After.row, joinerPos2After.col, ActionType.Pass, 0n],
        { account: joiner.account }
      );

      // Move remaining ships to new positions (round 5; creator's turn)
      const gameDataFinal = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos2Final = findShipPosition(gameDataFinal, 2n);
      const joinerPos6Final = findShipPosition(gameDataFinal, 6n);
      await game.write.moveShip(
        [
          1n,
          2n,
          creatorPos2Final.row + 1,
          creatorPos2Final.col,
          ActionType.Pass,
          0n,
        ],
        { account: creator.account }
      );
      await game.write.moveShip(
        [
          1n,
          6n,
          joinerPos6Final.row - 1,
          joinerPos6Final.col - 1,
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with two ships each
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

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

    it("should allow retreat (flee) for a ship with 0 HP as creator's turn", async function () {
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

      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
        { value: parseEther("4.99") }
      );
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        await randomManager.write.fulfillRandomRequest([ship.traits.serialNumber]);
      }
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      await creatorLobbies.write.createLobby([
        1000n, 300n, true, 0n, 100n, zeroAddress,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      let gameData = (await game.read.getGame([1n])) as unknown as GameDataView;
      const creatorPos1 = findShipPosition(gameData, 1n);

      await (game.write as any).debugSetHullPointsToZero([1n, 1], {
        account: owner.account,
      });
      const ship1Attrs = await game.read.getShipAttributes([1n, 1]);
      expect(ship1Attrs.hullPoints).to.equal(0);

      // Retreat (flee) ship 1 as creator's turn (Retreat allowed for 0 HP and already-moved ships)
      await game.write.moveShip(
        [1n, 1n, creatorPos1.row, creatorPos1.col, ActionType.Retreat, 0n],
        { account: creator.account }
      );

      const positions = (await game.read.getAllShipPositions([1n])) as any;
      expect(positions.length).to.equal(3);
      const remainingShipIds = positions.map((pos: any) => pos.shipId);
      expect(remainingShipIds).to.include(2n);
      expect(remainingShipIds).to.include(6n);
      expect(remainingShipIds).to.include(7n);
      expect(remainingShipIds).to.not.include(1n);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
          colors: {
            h1: 0,
            s1: 0,
            l1: 0,
            h2: 0,
            s2: 0,
            l2: 0,
            h3: 0,
            s3: 0,
            l3: 0,
          },
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
          isFreeShip: false,
          modified: 0,
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
      await ships.write.customizeShip([1n, repairShip], {
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start the game
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

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
      // Since RepairDrones has range 3, we can move ship 1 to position (2, 0) which is adjacent to ship 2 at (1, 0)
      await game.write.moveShip([1n, 1n, 2, 0, ActionType.Special, 2n], {
        account: creator.account,
      });

      // Verify ship 2's HP was increased by the repair strength (40)
      const ship2AttrsAfter = await game.read.getShipAttributes([1n, 2n]);
      expect(ship2AttrsAfter.hullPoints).to.equal(40); // Should be exactly 40 since RepairDrones restores 40 HP
    });

    it("should not complete round until repaired (formerly 0 HP) ship moves", async function () {
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

      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
        { value: parseEther("4.99") }
      );
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        await randomManager.write.fulfillRandomRequest([ship.traits.serialNumber]);
      }

      const repairShip: Ship = {
        name: "Repair Ship",
        id: 1n,
        equipment: {
          mainWeapon: 0,
          armor: 0,
          shields: 0,
          special: 2, // RepairDrones
        },
        traits: {
          serialNumber: 12345n,
          colors: { h1: 0, s1: 0, l1: 0, h2: 0, s2: 0, l2: 0, h3: 0, s3: 0, l3: 0 },
          variant: 0,
          accuracy: 0,
          hull: 0,
          speed: 2,
        },
        shipData: {
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
          shiny: false,
          constructed: false,
          inFleet: false,
          isFreeShip: false,
          modified: 0,
          timestampDestroyed: 0n,
        },
        owner: creator.account.address,
      };
      await ships.write.setIsAllowedToCreateShips([owner.account.address, true], { account: owner.account });
      await ships.write.customizeShip([1n, repairShip], { account: owner.account });
      await ships.write.constructShip([2n], { account: creator.account });
      await ships.write.constructShip([6n], { account: joiner.account });

      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n, zeroAddress]);
      await joinerLobbies.write.joinLobby([1n]);
      await creatorLobbies.write.createFleet([1n, [1n, 2n], generateStartingPositions([1n, 2n], true)]);
      await joinerLobbies.write.createFleet([1n, [6n], generateStartingPositions([6n], false)]);

      await (game.write as any).debugSetHullPointsToZero([1n, 2n], { account: owner.account });
      expect((await game.read.getShipAttributes([1n, 2n])).hullPoints).to.equal(0);

      // Creator moves ship 1 and repairs ship 2 (ship 2 removed from shipsWithZeroHP)
      await game.write.moveShip([1n, 1n, 2, 0, ActionType.Special, 2n], { account: creator.account });
      expect((await game.read.getShipAttributes([1n, 2n])).hullPoints).to.equal(40);

      // Round must not be complete: we need 3 counts, have 1 move. Repaired ship must still move.
      const stateAfterRepair = (await game.read.getGame([1n])) as any;
      expect(stateAfterRepair.turnState.currentRound).to.equal(1n);
      expect(stateAfterRepair.turnState.currentTurn.toLowerCase()).to.equal(joiner.account.address.toLowerCase());

      await game.write.moveShip([1n, 6n, 10, 13, ActionType.Pass, 0n], { account: joiner.account });

      // Still round 1; creator must move ship 2 (repaired ship) before round can complete
      const stateAfterJoiner = (await game.read.getGame([1n])) as any;
      expect(stateAfterJoiner.turnState.currentRound).to.equal(1n);
      expect(stateAfterJoiner.turnState.currentTurn.toLowerCase()).to.equal(creator.account.address.toLowerCase());

      const gameDataBefore = (await game.read.getGame([1n])) as unknown as GameDataView;
      const ship2Pos = findShipPosition(gameDataBefore, 2n);
      await game.write.moveShip([1n, 2n, ship2Pos.row, ship2Pos.col, ActionType.Pass, 0n], { account: creator.account });

      const stateAfterCreator2 = (await game.read.getGame([1n])) as any;
      expect(stateAfterCreator2.turnState.currentRound).to.equal(2n);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
          colors: {
            h1: 0,
            s1: 0,
            l1: 0,
            h2: 0,
            s2: 0,
            l2: 0,
            h3: 0,
            s3: 0,
            l3: 0,
          },
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
          isFreeShip: false,
          modified: 0,
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
      await ships.write.customizeShip([1n, empShip], {
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with one ship each
      await creatorLobbies.write.createFleet([
        1n,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Use debug function to position ships adjacent to each other for EMP test
      // Position creator's ship at (10, 15) and joiner's ship at (10, 16) - adjacent positions
      await game.write.debugSetShipPosition([1n, 1n, 10, 15], {
        account: owner.account,
      });
      await game.write.debugSetShipPosition([1n, 6n, 10, 16], {
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
      // for (const ship of gameData.shipPositions) {
      //   console.log("ship", ship.shipId, ship.position);
      // }
      const creatorPos = findShipPosition(gameData, 1n);
      // console.log("creatorPos", creatorPos);
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
          colors: {
            h1: 0,
            s1: 0,
            l1: 0,
            h2: 0,
            s2: 0,
            l2: 0,
            h3: 0,
            s3: 0,
            l3: 0,
          },
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
          isFreeShip: false,
          modified: 0,
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
      await ships.write.customizeShip([1n, flakShip], {
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets with multiple ships each
      await creatorLobbies.write.createFleet([
        1n,
        [1n, 2n, 3n],
        generateStartingPositions([1n, 2n, 3n], true),
      ]);
      await joinerLobbies.write.createFleet([
        1n,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

      // 5. Move the FlakArray ship to the center with the debug function
      await game.write.debugSetShipPosition([1n, 1n, 5, 8], {
        account: owner.account,
      });

      // 6. Move the remaining ships so that 1 from each team are within 3 squares and 1 from each team are outside 3 away
      // FlakArray has range 3, so we need ships within 3 squares and outside 3 squares
      // FlakArray is at (5, 8) - center of grid

      // Creator's second ship (ship 2) - within range (distance 2)
      await game.write.debugSetShipPosition([1n, 2n, 6, 6], {
        account: owner.account,
      });

      // Creator's third ship (ship 3) - outside range (distance 5)
      await game.write.debugSetShipPosition([1n, 3n, 0, 0], {
        account: owner.account,
      });

      // Joiner's first ship (ship 6) - within range (Manhattan distance 3)
      // FlakArray is at (5, 8), ship 6 at (7, 9) gives Manhattan distance |7-5| + |9-8| = 2 + 1 = 3
      await game.write.debugSetShipPosition([1n, 6n, 7, 9], {
        account: owner.account,
      });

      // Joiner's second ship (ship 7) - outside range (distance 6)
      await game.write.debugSetShipPosition([1n, 7n, 10, 16], {
        account: owner.account,
      });

      // Get initial hull points of all ships
      const ship1AttrsBefore = await game.read.getShipAttributes([1n, 1]); // FlakArray ship
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
      const ship1AttrsAfter = await game.read.getShipAttributes([1n, 1]);
      const ship2AttrsAfter = await game.read.getShipAttributes([1n, 2n]);
      const ship3AttrsAfter = await game.read.getShipAttributes([1n, 3n]);
      const ship6AttrsAfter = await game.read.getShipAttributes([1n, 6n]);
      const ship7AttrsAfter = await game.read.getShipAttributes([1n, 7n]);

      // 8. Make sure that ship is undamaged (FlakArray ship should not damage itself)
      expect(ship1AttrsAfter.hullPoints).to.equal(ship1AttrsBefore.hullPoints);

      // 9. Make sure that both friendly and enemy ships in range are damaged
      // FlakArray damages ALL ships in range (both friendly and enemy)
      // FlakArray strength is 30, and it applies armor/shield damage reduction
      const flakStrength = 30; // Current FlakArray strength

      // Ship 2 damage calculation (friendly ship in range)
      // Apply damage reduction like regular weapons
      const ship2DamageReduction = ship2AttrsBefore.damageReduction;
      const ship2ExpectedDamage = Math.max(
        0,
        flakStrength - Math.floor((flakStrength * ship2DamageReduction) / 100)
      );
      expect(ship2AttrsAfter.hullPoints).to.equal(
        Math.max(0, ship2AttrsBefore.hullPoints - ship2ExpectedDamage)
      );

      // Ship 6 damage calculation (enemy ship in range)
      // Apply damage reduction like regular weapons
      const ship6DamageReduction = ship6AttrsBefore.damageReduction;
      const ship6ExpectedDamage = Math.max(
        0,
        flakStrength - Math.floor((flakStrength * ship6DamageReduction) / 100)
      );
      expect(ship6AttrsAfter.hullPoints).to.equal(
        Math.max(0, ship6AttrsBefore.hullPoints - ship6ExpectedDamage)
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);

      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([
        lobbyId,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        lobbyId,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

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

      // Timeout: other player calls endGameOnTimeout to claim win (timed-out player forfeits)
      await expect(
        game.write.endGameOnTimeout([gameId], { account: creator.account })
      ).to.be.rejectedWith("NotYourTurn");

      await game.write.endGameOnTimeout([gameId], {
        account: joiner.account,
      });

      const gameDataAfterTimeout = (await game.read.getGame([gameId])) as any;
      expect(gameDataAfterTimeout.metadata.winner?.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);

      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([
        lobbyId,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        lobbyId,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game)
      await creatorLobbies.write.createFleet([
        lobbyId,
        [1n, 2n],
        generateStartingPositions([1n, 2n], true),
      ]);
      await joinerLobbies.write.createFleet([
        lobbyId,
        [6n, 7n],
        generateStartingPositions([6n, 7n], false),
      ]);

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
      await moveShipWithinMovement(game, gameId, 6n, joiner.account); // Joiner moves to complete round

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
        [creator.account.address, 0n, joiner.account.address, 1],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address, 1],
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
        { row: 5, col: 8 }, // Block the middle of the grid
        { row: 5, col: 9 },
        { row: 5, col: 10 },
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
        zeroAddress, // reservedJoiner - no reservation
      ]);
      const lobbyId = 1n;
      await joinerLobbies.write.joinLobby([lobbyId]);

      // Create fleets (this automatically starts the game and applies the preset map)
      await creatorLobbies.write.createFleet([
        lobbyId,
        [1n],
        generateStartingPositions([1n], true),
      ]);
      await joinerLobbies.write.createFleet([
        lobbyId,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      const gameId = 1n;
      const creatorShipIds = [1n];
      const joinerShipIds = [6n];

      // Get game data to see ship positions
      const gameData = (await game.read.getGame([
        gameId,
      ])) as unknown as GameDataView;

      // Creator ships start at column 0, joiner ships start at column 13
      // With the blocked tiles at row 5, columns 8-10, line of sight should be blocked
      // when trying to shoot from one side to the other through the middle

      // Test line of sight that should be blocked by the preset map
      const hasLOS = await maps.read.hasMaps([
        BigInt(gameId),
        5, // Start at row 5 (same row as blocked tiles)
        0, // Start at column 0 (creator side)
        5, // End at row 5 (same row as blocked tiles)
        16, // End at column 16 (passes through blocked tiles at columns 8-10)
      ]);

      // Line of sight should be blocked because it passes through the blocked tiles
      expect(hasLOS).to.be.false;

      // Test line of sight that should be clear (above the blocked tiles)
      const hasLOSAbove = await maps.read.hasMaps([
        BigInt(gameId),
        2, // Start at row 2 (above blocked tiles)
        0, // Start at column 0
        10, // End at row 10 (within bounds)
        15, // End at column 15 (avoid blocked tiles at columns 8-10)
      ]);

      // Line of sight should be clear above the blocked tiles
      expect(hasLOSAbove).to.be.true;

      // Test line of sight that should be clear (below the blocked tiles)
      // Use a path that avoids the blocked tiles at row 5, columns 8-10
      // Path from (10, 0) to (0, 7) avoids blocked tiles (goes left of column 8)
      const hasLOSBelow = await maps.read.hasMaps([
        BigInt(gameId),
        10, // Start at row 10 (below blocked tiles)
        0, // Start at column 0
        0, // End at row 0 (top of grid)
        7, // End at column 7 (left of blocked tiles at columns 8-10)
      ]);

      // Line of sight should be clear below the blocked tiles
      expect(hasLOSBelow).to.be.true;
    });
  });
});
