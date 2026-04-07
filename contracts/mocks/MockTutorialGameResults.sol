// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../ITutorialGameResults.sol";

contract MockTutorialGameResults is ITutorialGameResults {
    mapping(address => uint) public wins;
    mapping(address => uint) public losses;

    function addWin(address player) external override {
        wins[player]++;
    }

    function addLoss(address player) external override {
        losses[player]++;
    }
}
