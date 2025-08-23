// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Types.sol";

interface IGameResults {
    function recordGameResult(
        uint _gameId,
        address _winner,
        address _loser
    ) external;

    // function getPlayerStats(
    //     address _player
    // ) external view returns (PlayerStats memory);

    // function getGameResult(
    //     uint _gameId
    // ) external view returns (GameResult memory);

    // function isGameResultRecorded(uint _gameId) external view returns (bool);

    // function getPlayerTotalGames(address _player) external view returns (uint);

    // function getPlayerWinRate(address _player) external view returns (uint);

    // function totalGamesTracked() external view returns (uint);
}
