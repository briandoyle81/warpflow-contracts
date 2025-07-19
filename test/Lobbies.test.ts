import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther, zeroAddress } from "viem";
import { LobbyStatus, PlayerLobbyState, ShipTuple, tupleToShip } from "./types";
import DeployModule from "../ignition/modules/DeployAndConfig";

describe("Lobbies", function () {
  async function deployLobbiesFixture() {
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
      ]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });

      expect(receipt.status).to.equal("success");

      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.id).to.equal(1n);
      expect(lobby.creator.toLowerCase()).to.equal(
        creator.account.address.toLowerCase()
      );
      expect(lobby.joiner).to.equal(zeroAddress);
      expect(lobby.costLimit).to.equal(costLimit);
      expect(lobby.status).to.equal(LobbyStatus.Open);
      expect(lobby.turnTime).to.equal(turnTime);
      expect(lobby.creatorGoesFirst).to.equal(creatorGoesFirst);
      expect(lobby.creatorFleetId).to.equal(0n);
      expect(lobby.joinerFleetId).to.equal(0n);

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
      ]);

      // Second lobby should require fee
      await expect(
        creatorLobbies.write.createLobby([
          costLimit,
          turnTime,
          creatorGoesFirst,
        ])
      ).to.be.rejectedWith("InsufficientFee");

      // Should work with correct fee
      await expect(
        creatorLobbies.write.createLobby(
          [costLimit, turnTime, creatorGoesFirst],
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
      } = await loadFixture(deployLobbiesFixture);
      const costLimit = 1000n;
      const turnTime = 300n;
      const creatorGoesFirst = true;

      // Create and join a lobby
      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Check initial states
      let creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      let joinerState = (await joinerLobbies.read.getPlayerState([
        joiner.account.address,
      ])) as unknown as PlayerLobbyState;
      expect(creatorState.activeLobbiesCount).to.equal(1n);
      expect(joinerState.activeLobbiesCount).to.equal(1n);

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

      // Create fleets for both players
      await creatorLobbies.write.createFleet([1n, [1n]]);
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Check states after game start
      creatorState = (await creatorLobbies.read.getPlayerState([
        creator.account.address,
      ])) as unknown as PlayerLobbyState;
      joinerState = (await joinerLobbies.read.getPlayerState([
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
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Timeout the joiner
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await creatorLobbies.write.timeoutJoiner([1n]);

      // Create new lobby
      await creatorLobbies.write.createLobby(
        [costLimit, turnTime, creatorGoesFirst],
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
      ]);

      const tx = await joinerLobbies.write.joinLobby([1n]);
      const receipt = await publicClient.getTransactionReceipt({ hash: tx });
      expect(receipt.status).to.equal("success");

      const lobby = await creatorLobbies.read.getLobby([1n]);
      expect(lobby.joiner.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(lobby.status).to.equal(LobbyStatus.FleetSelection);
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
      ]);

      // First player joins
      await joinerLobbies.write.joinLobby([1n]);

      // Create second lobby
      await otherLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
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
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Timeout the joiner
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await creatorLobbies.write.timeoutJoiner([1n]);

      // Create new lobby
      await creatorLobbies.write.createLobby(
        [costLimit, turnTime, creatorGoesFirst],
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
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      // Create second lobby
      await otherLobbies.write.createLobby([
        costLimit,
        turnTime,
        creatorGoesFirst,
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
      expect(lobby.creator.toLowerCase()).to.equal(
        joiner.account.address.toLowerCase()
      );
      expect(lobby.joiner).to.equal(zeroAddress);
      expect(lobby.status).to.equal(LobbyStatus.Open);
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
      expect(lobby.joiner).to.equal(zeroAddress);
      expect(lobby.status).to.equal(LobbyStatus.Open);
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
      expect(lobby.joiner).to.equal(zeroAddress);
      expect(lobby.status).to.equal(LobbyStatus.Open);
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
      await joinerLobbies.write.createFleet([1n, [6n]]);

      // Verify lobby is in FleetSelection state before quitting
      const lobbyBefore = await creatorLobbies.read.getLobby([1n]);
      expect(lobbyBefore.status).to.equal(LobbyStatus.FleetSelection);
      expect(lobbyBefore.joinerFleetId).to.not.equal(0n);
      expect(lobbyBefore.creatorFleetId).to.equal(0n);

      // Wait for creator's timeout
      await hre.network.provider.send("evm_increaseTime", [301]); // Wait for timeout
      await hre.network.provider.send("evm_mine");

      // Get joiner's fleet before quitting
      const joinerFleetBefore = await creatorFleets.read.getFleet([
        lobbyBefore.joinerFleetId,
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
      expect(lobby.joiner).to.equal(zeroAddress);
      expect(lobby.status).to.equal(LobbyStatus.Open);
      expect(lobby.joinerFleetId).to.equal(0n);
      expect(lobby.creatorFleetId).to.equal(0n);

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
      await creatorLobbies.write.createLobby([1000n, 300n, true]);
      await joinerLobbies.write.joinLobby([1n]);

      // Try to create a fleet directly through the Fleets contract (should fail)
      await expect(
        fleets.write.createFleet([1n, creator.account.address, [1n], 1000n])
      ).to.be.rejectedWith("NotLobbiesContract");

      // Create a fleet through the Lobbies contract (should succeed)
      await expect(creatorLobbies.write.createFleet([1n, [1n]])).to.not.be
        .rejected;
    });
  });

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
      const attributes = await game.read.getShipAttributes([1n, 1n, true]);

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
      const creatorAttributes = await game.read.getShipAttributes([
        1n,
        1n,
        true,
      ]);
      const joinerAttributes = await game.read.getShipAttributes([
        1n,
        6n,
        false,
      ]);

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
      const attributes = await game.read.getShipAttributes([1n, 1n, true]);

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
      const creatorAttributes = await game.read.getShipAttributes([
        1n,
        1n,
        true,
      ]);
      const joinerAttributes = await game.read.getShipAttributes([
        1n,
        6n,
        false,
      ]);

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
        true,
      ]);

      // Get attributes for all ships in joiner's fleet
      const joinerShipIds = [6n, 7n, 8n];
      const joinerAttributes = await game.read.getPlayerShipAttributes([
        1n,
        joinerShipIds,
        false,
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
      const gameData = await game.read.getGame([1n, [1n], [6n]]);

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
      expect(gameData.creatorShipAttributes.length).to.equal(1);
      expect(gameData.joinerShipAttributes.length).to.equal(1);

      // Verify creator ship attributes
      const creatorAttrs = gameData.creatorShipAttributes[0];
      expect(creatorAttrs.version).to.equal(1);
      expect(creatorAttrs.hullPoints).to.be.greaterThan(0);
      expect(creatorAttrs.movement).to.be.greaterThanOrEqual(0);
      expect(creatorAttrs.range).to.be.greaterThan(0);
      expect(creatorAttrs.gunDamage).to.be.greaterThan(0);
      expect(creatorAttrs.statusEffects.length).to.equal(0);

      // Verify joiner ship attributes
      const joinerAttrs = gameData.joinerShipAttributes[0];
      expect(joinerAttrs.version).to.equal(1);
      expect(joinerAttrs.hullPoints).to.be.greaterThan(0);
      expect(joinerAttrs.movement).to.be.greaterThanOrEqual(0);
      expect(joinerAttrs.range).to.be.greaterThan(0);
      expect(joinerAttrs.gunDamage).to.be.greaterThan(0);
      expect(joinerAttrs.statusEffects.length).to.equal(0);
    });

    it("should revert when trying to get attributes for non-existent game", async function () {
      const { game } = await loadFixture(deployLobbiesFixture);

      await expect(
        game.read.getShipAttributes([999n, 1n, true])
      ).to.be.rejectedWith("GameNotFound");
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
      await expect(
        game.read.getShipAttributes([1n, 999n, true])
      ).to.be.rejectedWith("ShipNotFound");
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
        expect(creatorShips[i].position.row).to.equal(i); // Top to bottom (rows 0, 1, 2)
        expect(creatorShips[i].position.row).to.be.lessThan(50); // Within grid height
      }

      // Verify joiner ships are on the right side (column 99) and placed from bottom to top
      for (let i = 0; i < joinerShips.length; i++) {
        expect(joinerShips[i].position.col).to.equal(99); // Right side
        expect(joinerShips[i].position.row).to.equal(49 - i); // Bottom to top (rows 49, 48, 47)
        expect(joinerShips[i].position.row).to.be.lessThan(50); // Within grid height
      }

      // Verify specific ship positions using grid queries
      // Creator ships should be at (row 0, col 0), (row 1, col 0), (row 2, col 0)
      expect((await game.read.getShipAtPosition([1n, 0, 0])) as any).to.equal(
        1n
      );
      expect((await game.read.getShipAtPosition([1n, 1, 0])) as any).to.equal(
        2n
      );
      expect((await game.read.getShipAtPosition([1n, 2, 0])) as any).to.equal(
        3n
      );

      // Joiner ships should be at (row 49, col 99), (row 48, col 99), (row 47, col 99)
      expect((await game.read.getShipAtPosition([1n, 49, 99])) as any).to.equal(
        6n
      );
      expect((await game.read.getShipAtPosition([1n, 48, 99])) as any).to.equal(
        7n
      );
      expect((await game.read.getShipAtPosition([1n, 47, 99])) as any).to.equal(
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

      // Display the grid on the console
      console.log("Grid:");
      for (let row = 0; row < 50; row++) {
        let rowStr = "";
        for (let col = 0; col < 100; col++) {
          rowStr += await game.read.getShipAtPosition([1n, row, col]);
        }
        console.log(rowStr);
      }
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
});
