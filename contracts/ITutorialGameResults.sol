// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface ITutorialGameResults {
    function addWin(address player) external;

    function addLoss(address player) external;
}
