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

// Helper function to generate starting positions
function generateStartingPositions(shipIds: bigint[], isCreator: boolean) {
  const positions = [];
  for (let i = 0; i < shipIds.length; i++) {
    if (isCreator) {
      // Creator starts in top-left, each ship 1 down, in columns 0-4
      positions.push({ row: i, col: i % 5 }); // Use columns 0-4
    } else {
      // Joiner starts in bottom-right, each ship 1 up, in columns 20-24
      positions.push({ row: 12 - i, col: 20 + (i % 5) }); // Use columns 20-24
    }
  }
  return positions;
}

describe("Lobbies", function () {
  // Restore the original deployLobbiesFixture for basic tests
  async function deployLobbiesFixture() {
    const [owner, creator, joiner, other] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();
    // Deploy all contracts using the module
    const deployed = await hre.ignition.deploy(DeployModule);
    // Create separate contract instances for each user
    const creatorLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      { client: { wallet: creator } }
    );
    const joinerLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      { client: { wallet: joiner } }
    );
    const otherLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      { client: { wallet: other } }
    );
    // Create Fleets contract instances
    const creatorFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      { client: { wallet: creator } }
    );
    const joinerFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      { client: { wallet: joiner } }
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

  // New fixture: sets up ships, lobby, and game for both players
  async function deployFullGameFixture() {
    const [owner, creator, joiner, other] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();
    const deployed = await hre.ignition.deploy(DeployModule);

    // Contract instances
    const creatorLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      { client: { wallet: creator } }
    );
    const joinerLobbies = await hre.viem.getContractAt(
      "Lobbies",
      deployed.lobbies.address,
      { client: { wallet: joiner } }
    );
    const creatorFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      { client: { wallet: creator } }
    );
    const joinerFleets = await hre.viem.getContractAt(
      "Fleets",
      deployed.fleets.address,
      { client: { wallet: joiner } }
    );
    const ships = deployed.ships;
    const randomManager = deployed.randomManager;
    const game = deployed.game;

    // Purchase and construct ships for both players
    await ships.write.purchaseWithFlow(
      [creator.account.address, 0n, joiner.account.address],
      { value: parseEther("4.99") }
    );
    await ships.write.purchaseWithFlow(
      [joiner.account.address, 0n, creator.account.address],
      { value: parseEther("4.99") }
    );
    // Fulfill random requests for all ships
    for (let i = 1; i <= 10; i++) {
      const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber;
      await randomManager.write.fulfillRandomRequest([serialNumber]);
    }
    await ships.write.constructAllMyShips({ account: creator.account });
    await ships.write.constructAllMyShips({ account: joiner.account });

    // Create lobby and join
    const costLimit = 1000n;
    const turnTime = 300n;
    const creatorGoesFirst = true;
    const tx = await creatorLobbies.write.createLobby([
      costLimit,
      turnTime,
      creatorGoesFirst,
      0n, // selectedMapId - no preset map,
      100n, // maxScore
    ]);
    await joinerLobbies.write.joinLobby([1n]);

    // Create fleets for both players
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

    return {
      lobbies: deployed.lobbies,
      creatorLobbies,
      joinerLobbies,
      creatorFleets,
      joinerFleets,
      ships,
      game,
      randomManager,
      owner,
      creator,
      joiner,
      publicClient,
      lobbyId: 1n,
      creatorFleetId: 1n,
      joinerFleetId: 1n, // assuming fleetId starts at 1 for both
      creatorShipId: 1n,
      joinerShipId: 6n,
    };
  }

  describe("Lobby Creation", function () {
    it("should create a lobby with correct initial values", async function () {
      const { creatorLobbies, creator, publicClient } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n; // 5 minutes
      const creatorGoesFirst = true;

      const tx = await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      expect(receipt.status).to.equal("success");

      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.basic.id).to.equal(1n);
      expect(lobby.basic.creator.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.basic.costLimit).to.equal(costLimit);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);
      expect(lobby.gameConfig.turnTime).to.equal(turnTime);
      expect(lobby.gameConfig.creatorGoesFirst).to.equal(creatorGoesFirst);
      expect(lobby.players.creatorFleetId).to.equal(0n);
      expect(lobby.players.joinerFleetId).to.equal(0n);

      // Check player state
      const playerState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(playerState.activeLobbiesCount).to.equal(1n);
    });

    it("should revert when creating lobby with invalid turn time", async function () {
      const { creatorLobbies } = await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const invalidTurnTime = 30n; // Less than MIN_TURN_TIME (60 seconds)
      const creatorGoesFirst = true;

      await expect(
        creatorLobbies.write.createLobby([
          costLimit,
          invalidTurnTime,
          creatorGoesFirst,
          0n, // selectedMapId - no preset map,
          100n, // maxScore
        ])
      ).to.be.rejectedWith("InvalidTurnTime");
    });

    it("should require fee for additional lobbies", async function () {
      const { creatorLobbies, creator } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // First lobby should be free
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // Second lobby should require fee
      await expect(
        creatorLobbies.write.createLobby([
          costLimit,
          turnTime,
          creatorGoesFirst,
          0n, // selectedMapId - no preset map,
          100n, // maxScore
        ])
      ).to.be.rejectedWith("InsufficientFee");

      // Should work with correct fee
      await expect(
        creatorLobbies.write.createLobby(
          [costLimit, turnTime, creatorGoesFirst, 0n, 100n], // selectedMapId - no preset map, maxScore
          {
            value: parseEther("1"),
          }
        )
      ).to.not.be.rejected;

      // Check player state after creating two lobbies
      const playerState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(playerState.activeLobbiesCount).to.equal(2n);
    });

    it("should decrement active lobbies when game starts", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployFullGameFixture);
      // Remove redundant setup code, as deployFullGameFixture already does it
      // Check states after game start
      let creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      let joinerState = (await joinerLobbies.read.getPlayerState([
        joiner.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(creatorState.activeLobbiesCount).to.equal(0n);
      expect(joinerState.activeLobbiesCount).to.equal(0n);
    });

    it("should decrement active lobbies when leaving lobby", async function () {
      const { creatorLobbies, creator } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // Check initial state
      let creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(creatorState.activeLobbiesCount).to.equal(1n);

      // Leave the lobby
      await creatorLobbies.write.leaveLobby([1n]);

      // Check state after leaving
      creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(creatorState.activeLobbiesCount).to.equal(0n);
    });

    it("should prevent creating lobby when in timeout", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Timeout the joiner
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await creatorLobbies.write.timeoutJoiner([1n]);

      // Create new lobby
      await creatorLobbies.write.createLobby(
        [costLimit, turnTime, creatorGoesFirst, 0n, 100n], // selectedMapId - no preset map, maxScore
        { value: parseEther("1") }
      );

      // Try to join while in timeout
      await expect(joinerLobbies.write.joinLobby([2n])).to.be.rejectedWith(
        "PlayerInTimeout"
      );
    });
  });

  describe("Lobby Joining", function () {
    it("should allow joining an open lobby", async function () {
      const { creatorLobbies, joinerLobbies, joiner, publicClient } =
        await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      const tx = await joinerLobbies.write.joinLobby([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });
      expect(receipt.status).to.equal("success");

      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(lobby.state.status).to.equal(LobbyStatus.FleetSelection);
    });

    it("should revert when joining non-existent lobby", async function () {
      const { joinerLobbies } = await loadFixture(deployLobbiesFixture);

      await expect(joinerLobbies.write.joinLobby([999n])).to.be.rejectedWith(
        "LobbyNotFound"
      );
    });

    it("should revert when joining a full lobby", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create first lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // First player joins
      await joinerLobbies.write.joinLobby([1n]);

      // Create second lobby
      await otherLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // Try to join first lobby while it's in FleetSelection state
      await expect(otherLobbies.write.joinLobby([1n])).to.be.rejectedWith(
        "LobbyNotOpen"
      );
    });

    it("should revert when joining while in timeout", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Timeout the joiner
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await creatorLobbies.write.timeoutJoiner([1n]);

      // Create new lobby
      await creatorLobbies.write.createLobby(
        [costLimit, turnTime, creatorGoesFirst, 0n, 100n], // selectedMapId - no preset map, maxScore
        { value: parseEther("1") }
      );

      // Try to join while in timeout
      await expect(joinerLobbies.write.joinLobby([2n])).to.be.rejectedWith(
        "PlayerInTimeout"
      );
    });

    it("should revert when creator tries to join their own lobby", async function () {
      const { creatorLobbies } = await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      await expect(creatorLobbies.write.joinLobby([1n])).to.be.rejectedWith(
        "PlayerAlreadyInLobby"
      );
    });

    it("should revert when player already in another lobby tries to join", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create first lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create second lobby
      await otherLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // Try to join second lobby while in first lobby
      await expect(joinerLobbies.write.joinLobby([2n])).to.be.rejectedWith(
        "PlayerAlreadyInLobby"
      );
    });

    it("should revert when trying to join a lobby that already has a joiner", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // First player joins
      await joinerLobbies.write.joinLobby([1n]);

      // Try to join the same lobby with a third player
      await expect(otherLobbies.write.joinLobby([1n])).to.be.rejectedWith(
        "LobbyNotOpen"
      );
    });
  });

  describe("Lobby State Changes", function () {
    it("should emit correct events when creator leaves with joiner", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner, publicClient } =
        await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Creator leaves, joiner becomes new creator
      const tx = await creatorLobbies.write.leaveLobby([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      // Check for LobbyReset event
      const events = await creatorLobbies.getEvents.LobbyReset();
      const lobbyResetEvent = events[0];
      expect(lobbyResetEvent).to.not.be.undefined;
      expect(lobbyResetEvent.args.lobbyId).to.equal(1n);
      expect(lobbyResetEvent.args.newCreator!.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Verify lobby state
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.basic.creator.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);
    });

    it("should emit correct events when creator leaves alone", async function () {
      const { creatorLobbies, creator, publicClient } = await loadFixture(
        deployLobbiesFixture
      );
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);

      // Creator leaves
      const tx = await creatorLobbies.write.leaveLobby([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      // Check for LobbyAbandoned event
      const events = await creatorLobbies.getEvents.LobbyAbandoned();
      const lobbyAbandonedEvent = events[0];
      expect(lobbyAbandonedEvent).to.not.be.undefined;
      expect(lobbyAbandonedEvent.args.lobbyId).to.equal(1n);
      expect(lobbyAbandonedEvent.args.player!.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
    });

    it("should emit correct events when joiner leaves", async function () {
      const { creatorLobbies, joinerLobbies, joiner, publicClient } =
        await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Joiner leaves
      const tx = await joinerLobbies.write.leaveLobby([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      // Check for LobbyAbandoned event
      const events = await joinerLobbies.getEvents.LobbyAbandoned();
      const lobbyAbandonedEvent = events[0];
      expect(lobbyAbandonedEvent).to.not.be.undefined;
      expect(lobbyAbandonedEvent.args.lobbyId).to.equal(1n);
      expect(lobbyAbandonedEvent.args.player!.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );

      // Verify lobby state
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);
    });

    it("should emit correct events when joiner times out", async function () {
      const { creatorLobbies, joinerLobbies, creator, publicClient } =
        await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Wait for timeout
      await hre.network.provider.send("evm_increaseTime", [301]);
      await hre.network.provider.send("evm_mine");

      // Timeout joiner
      const tx = await creatorLobbies.write.timeoutJoiner([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      // Check for LobbyReset event
      const events = await creatorLobbies.getEvents.LobbyReset();
      const lobbyResetEvent = events[0];
      expect(lobbyResetEvent).to.not.be.undefined;
      expect(lobbyResetEvent.args.lobbyId).to.equal(1n);
      expect(lobbyResetEvent.args.newCreator!.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );

      // Verify lobby state
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);
    });

    it("should emit correct events when joiner quits with penalty", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creatorFleets,
        joinerFleets,
        creator,
        joiner,
        ships,
        randomManager,
        publicClient,
      } = await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get all ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Only joiner creates a fleet
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Verify lobby is in FleetSelection state before quitting
      const lobbyBefore = await creatorLobbies.read.getLobby([1n]);
      expect(lobbyBefore.state.status).to.equal(LobbyStatus.FleetSelection);
      expect(lobbyBefore.players.joinerFleetId).to.not.equal(0n);
      expect(lobbyBefore.players.creatorFleetId).to.equal(0n);

      // Wait for creator's timeout
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await hre.network.provider.send("evm_mine");

      // Get joiner's fleet before quitting
      const joinerFleetBefore = await creatorFleets.read.getFleet([
        lobbyBefore.players.joinerFleetId,
      ]);

      // Joiner quits with penalty
      const tx = await joinerLobbies.write.quitWithPenalty([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      // Check for LobbyTerminated event
      const events = await joinerLobbies.getEvents.LobbyTerminated();
      const lobbyTerminatedEvents = events.filter(
        (e) => e.transactionHash === tx
      );
      expect(lobbyTerminatedEvents.length).to.equal(1);
      const lobbyTerminatedEvent = lobbyTerminatedEvents[0];
      expect(lobbyTerminatedEvent.args.lobbyId).to.equal(1n);

      // Verify lobby state
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);
      expect(lobby.players.joinerFleetId).to.equal(0n);
      expect(lobby.players.creatorFleetId).to.equal(0n);

      // Verify joiner's fleet is cleared
      const joinerFleetAfter = await creatorFleets.read.getFleet([
        joinerFleetBefore.id,
      ]);
      expect(joinerFleetAfter.shipIds.length).to.equal(0);

      // Verify penalty was applied to creator
      const creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(creatorState.kickCount).to.equal(1n);
    });
  });

  describe("Fleet Creation", function () {
    it("should only allow Lobbies contract to create fleets", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        fleets,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Get all ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships for both players
      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Try to create a fleet directly through the Fleets contract (should fail)
      await expect(
        fleets.write.createFleet([
          1n,
          creator.account.address,
          [1n],
          generateStartingPositions([1n], true),
          1000n,
          true, // isCreator parameter
        ])
      ).to.be.rejectedWith("NotLobbiesContract");

      // Create a fleet through the Lobbies contract (should succeed)
      await expect(
        creatorLobbies.write.createFleet([
          1n,
          [1n],
          generateStartingPositions([1n], true),
        ])
      ).to.not.be.rejected;
    });

    it("should reject fleet creation with duplicate positions", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships for testing (following the pattern from other tests)
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Fulfill random requests for all ships
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create lobby and join
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create duplicate positions array (same position twice)
      const duplicatePositions = [
        { row: 0, col: 0 }, // First ship at (0, 0)
        { row: 0, col: 0 }, // Second ship also at (0, 0) - DUPLICATE!
      ];

      // Try to create a fleet with duplicate positions (should fail)
      await expect(
        creatorLobbies.write.createFleet([1n, [1n, 2n], duplicatePositions])
      ).to.be.rejectedWith("DuplicatePosition");
    });

    it("should reject fleet creation with invalid positions for creator", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships for testing
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );

      // Fulfill random request
      const shipTuple = (await ships.read.ships([BigInt(1)])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber;
      await randomManager.write.fulfillRandomRequest([serialNumber]);

      await ships.write.constructAllMyShips({ account: creator.account });

      // Create lobby and join
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Try to create a fleet with creator ship in joiner column (should fail)
      const invalidPositions = [
        { row: 0, col: 20 }, // Creator ship in joiner column - INVALID!
      ];

      await expect(
        creatorLobbies.write.createFleet([1n, [1n], invalidPositions])
      ).to.be.rejectedWith("InvalidPosition");
    });

    it("should reject fleet creation with invalid positions for joiner", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships for testing
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Fulfill random requests
      for (let i = 1; i <= 2; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create lobby and join
      await creatorLobbies.write.createLobby([
        1000n,
        300n,
        true,
        0n, // selectedMapId - no preset map,
        100n, // maxScore
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Try to create a fleet with joiner ship in creator column (should fail)
      const invalidPositions = [
        { row: 0, col: 0 }, // Joiner ship in creator column - INVALID!
      ];

      await expect(
        joinerLobbies.write.createFleet([1n, [2n], invalidPositions])
      ).to.be.rejectedWith("InvalidPosition");
    });
  });

  describe("Lobby Tracking Functions", function () {
    it("should track player lobbies correctly", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);

      // Initially no lobbies
      let creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      let joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      expect(creatorLobbyIds.length).to.equal(0);
      expect(joinerLobbyIds.length).to.equal(0);

      // Creator creates a lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);

      // Check creator has the lobby
      creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      expect(creatorLobbyIds.length).to.equal(1);
      expect(creatorLobbyIds[0]).to.equal(1n);

      // Check joiner still has no lobbies
      joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      expect(joinerLobbyIds.length).to.equal(0);

      // Joiner joins the lobby
      await joinerLobbies.write.joinLobby([1n]);

      // Check both players now have the lobby
      creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      expect(creatorLobbyIds.length).to.equal(1);
      expect(joinerLobbyIds.length).to.equal(1);
      expect(creatorLobbyIds[0]).to.equal(1n);
      expect(joinerLobbyIds[0]).to.equal(1n);
    });

    it("should track open lobbies correctly", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );

      // Initially no open lobbies
      let openLobbyIds = await creatorLobbies.read.getOpenLobbies();
      expect(openLobbyIds.length).to.equal(0);

      // Creator creates a lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);

      // Check lobby is open
      openLobbyIds = await creatorLobbies.read.getOpenLobbies();
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(1n);

      // Joiner joins the lobby
      await joinerLobbies.write.joinLobby([1n]);

      // Check lobby is no longer open
      openLobbyIds = await creatorLobbies.read.getOpenLobbies();
      expect(openLobbyIds.length).to.equal(0);

      // Create another lobby
      await otherLobbies.write.createLobby([2000n, 300n, true, 0n, 100n]);

      // Check new lobby is open
      openLobbyIds = await creatorLobbies.read.getOpenLobbies();
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(2n);
    });

    it("should handle creator leaving lobby with joiner", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Creator leaves lobby
      await creatorLobbies.write.leaveLobby([1n]);

      // Check joiner becomes creator and lobby is open again
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.basic.creator.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);

      // Check tracking sets
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(0);
      expect(joinerLobbyIds.length).to.equal(1);
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(1n);
    });

    it("should handle creator leaving lobby alone", async function () {
      const { creatorLobbies, creator } = await loadFixture(
        deployLobbiesFixture
      );

      // Create lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);

      // Creator leaves lobby
      await creatorLobbies.write.leaveLobby([1n]);

      // Check lobby is cleaned up
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(0);
      expect(openLobbyIds.length).to.equal(0);
    });

    it("should handle joiner leaving lobby", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Joiner leaves lobby
      await joinerLobbies.write.leaveLobby([1n]);

      // Check lobby is open again
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);

      // Check tracking sets
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(1);
      expect(joinerLobbyIds.length).to.equal(0);
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(1n);
    });

    it("should handle joiner timeout", async function () {
      const { creatorLobbies, joinerLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Wait for timeout and timeout joiner
      await hre.network.provider.send("evm_increaseTime", [400]); // 400 seconds later
      await hre.network.provider.send("evm_mine");
      await creatorLobbies.write.timeoutJoiner([1n]);

      // Check lobby is open again
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);

      // Check tracking sets
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(1);
      expect(joinerLobbyIds.length).to.equal(0);
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(1n);
    });

    it("should handle quit with penalty", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships for both players
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Fulfill random requests and construct ships
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleet for joiner
      await joinerLobbies.write.createFleet([
        1n,
        [6n],
        generateStartingPositions([6n], false),
      ]);

      // Wait for timeout and quit with penalty
      await hre.network.provider.send("evm_increaseTime", [400]); // 400 seconds later
      await hre.network.provider.send("evm_mine");
      await joinerLobbies.write.quitWithPenalty([1n]);

      // Check lobby is open again
      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.players.joiner).to.equal(zeroAddress);
      expect(lobby.state.status).to.equal(LobbyStatus.Open);

      // Check tracking sets
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(0);
      expect(joinerLobbyIds.length).to.equal(0);
      expect(openLobbyIds.length).to.equal(1);
      expect(openLobbyIds[0]).to.equal(1n);
    });

    it("should clean up when game starts", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        creator,
        joiner,
        ships,
        randomManager,
      } = await loadFixture(deployLobbiesFixture);

      // Purchase and construct ships
      await ships.write.purchaseWithFlow(
        [creator.account.address, 0n, joiner.account.address],
        { value: parseEther("4.99") }
      );
      await ships.write.purchaseWithFlow(
        [joiner.account.address, 0n, creator.account.address],
        { value: parseEther("4.99") }
      );

      // Fulfill random requests and construct ships
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      await ships.write.constructAllMyShips({ account: creator.account });
      await ships.write.constructAllMyShips({ account: joiner.account });

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create fleets to start game
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

      // Check tracking sets are cleaned up
      const creatorLobbyIds = await creatorLobbies.read.getPlayerLobbies([
        creator.account.address,
      ]);
      const joinerLobbyIds = await joinerLobbies.read.getPlayerLobbies([
        joiner.account.address,
      ]);
      const openLobbyIds = await creatorLobbies.read.getOpenLobbies();

      expect(creatorLobbyIds.length).to.equal(0);
      expect(joinerLobbyIds.length).to.equal(0);
      expect(openLobbyIds.length).to.equal(0);
    });

    it("should provide correct lobby counts", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies, creator, joiner } =
        await loadFixture(deployLobbiesFixture);

      // Initially no lobbies
      expect(
        await creatorLobbies.read.getPlayerLobbyCount([creator.account.address])
      ).to.equal(0n);
      expect(await creatorLobbies.read.getOpenLobbyCount()).to.equal(0n);

      // Create first lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);

      expect(
        await creatorLobbies.read.getPlayerLobbyCount([creator.account.address])
      ).to.equal(1n);
      expect(await creatorLobbies.read.getOpenLobbyCount()).to.equal(1n);

      // Join lobby
      await joinerLobbies.write.joinLobby([1n]);

      expect(
        await creatorLobbies.read.getPlayerLobbyCount([creator.account.address])
      ).to.equal(1n);
      expect(
        await joinerLobbies.read.getPlayerLobbyCount([joiner.account.address])
      ).to.equal(1n);
      expect(await creatorLobbies.read.getOpenLobbyCount()).to.equal(0n);

      // Create second lobby
      await otherLobbies.write.createLobby([2000n, 300n, true, 0n, 100n]);

      expect(await creatorLobbies.read.getOpenLobbyCount()).to.equal(1n);
    });

    it("should check lobby membership correctly", async function () {
      const {
        creatorLobbies,
        joinerLobbies,
        otherLobbies,
        creator,
        joiner,
        other,
      } = await loadFixture(deployLobbiesFixture);

      // Create and join lobby
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Check membership
      expect(
        await creatorLobbies.read.isPlayerInLobby([creator.account.address, 1n])
      ).to.be.true;
      expect(
        await joinerLobbies.read.isPlayerInLobby([joiner.account.address, 1n])
      ).to.be.true;
      expect(
        await otherLobbies.read.isPlayerInLobby([other.account.address, 1n])
      ).to.be.false;

      // Check lobby openness
      expect(await creatorLobbies.read.isLobbyOpen([1n])).to.be.false;

      // Create another lobby
      await otherLobbies.write.createLobby([2000n, 300n, true, 0n, 100n]);

      expect(await creatorLobbies.read.isLobbyOpen([2n])).to.be.true;
    });

    it("should get lobbies from IDs correctly", async function () {
      const { creatorLobbies, joinerLobbies, otherLobbies } = await loadFixture(
        deployLobbiesFixture
      );

      // Create multiple lobbies
      await creatorLobbies.write.createLobby([1000n, 300n, true, 0n, 100n]);
      await otherLobbies.write.createLobby([2000n, 300n, true, 0n, 100n]);
      await joinerLobbies.write.joinLobby([1n]);

      // Get lobbies by IDs
      const lobbies = await creatorLobbies.read.getLobbiesFromIds([[1n, 2n]]);

      expect(lobbies.length).to.equal(2);
      expect(lobbies[0].basic.id).to.equal(1n);
      expect(lobbies[0].basic.costLimit).to.equal(1000n);
      expect(lobbies[1].basic.id).to.equal(2n);
      expect(lobbies[1].basic.costLimit).to.equal(2000n);
    });
  });
});
