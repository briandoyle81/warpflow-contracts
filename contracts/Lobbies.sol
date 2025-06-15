// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";
import "./Game.sol";

contract Lobbies is Ownable, ReentrancyGuard {
    Ships public ships;
    Game public game;

    uint public lobbyCount;
    uint public fleetCount;
    uint public freeGamesPerAddress = 1;
    uint public additionalLobbyFee = 1 ether;
    bool public paused;

    mapping(uint => Lobby) public lobbies;
    mapping(uint => Fleet) public fleets;
    mapping(address => PlayerLobbyState) public playerStates;
    mapping(uint => bool) public isLobbyOpen;

    event LobbyCreated(
        uint indexed lobbyId,
        address indexed creator,
        uint costLimit,
        uint turnTime,
        bool creatorGoesFirst
    );
    event PlayerJoinedLobby(uint indexed lobbyId, address indexed joiner);
    event FleetCreated(
        uint indexed fleetId,
        uint indexed lobbyId,
        address indexed owner
    );
    event GameStarted(uint indexed lobbyId);
    event AdditionalLobbyFeePaid(address indexed player, uint amount);
    event LobbyClosed(uint indexed lobbyId);

    error LobbyNotFound();
    error LobbyFull();
    error LobbyNotOpen();
    error LobbyAlreadyStarted();
    error InvalidFleetCost();
    error ShipAlreadyInFleet();
    error ShipNotOwned();
    error ShipCostVersionMismatch();
    error PlayerAlreadyInLobby();
    error InsufficientFee();
    error LobbyCreationPaused();
    error NotInLobby();
    error FleetAlreadyCreated();
    error InvalidShipCount();
    error CannotLeaveStartedGame();
    error InvalidTurnTime();
    error TimeoutNotReached();
    error NotLobbyCreator();
    error PlayerInTimeout();
    error NotLobbyJoiner();
    error CreatorTimeoutNotReached();

    uint public constant MIN_TURN_TIME = 60; // 1 minute in seconds
    uint public constant MAX_TURN_TIME = 86400; // 24 hours in seconds
    uint public constant MIN_TIMEOUT = 300; // 5 minutes in seconds
    uint public constant KICK_PENALTY_PER_HOUR = 3600; // 1 hour in seconds

    constructor(address _ships) Ownable(msg.sender) {
        ships = Ships(_ships);
    }

    function setGameAddress(address _gameAddress) public onlyOwner {
        game = Game(_gameAddress);
    }

    function leaveLobby(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.creator && msg.sender != lobby.joiner)
            revert NotInLobby();
        if (lobby.status == LobbyStatus.InGame) revert CannotLeaveStartedGame();

        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.activeLobbyId != _lobbyId) revert NotInLobby();

        // If player is creator, delete the lobby
        if (msg.sender == lobby.creator) {
            // If joiner exists, they become the new creator
            if (lobby.joiner != address(0)) {
                lobby.creator = lobby.joiner;
                lobby.joiner = address(0);
                lobby.status = LobbyStatus.Open;
                isLobbyOpen[_lobbyId] = true;

                // Update joiner's state
                PlayerLobbyState storage joinerState = playerStates[
                    lobby.joiner
                ];
                joinerState.hasActiveLobby = true;
                joinerState.activeLobbyId = _lobbyId;
            } else {
                isLobbyOpen[_lobbyId] = false;
                emit LobbyClosed(_lobbyId);
            }
        } else {
            // If player is joiner, just remove them
            lobby.joiner = address(0);
            lobby.status = LobbyStatus.Open;
            isLobbyOpen[_lobbyId] = true;
        }

        // Clear player's state
        state.hasActiveLobby = false;
        state.activeLobbyId = 0;
    }

    function createLobby(
        uint _costLimit,
        uint _turnTime,
        bool _creatorGoesFirst
    ) public payable nonReentrant {
        if (paused) revert LobbyCreationPaused();
        if (_turnTime < MIN_TURN_TIME || _turnTime > MAX_TURN_TIME)
            revert InvalidTurnTime();

        // Check if player is in timeout
        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        if (state.hasActiveLobby) {
            if (msg.value < 1 ether) revert InsufficientFee();
        } else {
            state.freeGamesRemaining--;
        }

        lobbyCount++;
        Lobby storage newLobby = lobbies[lobbyCount];
        newLobby.id = lobbyCount;
        newLobby.creator = msg.sender;
        newLobby.costLimit = _costLimit;
        newLobby.status = LobbyStatus.Open;
        newLobby.createdAt = block.timestamp;
        newLobby.creatorGoesFirst = _creatorGoesFirst;
        newLobby.turnTime = _turnTime;

        state.hasActiveLobby = true;
        state.activeLobbyId = lobbyCount;
        isLobbyOpen[lobbyCount] = true;

        emit LobbyCreated(
            lobbyCount,
            msg.sender,
            _costLimit,
            _turnTime,
            _creatorGoesFirst
        );
    }

    function joinLobby(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (lobby.status != LobbyStatus.Open) revert LobbyNotOpen();
        if (lobby.creator == msg.sender) revert PlayerAlreadyInLobby();
        if (lobby.joiner != address(0)) revert LobbyFull();

        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.hasActiveLobby) revert PlayerAlreadyInLobby();

        // Check if player is in timeout
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        lobby.joiner = msg.sender;
        lobby.status = LobbyStatus.FleetSelection;
        lobby.joinedAt = block.timestamp;
        isLobbyOpen[_lobbyId] = false;

        state.hasActiveLobby = true;
        state.activeLobbyId = _lobbyId;

        emit PlayerJoinedLobby(_lobbyId, msg.sender);
    }

    function timeoutJoiner(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.creator) revert NotLobbyCreator();
        if (lobby.status != LobbyStatus.FleetSelection) revert LobbyNotOpen();
        if (lobby.joiner == address(0)) revert LobbyNotFound();
        if (lobby.joinerFleetId != 0) revert FleetAlreadyCreated();

        // Calculate timeout period
        uint timeoutPeriod = lobby.turnTime <= MIN_TIMEOUT
            ? MIN_TIMEOUT
            : lobby.turnTime;

        // Check if timeout has been reached
        if (block.timestamp < lobby.joinedAt + timeoutPeriod)
            revert TimeoutNotReached();

        // Update joiner's kick state
        PlayerLobbyState storage joinerState = playerStates[lobby.joiner];
        joinerState.kickCount++;
        joinerState.lastKickTime = block.timestamp;
        joinerState.hasActiveLobby = false;
        joinerState.activeLobbyId = 0;

        // Reset lobby state
        lobby.joiner = address(0);
        lobby.status = LobbyStatus.Open;
        isLobbyOpen[_lobbyId] = true;

        emit LobbyClosed(_lobbyId);
    }

    function createFleet(
        uint _lobbyId,
        uint[] calldata _shipIds
    ) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (lobby.status != LobbyStatus.FleetSelection) revert LobbyNotOpen();
        if (msg.sender != lobby.creator && msg.sender != lobby.joiner)
            revert NotInLobby();

        // Check if player already has a fleet in this lobby
        if (msg.sender == lobby.creator && lobby.creatorFleetId != 0)
            revert FleetAlreadyCreated();
        if (msg.sender == lobby.joiner && lobby.joinerFleetId != 0)
            revert FleetAlreadyCreated();

        uint totalCost = 0;
        fleetCount++;
        uint fleetId = fleetCount; // Fleet IDs start at 1

        Fleet storage newFleet = fleets[fleetId];
        newFleet.id = fleetId;
        newFleet.lobbyId = _lobbyId;
        newFleet.owner = msg.sender;
        newFleet.shipIds = _shipIds;

        // Validate ships and calculate total cost
        for (uint i = 0; i < _shipIds.length; i++) {
            uint shipId = _shipIds[i];
            Ship memory ship = ships.getShip(shipId);

            // Validate ship ownership
            if (ship.owner != msg.sender) revert ShipNotOwned();

            // Validate ship is not in another fleet
            if (ship.shipData.inFleet) revert ShipAlreadyInFleet();

            // Validate cost version
            if (ship.shipData.costsVersion != ships.getCurrentCostsVersion())
                revert ShipCostVersionMismatch();

            totalCost += ship.shipData.cost;
        }

        // Validate total cost
        if (totalCost > lobby.costLimit) revert InvalidFleetCost();

        newFleet.totalCost = totalCost;
        newFleet.isComplete = true;

        // Mark ships as in fleet
        for (uint i = 0; i < _shipIds.length; i++) {
            ships.setInFleet(_shipIds[i], true);
        }

        // Assign fleet to the correct player and determine who goes first
        if (msg.sender == lobby.creator) {
            lobby.creatorFleetId = fleetId;
            // If creator is setting their fleet first, they go first
            if (lobby.joinerFleetId == 0) {
                lobby.creatorGoesFirst = true;
            }
        } else {
            lobby.joinerFleetId = fleetId;
            // If joiner is setting their fleet first, creator doesn't go first
            if (lobby.creatorFleetId == 0) {
                lobby.creatorGoesFirst = false;
            }
            // Record when joiner set their fleet
            lobby.joinerFleetSetAt = block.timestamp;
        }

        emit FleetCreated(fleetId, _lobbyId, msg.sender);

        // Check if both players have created fleets
        if (lobby.creatorFleetId != 0 && lobby.joinerFleetId != 0) {
            lobby.status = LobbyStatus.InGame;
            lobby.gameStartedAt = block.timestamp;
            emit GameStarted(_lobbyId);

            // Start the game
            game.startGame(
                _lobbyId,
                lobby.creator,
                lobby.joiner,
                lobby.creatorFleetId,
                lobby.joinerFleetId,
                lobby.creatorGoesFirst
            );
        }
    }

    function quitWithPenalty(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.joiner) revert NotLobbyJoiner();
        if (lobby.status != LobbyStatus.FleetSelection) revert LobbyNotOpen();
        if (lobby.joinerFleetId == 0) revert NotInLobby();
        if (lobby.creatorFleetId != 0) revert FleetAlreadyCreated();

        // Calculate timeout period
        uint timeoutPeriod = lobby.turnTime <= MIN_TIMEOUT
            ? MIN_TIMEOUT
            : lobby.turnTime;

        // Check if creator's timeout has been reached
        if (block.timestamp < lobby.joinerFleetSetAt + timeoutPeriod)
            revert CreatorTimeoutNotReached();

        // Release joiner's ships from fleet
        Fleet storage joinerFleet = fleets[lobby.joinerFleetId];
        for (uint i = 0; i < joinerFleet.shipIds.length; i++) {
            ships.setInFleet(joinerFleet.shipIds[i], false);
        }

        // Apply penalty to creator
        PlayerLobbyState storage creatorState = playerStates[lobby.creator];
        creatorState.kickCount++;
        creatorState.lastKickTime = block.timestamp;
        creatorState.hasActiveLobby = false;
        creatorState.activeLobbyId = 0;

        // Clear joiner's state
        PlayerLobbyState storage joinerState = playerStates[lobby.joiner];
        joinerState.hasActiveLobby = false;
        joinerState.activeLobbyId = 0;

        // Reset lobby state
        lobby.joiner = address(0);
        lobby.status = LobbyStatus.Open;
        isLobbyOpen[_lobbyId] = true;

        emit LobbyClosed(_lobbyId);
    }

    // Owner functions
    function setFreeGamesPerAddress(uint _count) public onlyOwner {
        freeGamesPerAddress = _count;
    }

    function setAdditionalLobbyFee(uint _fee) public onlyOwner {
        additionalLobbyFee = _fee;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed");
    }

    // View functions
    function getLobby(uint _lobbyId) public view returns (Lobby memory) {
        return lobbies[_lobbyId];
    }

    function getFleet(uint _fleetId) public view returns (Fleet memory) {
        return fleets[_fleetId];
    }

    function getPlayerState(
        address _player
    ) public view returns (PlayerLobbyState memory) {
        return playerStates[_player];
    }

    function isLobbyOpenForJoining(uint _lobbyId) public view returns (bool) {
        return
            isLobbyOpen[_lobbyId] &&
            lobbies[_lobbyId].status == LobbyStatus.Open;
    }

    function getPlayerTimeoutEnd(address _player) public view returns (uint) {
        PlayerLobbyState storage state = playerStates[_player];
        if (state.kickCount == 0) return 0;
        return state.lastKickTime + (state.kickCount * KICK_PENALTY_PER_HOUR);
    }
}
