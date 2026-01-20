// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Types.sol";
import "./Ships.sol";
import "./Game.sol";
import "./IFleets.sol";
import "./IMaps.sol";

contract Lobbies is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    Ships public ships;
    Game public game;
    IFleets public fleets;
    IMaps public maps;
    IERC20 public universalCredits;

    uint public lobbyCount;
    uint public freeGamesPerAddress = 1;
    uint public additionalLobbyFee = 1 ether;
    uint public maxFleetCostLimit = 2000;
    bool public paused;

    mapping(uint => Lobby) public lobbies;
    mapping(address => PlayerLobbyState) public playerStates;

    // New mappings for lobby tracking
    mapping(address => EnumerableSet.UintSet) private playerLobbies;
    EnumerableSet.UintSet private openLobbyIds;

    event LobbyCreated(
        uint indexed lobbyId,
        address indexed creator,
        uint costLimit,
        uint turnTime,
        bool creatorGoesFirst,
        uint selectedMapId,
        uint maxScore
    );
    event PlayerJoinedLobby(uint indexed lobbyId, address indexed joiner);
    event GameStarted(uint indexed lobbyId);
    event LobbyReset(uint indexed lobbyId, address indexed newCreator);
    event LobbyAbandoned(uint indexed lobbyId, address indexed player);
    event LobbyTerminated(uint indexed lobbyId);
    event FleetCreated(
        uint indexed lobbyId,
        address indexed player,
        uint fleetId
    );
    event MaxFleetCostLimitUpdated(uint newLimit);
    event GameReserved(uint indexed lobbyId, address indexed reservedJoiner);
    event GameAccepted(uint indexed lobbyId, address indexed joiner);
    event GameRejected(uint indexed lobbyId, address indexed joiner);

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
    error InvalidMapId();
    error MaxFleetCostExceeded();
    error NotReservedJoiner();
    error LobbyNotReserved();
    error InsufficientUTC();
    error UTCTransferFailed();

    uint public constant MIN_TURN_TIME = 60; // 1 minute in seconds
    uint public constant MAX_TURN_TIME = 86400; // 24 hours in seconds
    uint public constant MIN_TIMEOUT = 300; // 5 minutes in seconds
    uint public constant KICK_PENALTY_PER_HOUR = 3600; // 1 hour in seconds

    constructor(address _ships) Ownable(msg.sender) {
        ships = Ships(_ships);
    }

    function setUniversalCreditsAddress(address _universalCredits) public onlyOwner {
        universalCredits = IERC20(_universalCredits);
    }

    function setGameAddress(address _gameAddress) public onlyOwner {
        game = Game(_gameAddress);
    }

    function setFleetsAddress(address _fleetsAddress) public onlyOwner {
        fleets = IFleets(_fleetsAddress);
    }

    function setMapsAddress(address _mapsAddress) public onlyOwner {
        maps = IMaps(_mapsAddress);
    }

    function isLobbyOpenForJoining(uint _id) public view returns (bool) {
        Lobby storage l = lobbies[_id];
        return
            l.state.status == LobbyStatus.Open &&
            l.players.joiner == address(0);
    }

    // Helper functions for set management
    function _addPlayerToLobby(address _player, uint _lobbyId) internal {
        playerLobbies[_player].add(_lobbyId);
    }

    function _removePlayerFromLobby(address _player, uint _lobbyId) internal {
        playerLobbies[_player].remove(_lobbyId);
    }

    function _addLobbyToOpenSet(uint _lobbyId) internal {
        openLobbyIds.add(_lobbyId);
    }

    function _removeLobbyFromOpenSet(uint _lobbyId) internal {
        openLobbyIds.remove(_lobbyId);
    }

    function _cleanupLobbyFromAllSets(uint _lobbyId) internal {
        Lobby storage lobby = lobbies[_lobbyId];

        // Remove from both players' sets
        if (lobby.basic.creator != address(0)) {
            _removePlayerFromLobby(lobby.basic.creator, _lobbyId);
        }
        if (lobby.players.joiner != address(0)) {
            _removePlayerFromLobby(lobby.players.joiner, _lobbyId);
        }

        // Remove from open set
        _removeLobbyFromOpenSet(_lobbyId);
    }

    function leaveLobby(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (
            msg.sender != lobby.basic.creator &&
            msg.sender != lobby.players.joiner
        ) revert NotInLobby();
        if (lobby.state.status == LobbyStatus.InGame)
            revert CannotLeaveStartedGame();

        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.activeLobbyId != _lobbyId) revert NotInLobby();

        // If player is creator, delete the lobby
        if (msg.sender == lobby.basic.creator) {
            // Clear creator's fleet if they have one
            if (lobby.players.creatorFleetId != 0) {
                fleets.clearFleet(lobby.players.creatorFleetId);
                lobby.players.creatorFleetId = 0;
            }

            // If joiner exists, they become the new creator
            if (lobby.players.joiner != address(0)) {
                address newCreator = lobby.players.joiner;
                lobby.basic.creator = newCreator;
                lobby.players.joiner = address(0);
                lobby.state.status = LobbyStatus.Open;

                // Update joiner's state
                PlayerLobbyState storage joinerState = playerStates[newCreator];
                joinerState.hasActiveLobby = true;
                joinerState.activeLobbyId = _lobbyId;

                // Update tracking sets: remove old creator, joiner becomes creator
                _removePlayerFromLobby(msg.sender, _lobbyId);
                // Joiner stays in the set, just becomes creator
                _addLobbyToOpenSet(_lobbyId); // Lobby is open again

                emit LobbyReset(_lobbyId, newCreator);
            } else {
                // Lobby is completely abandoned, clean up all sets
                _cleanupLobbyFromAllSets(_lobbyId);
                emit LobbyAbandoned(_lobbyId, msg.sender);
            }
        } else {
            // If player is joiner, just remove them
            // Clear joiner's fleet if they have one
            if (lobby.players.joinerFleetId != 0) {
                fleets.clearFleet(lobby.players.joinerFleetId);
                lobby.players.joinerFleetId = 0;
            }

            lobby.players.joiner = address(0);
            lobby.state.status = LobbyStatus.Open;

            // Remove joiner from tracking and add lobby back to open set
            _removePlayerFromLobby(msg.sender, _lobbyId);
            _addLobbyToOpenSet(_lobbyId);

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
        bool _creatorGoesFirst,
        uint _selectedMapId,
        uint _maxScore,
        address _reservedJoiner
    ) public payable nonReentrant {
        if (paused) revert LobbyCreationPaused();
        if (_turnTime < MIN_TIMEOUT || _turnTime > MAX_TURN_TIME)
            revert InvalidTurnTime();
        if (_costLimit > maxFleetCostLimit) revert MaxFleetCostExceeded();
        if (_reservedJoiner == msg.sender) revert PlayerAlreadyInLobby();

        // Validate mapId: 0 means no preset map (valid), otherwise must exist
        if (_selectedMapId > 0) {
            if (address(maps) == address(0)) revert InvalidMapId();
            if (!maps.mapExists(_selectedMapId)) revert InvalidMapId();
        }

        // Check if player is in timeout
        PlayerLobbyState storage state = playerStates[msg.sender];
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        // If reserving for a specific player, charge 1 UTC
        if (_reservedJoiner != address(0)) {
            if (address(universalCredits) == address(0)) revert UTCTransferFailed();
            uint reservationFee = 1 ether; // 1 UTC
            uint balance = universalCredits.balanceOf(msg.sender);
            if (balance < reservationFee) revert InsufficientUTC();
            require(
                universalCredits.transferFrom(msg.sender, address(this), reservationFee),
                "UTC transfer failed"
            );
        } else {
            // Check if player needs to pay for additional lobbies (FLOW payment)
            if (state.activeLobbiesCount >= freeGamesPerAddress) {
                if (msg.value < additionalLobbyFee) revert InsufficientFee();
            }
        }

        lobbyCount++;
        Lobby storage newLobby = lobbies[lobbyCount];
        newLobby.basic.id = lobbyCount;
        newLobby.basic.creator = msg.sender;
        newLobby.basic.costLimit = _costLimit;
        newLobby.state.status = LobbyStatus.Open;
        newLobby.basic.createdAt = block.timestamp;
        newLobby.gameConfig.creatorGoesFirst = _creatorGoesFirst;
        newLobby.gameConfig.turnTime = _turnTime;
        newLobby.gameConfig.selectedMapId = _selectedMapId;
        newLobby.gameConfig.maxScore = _maxScore;

        // Set reserved joiner if provided
        if (_reservedJoiner != address(0)) {
            newLobby.players.reservedJoiner = _reservedJoiner;
            emit GameReserved(lobbyCount, _reservedJoiner);
        }

        state.hasActiveLobby = true;
        state.activeLobbyId = lobbyCount;
        state.activeLobbiesCount++;

        // Add to tracking sets
        _addPlayerToLobby(msg.sender, lobbyCount);
        _addLobbyToOpenSet(lobbyCount);

        emit LobbyCreated(
            lobbyCount,
            msg.sender,
            _costLimit,
            _turnTime,
            _creatorGoesFirst,
            _selectedMapId,
            _maxScore
        );
    }

    function joinLobby(uint _lobbyId) public payable nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (lobby.state.status != LobbyStatus.Open) revert LobbyNotOpen();
        if (lobby.basic.creator == msg.sender) revert PlayerAlreadyInLobby();
        if (lobby.players.joiner != address(0)) revert LobbyFull();

        // Check if lobby is reserved for a specific player
        if (lobby.players.reservedJoiner != address(0)) {
            if (msg.sender != lobby.players.reservedJoiner) {
                revert NotReservedJoiner();
            }
        }

        PlayerLobbyState storage state = playerStates[msg.sender];

        // Check if player is in timeout
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        // Check if player needs to pay for additional lobbies (only for non-reserved lobbies)
        if (lobby.players.reservedJoiner == address(0)) {
            if (state.activeLobbiesCount >= freeGamesPerAddress) {
                if (msg.value < additionalLobbyFee) revert InsufficientFee();
            }
        }

        lobby.players.joiner = msg.sender;
        lobby.state.status = LobbyStatus.FleetSelection;
        lobby.players.joinedAt = block.timestamp;

        // Update player state - allow multiple active lobbies
        if (!state.hasActiveLobby) {
            state.hasActiveLobby = true;
            state.activeLobbyId = _lobbyId;
        }
        state.activeLobbiesCount++;

        // Add joiner to lobby tracking and remove from open set
        _addPlayerToLobby(msg.sender, _lobbyId);
        _removeLobbyFromOpenSet(_lobbyId);

        emit PlayerJoinedLobby(_lobbyId, msg.sender);
    }

    function acceptGame(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (lobby.players.reservedJoiner == address(0)) revert LobbyNotReserved();
        if (msg.sender != lobby.players.reservedJoiner) revert NotReservedJoiner();
        if (lobby.state.status != LobbyStatus.Open) revert LobbyNotOpen();
        if (lobby.players.joiner != address(0)) revert LobbyFull();

        PlayerLobbyState storage state = playerStates[msg.sender];

        // Check if player is in timeout
        if (state.kickCount > 0) {
            uint timeoutEnd = state.lastKickTime +
                (state.kickCount * KICK_PENALTY_PER_HOUR);
            if (block.timestamp < timeoutEnd) revert PlayerInTimeout();
        }

        lobby.players.joiner = msg.sender;
        lobby.state.status = LobbyStatus.FleetSelection;
        lobby.players.joinedAt = block.timestamp;
        // Clear reserved joiner since they've accepted
        lobby.players.reservedJoiner = address(0);

        // Update player state - allow multiple active lobbies
        if (!state.hasActiveLobby) {
            state.hasActiveLobby = true;
            state.activeLobbyId = _lobbyId;
        }
        state.activeLobbiesCount++;

        // Add joiner to lobby tracking and remove from open set
        _addPlayerToLobby(msg.sender, _lobbyId);
        _removeLobbyFromOpenSet(_lobbyId);

        emit GameAccepted(_lobbyId, msg.sender);
        emit PlayerJoinedLobby(_lobbyId, msg.sender);
    }

    function rejectGame(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (lobby.players.reservedJoiner == address(0)) revert LobbyNotReserved();
        if (msg.sender != lobby.players.reservedJoiner) revert NotReservedJoiner();
        if (lobby.state.status != LobbyStatus.Open) revert LobbyNotOpen();
        if (lobby.players.joiner != address(0)) revert LobbyFull();

        // Clear reserved joiner, making lobby open to anyone
        lobby.players.reservedJoiner = address(0);

        emit GameRejected(_lobbyId, msg.sender);
    }

    function timeoutJoiner(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.basic.creator) revert NotLobbyCreator();
        if (lobby.state.status != LobbyStatus.FleetSelection)
            revert LobbyNotOpen();
        if (lobby.players.joiner == address(0)) revert LobbyNotFound();
        if (lobby.players.joinerFleetId != 0) revert FleetAlreadyCreated();

        // Check if timeout has been reached
        if (
            block.timestamp < lobby.players.joinedAt + lobby.gameConfig.turnTime
        ) revert TimeoutNotReached();

        // Update joiner's kick state
        PlayerLobbyState storage joinerState = playerStates[
            lobby.players.joiner
        ];
        joinerState.kickCount++;
        joinerState.lastKickTime = block.timestamp;
        joinerState.hasActiveLobby = false;
        joinerState.activeLobbyId = 0;

        // Remove joiner from tracking and add lobby back to open set
        _removePlayerFromLobby(lobby.players.joiner, _lobbyId);
        _addLobbyToOpenSet(_lobbyId);

        // Reset lobby state
        lobby.players.joiner = address(0);
        lobby.state.status = LobbyStatus.Open;
        lobby.players.creatorFleetId = 0;
        lobby.players.joinerFleetId = 0;

        emit LobbyReset(_lobbyId, lobby.basic.creator);
    }

    function createFleet(
        uint _lobbyId,
        uint[] calldata _shipIds,
        Position[] calldata _startingPositions
    ) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (lobby.state.status != LobbyStatus.FleetSelection)
            revert LobbyNotOpen();
        if (
            msg.sender != lobby.basic.creator &&
            msg.sender != lobby.players.joiner
        ) revert NotInLobby();

        // Check if player already has a fleet in this lobby
        if (
            msg.sender == lobby.basic.creator &&
            lobby.players.creatorFleetId != 0
        ) revert FleetAlreadyCreated();
        if (
            msg.sender == lobby.players.joiner &&
            lobby.players.joinerFleetId != 0
        ) revert FleetAlreadyCreated();

        // Create fleet through Fleets contract
        bool isCreator = (msg.sender == lobby.basic.creator);
        uint fleetId = fleets.createFleet(
            _lobbyId,
            msg.sender,
            _shipIds,
            _startingPositions,
            lobby.basic.costLimit,
            isCreator
        );

        // Assign fleet to the correct player and determine who goes first
        if (msg.sender == lobby.basic.creator) {
            lobby.players.creatorFleetId = fleetId;
            // If creator is setting their fleet first, they go first
            if (lobby.players.joinerFleetId == 0) {
                lobby.gameConfig.creatorGoesFirst = true;
            }
        } else {
            lobby.players.joinerFleetId = fleetId;
            // If joiner is setting their fleet first, creator doesn't go first
            if (lobby.players.creatorFleetId == 0) {
                lobby.gameConfig.creatorGoesFirst = false;
            }
            // Record when joiner set their fleet
            lobby.players.joinerFleetSetAt = block.timestamp;
        }

        emit FleetCreated(_lobbyId, msg.sender, fleetId);

        // Check if both players have created fleets
        if (
            lobby.players.creatorFleetId != 0 &&
            lobby.players.joinerFleetId != 0
        ) {
            lobby.state.status = LobbyStatus.InGame;
            lobby.state.gameStartedAt = block.timestamp;
            emit GameStarted(_lobbyId);

            // Remove lobby from both players' tracking sets
            _removePlayerFromLobby(lobby.basic.creator, _lobbyId);
            _removePlayerFromLobby(lobby.players.joiner, _lobbyId);

            // Remove from open lobbies set
            _removeLobbyFromOpenSet(_lobbyId);

            // Decrement active lobbies count for both players
            PlayerLobbyState storage creatorState = playerStates[
                lobby.basic.creator
            ];
            PlayerLobbyState storage joinerState = playerStates[
                lobby.players.joiner
            ];
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

            // Remove from tracking sets when game starts
            _cleanupLobbyFromAllSets(_lobbyId);

            // Start the game
            game.startGame(
                _lobbyId,
                lobby.basic.creator,
                lobby.players.joiner,
                lobby.players.creatorFleetId,
                lobby.players.joinerFleetId,
                lobby.gameConfig.creatorGoesFirst,
                lobby.gameConfig.turnTime,
                lobby.gameConfig.selectedMapId,
                lobby.gameConfig.maxScore
            );
        }
    }

    function quitWithPenalty(uint _lobbyId) public nonReentrant {
        Lobby storage lobby = lobbies[_lobbyId];
        if (lobby.basic.id == 0) revert LobbyNotFound();
        if (msg.sender != lobby.players.joiner) revert NotLobbyJoiner();
        if (lobby.state.status != LobbyStatus.FleetSelection)
            revert LobbyNotOpen();
        if (lobby.players.joinerFleetId == 0) revert NotInLobby();
        if (lobby.players.creatorFleetId != 0) revert FleetAlreadyCreated();

        // Check if creator's timeout has been reached
        if (
            block.timestamp <
            lobby.players.joinerFleetSetAt + lobby.gameConfig.turnTime
        ) revert CreatorTimeoutNotReached();

        // Clear joiner's fleet through Fleets contract
        fleets.clearFleet(lobby.players.joinerFleetId);

        // Apply penalty to creator
        PlayerLobbyState storage creatorState = playerStates[
            lobby.basic.creator
        ];
        creatorState.kickCount++;
        creatorState.lastKickTime = block.timestamp;
        creatorState.hasActiveLobby = false;
        creatorState.activeLobbyId = 0;

        // Clear joiner's state
        PlayerLobbyState storage joinerState = playerStates[
            lobby.players.joiner
        ];
        joinerState.hasActiveLobby = false;
        joinerState.activeLobbyId = 0;

        // Remove both players from tracking and add lobby back to open set
        _removePlayerFromLobby(lobby.basic.creator, _lobbyId);
        _removePlayerFromLobby(lobby.players.joiner, _lobbyId);
        _addLobbyToOpenSet(_lobbyId);

        // Reset lobby state
        lobby.players.joiner = address(0);
        lobby.state.status = LobbyStatus.Open;
        lobby.players.creatorFleetId = 0;
        lobby.players.joinerFleetId = 0;

        emit LobbyTerminated(_lobbyId);
    }

    // Owner function to create a lobby with both creator and joiner already set
    // Bypasses paused state, timeout checks, and fee requirements
    // Who goes first is determined by who creates their fleet first (not a lobby setting)
    function createLobbyForAddresses(
        address _creator,
        address _joiner,
        uint _costLimit,
        uint _turnTime,
        uint _selectedMapId,
        uint _maxScore
    ) public onlyOwner {
        if (_turnTime < MIN_TIMEOUT || _turnTime > MAX_TURN_TIME)
            revert InvalidTurnTime();
        if (_creator == _joiner) revert PlayerAlreadyInLobby();
        if (_costLimit > maxFleetCostLimit) revert MaxFleetCostExceeded();

        // Validate mapId: 0 means no preset map (valid), otherwise must exist
        if (_selectedMapId > 0) {
            if (address(maps) == address(0)) revert InvalidMapId();
            if (!maps.mapExists(_selectedMapId)) revert InvalidMapId();
        }

        lobbyCount++;
        Lobby storage newLobby = lobbies[lobbyCount];
        newLobby.basic.id = lobbyCount;
        newLobby.basic.creator = _creator;
        newLobby.basic.costLimit = _costLimit;
        newLobby.state.status = LobbyStatus.FleetSelection; // Both players set, ready for fleet selection
        newLobby.basic.createdAt = block.timestamp;
        newLobby.gameConfig.turnTime = _turnTime;
        newLobby.gameConfig.selectedMapId = _selectedMapId;
        newLobby.gameConfig.maxScore = _maxScore;
        // creatorGoesFirst will be set when fleets are created based on who creates first

        // Set joiner immediately
        newLobby.players.joiner = _joiner;
        newLobby.players.joinedAt = block.timestamp;

        // Update creator's state
        PlayerLobbyState storage creatorState = playerStates[_creator];
        creatorState.hasActiveLobby = true;
        creatorState.activeLobbyId = lobbyCount;
        creatorState.activeLobbiesCount++;

        // Update joiner's state
        PlayerLobbyState storage joinerState = playerStates[_joiner];
        joinerState.hasActiveLobby = true;
        joinerState.activeLobbyId = lobbyCount;
        joinerState.activeLobbiesCount++;

        // Add both players to tracking sets (not open for joining since both players are set)
        _addPlayerToLobby(_creator, lobbyCount);
        _addPlayerToLobby(_joiner, lobbyCount);
        // Don't add to open set since lobby is already full

        emit LobbyCreated(
            lobbyCount,
            _creator,
            _costLimit,
            _turnTime,
            false, // creatorGoesFirst - will be determined by fleet creation order
            _selectedMapId,
            _maxScore
        );
        emit PlayerJoinedLobby(lobbyCount, _joiner);
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

    function setMaxFleetCostLimit(uint _maxFleetCostLimit) public onlyOwner {
        maxFleetCostLimit = _maxFleetCostLimit;
        emit MaxFleetCostLimitUpdated(_maxFleetCostLimit);
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

    // New view functions for lobby tracking
    function getPlayerLobbies(
        address _player
    ) public view returns (uint[] memory) {
        return playerLobbies[_player].values();
    }

    function getOpenLobbies() public view returns (uint[] memory) {
        return openLobbyIds.values();
    }

    function getLobbiesFromIds(
        uint[] calldata _lobbyIds
    ) public view returns (Lobby[] memory) {
        Lobby[] memory result = new Lobby[](_lobbyIds.length);
        for (uint i = 0; i < _lobbyIds.length; i++) {
            result[i] = lobbies[_lobbyIds[i]];
        }
        return result;
    }

    function getPlayerLobbyCount(address _player) public view returns (uint) {
        return playerLobbies[_player].length();
    }

    function getOpenLobbyCount() public view returns (uint) {
        return openLobbyIds.length();
    }

    function isPlayerInLobby(
        address _player,
        uint _lobbyId
    ) public view returns (bool) {
        return playerLobbies[_player].contains(_lobbyId);
    }

    function isLobbyOpen(uint _lobbyId) public view returns (bool) {
        return openLobbyIds.contains(_lobbyId);
    }

    // This function will have dupes that must be
    // filtered on the client sided
    function getAllLobbiesForPlayerWithDupes(
        address _player
    ) public view returns (Lobby[] memory) {
        EnumerableSet.UintSet storage playerLobbyIds = playerLobbies[_player];
        EnumerableSet.UintSet storage openLobbies = openLobbyIds;

        Lobby[] memory result = new Lobby[](
            playerLobbyIds.length() + openLobbies.length()
        );
        for (uint i = 0; i < playerLobbyIds.length(); i++) {
            result[i] = lobbies[playerLobbyIds.at(i)];
        }
        for (uint i = 0; i < openLobbies.length(); i++) {
            result[playerLobbyIds.length() + i] = lobbies[openLobbies.at(i)];
        }
        return result;
    }
}
