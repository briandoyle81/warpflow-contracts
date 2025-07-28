// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";
import "./Game.sol";
import "./IFleets.sol";

contract Lobbies is Ownable, ReentrancyGuard {
    Ships public ships;
    Game public game;
    IFleets public fleets;

    uint public lobbyCount;
    uint public freeGamesPerAddress = 1;
    uint public additionalLobbyFee = 1 ether;
    bool public paused;

    mapping(uint => Lobby) public lobbies;
    mapping(address => PlayerLobbyState) public playerStates;

    event LobbyCreated(
        uint indexed lobbyId,
        address indexed creator,
        uint costLimit,
        uint turnTime,
        bool creatorGoesFirst
    );
    event PlayerJoinedLobby(uint indexed lobbyId, address indexed joiner);
    event GameStarted(uint indexed lobbyId);
    event AdditionalLobbyFeePaid(address indexed player, uint amount);
    event LobbyReset(uint indexed lobbyId, address indexed newCreator);
    event LobbyAbandoned(uint indexed lobbyId, address indexed player);
    event LobbyTerminated(uint indexed lobbyId);

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

    function setFleetsAddress(address _fleetsAddress) public onlyOwner {
        fleets = IFleets(_fleetsAddress);
    }

    function isLobbyOpenForJoining(uint _id) public view returns (bool) {
        Lobby storage l = lobbies[_id];
        return l.status == LobbyStatus.Open && l.joiner == address(0);
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
                address newCreator = lobby.joiner;
                lobby.creator = newCreator;
                lobby.joiner = address(0);
                lobby.status = LobbyStatus.Open;

                // Update joiner's state
                PlayerLobbyState storage joinerState = playerStates[newCreator];
                joinerState.hasActiveLobby = true;
                joinerState.activeLobbyId = _lobbyId;

                emit LobbyReset(_lobbyId, newCreator);
            } else {
                emit LobbyAbandoned(_lobbyId, msg.sender);
            }
        } else {
            // If player is joiner, just remove them
            lobby.joiner = address(0);
            lobby.status = LobbyStatus.Open;
            emit LobbyAbandoned(_lobbyId, msg.sender);
        }

        // Clear player's state and decrement active lobbies count
        state.hasActiveLobby = false;
        state.activeLobbyId = 0;
        if (state.activeLobbiesCount > 0) {
            state.activeLobbiesCount--;
        }
    }

    function createLobby(
        uint _costLimit,
        uint _turnTime,
        bool _creatorGoesFirst
    ) public payable nonReentrant {
        if (paused) revert LobbyCreationPaused();
        if (_turnTime < MIN_TIMEOUT || _turnTime > MAX_TURN_TIME)
            revert InvalidTurnTime();

        // Check if player is in timeout
        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        // Check if player needs to pay for additional lobbies
        if (state.activeLobbiesCount >= freeGamesPerAddress) {
            if (msg.value < additionalLobbyFee) revert InsufficientFee();
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
        state.activeLobbiesCount++;

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

        state.hasActiveLobby = true;
        state.activeLobbyId = _lobbyId;
        state.activeLobbiesCount++;

        emit PlayerJoinedLobby(_lobbyId, msg.sender);
    }

    function timeoutJoiner(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.creator) revert NotLobbyCreator();
        if (lobby.status != LobbyStatus.FleetSelection) revert LobbyNotOpen();
        if (lobby.joiner == address(0)) revert LobbyNotFound();
        if (lobby.joinerFleetId != 0) revert FleetAlreadyCreated();

        // Check if timeout has been reached
        if (block.timestamp < lobby.joinedAt + lobby.turnTime)
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
        lobby.creatorFleetId = 0;
        lobby.joinerFleetId = 0;

        emit LobbyReset(_lobbyId, lobby.creator);
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

        // Create fleet through Fleets contract
        uint fleetId = fleets.createFleet(
            _lobbyId,
            msg.sender,
            _shipIds,
            lobby.costLimit
        );

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

        // Check if both players have created fleets
        if (lobby.creatorFleetId != 0 && lobby.joinerFleetId != 0) {
            lobby.status = LobbyStatus.InGame;
            lobby.gameStartedAt = block.timestamp;
            emit GameStarted(_lobbyId);

            // Decrement active lobbies count for both players
            PlayerLobbyState storage creatorState = playerStates[lobby.creator];
            PlayerLobbyState storage joinerState = playerStates[lobby.joiner];
            if (creatorState.activeLobbiesCount > 0) {
                creatorState.activeLobbiesCount--;
            }
            if (joinerState.activeLobbiesCount > 0) {
                joinerState.activeLobbiesCount--;
            }

            // Reset active lobby state for both players
            creatorState.hasActiveLobby = false;
            creatorState.activeLobbyId = 0;
            joinerState.hasActiveLobby = false;
            joinerState.activeLobbyId = 0;

            // Start the game
            try
                game.startGame(
                    _lobbyId,
                    lobby.creator,
                    lobby.joiner,
                    lobby.creatorFleetId,
                    lobby.joinerFleetId,
                    lobby.creatorGoesFirst
                )
            {
                // Game started successfully
            } catch {
                // Reset lobby state if game start fails
                lobby.status = LobbyStatus.FleetSelection;
                lobby.gameStartedAt = 0;

                // Restore player states
                creatorState.hasActiveLobby = true;
                creatorState.activeLobbyId = _lobbyId;
                creatorState.activeLobbiesCount++;
                joinerState.hasActiveLobby = true;
                joinerState.activeLobbyId = _lobbyId;
                joinerState.activeLobbiesCount++;

                revert("GameStartFailed");
            }
        }
    }

    function quitWithPenalty(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.joiner) revert NotLobbyJoiner();
        if (lobby.status != LobbyStatus.FleetSelection) revert LobbyNotOpen();
        if (lobby.joinerFleetId == 0) revert NotInLobby();
        if (lobby.creatorFleetId != 0) revert FleetAlreadyCreated();

        // Check if creator's timeout has been reached
        if (block.timestamp < lobby.joinerFleetSetAt + lobby.turnTime)
            revert CreatorTimeoutNotReached();

        // Clear joiner's fleet through Fleets contract
        fleets.clearFleet(lobby.joinerFleetId);

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
        lobby.creatorFleetId = 0;
        lobby.joinerFleetId = 0;

        emit LobbyTerminated(_lobbyId);
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

    function getPlayerState(
        address _player
    ) public view returns (PlayerLobbyState memory) {
        return playerStates[_player];
    }

    function getPlayerTimeoutEnd(address _player) public view returns (uint) {
        PlayerLobbyState storage state = playerStates[_player];
        if (state.kickCount == 0) return 0;
        return state.lastKickTime + (state.kickCount * KICK_PENALTY_PER_HOUR);
    }
}
