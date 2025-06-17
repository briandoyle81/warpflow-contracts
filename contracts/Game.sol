// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Types.sol";
import "./Ships.sol";

contract Game is Ownable, ReentrancyGuard {
    Ships public ships;
    address public lobbiesAddress;

    mapping(uint => GameData) public games;
    uint public gameCount;

    event GameStarted(
        uint indexed gameId,
        uint indexed lobbyId,
        address creator,
        address joiner
    );

    error NotLobbiesContract();
    error GameNotFound();
    error NotInGame();

    constructor(address _ships) Ownable(msg.sender) {
        ships = Ships(_ships);
    }

    function setLobbiesAddress(address _lobbiesAddress) public onlyOwner {
        lobbiesAddress = _lobbiesAddress;
    }

    function startGame(
        uint _lobbyId,
        address _creator,
        address _joiner,
        uint _creatorFleetId,
        uint _joinerFleetId,
        bool _creatorGoesFirst
    ) external nonReentrant {
        if (msg.sender != lobbiesAddress) revert NotLobbiesContract();

        gameCount++;
        GameData storage game = games[gameCount];
        game.gameId = gameCount;
        game.lobbyId = _lobbyId;
        game.creator = _creator;
        game.joiner = _joiner;
        game.creatorFleetId = _creatorFleetId;
        game.joinerFleetId = _joinerFleetId;
        game.creatorGoesFirst = _creatorGoesFirst;
        game.startedAt = block.timestamp;
        game.currentTurn = _creatorGoesFirst ? _creator : _joiner;

        emit GameStarted(gameCount, _lobbyId, _creator, _joiner);
    }

    // View functions
    function getGame(uint _gameId) public view returns (GameData memory) {
        if (games[_gameId].gameId == 0) revert GameNotFound();
        return games[_gameId];
    }
}
