// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../ITutorialGameResults.sol";

interface ITutorialClaimTarget {
    function completeTutorialLossPath() external;
}

contract MockTutorialReentrantGameResults is ITutorialGameResults {
    address public target;

    function setTarget(address _target) external {
        target = _target;
    }

    function addWin(address) external override {
        ITutorialClaimTarget(target).completeTutorialLossPath();
    }

    function addLoss(address) external override {}
}
