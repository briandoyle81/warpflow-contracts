// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ITutorialShips.sol";
import "./ITutorialGameResults.sol";
import "./Types.sol";

contract TutorialClaim is ReentrancyGuard {
    error TutorialAlreadyCompleted();
    error ZeroAddress();

    mapping(address => bool) public tutorialCompleted;

    ITutorialShips public immutable ships;
    ITutorialGameResults public immutable gameResults;

    event TutorialCompleted(
        address indexed player,
        bool winPath,
        uint8 shipsCreated
    );

    constructor(address _ships, address _gameResults) {
        if (_ships == address(0) || _gameResults == address(0))
            revert ZeroAddress();
        ships = ITutorialShips(_ships);
        gameResults = ITutorialGameResults(_gameResults);
    }

    function completeTutorialWinPath() external nonReentrant {
        _markTutorialCompleted(msg.sender);

        _createAndCustomizeShip(msg.sender, _buildVigilantTemplate(msg.sender));
        _createAndCustomizeShip(msg.sender, _buildSentinelTemplate(msg.sender));

        gameResults.addWin(msg.sender);

        emit TutorialCompleted(msg.sender, true, 2);
    }

    function completeTutorialLossPath() external nonReentrant {
        _markTutorialCompleted(msg.sender);

        _createAndCustomizeShip(msg.sender, _buildResoluteTemplate(msg.sender));
        _createAndCustomizeShip(msg.sender, _buildVigilantTemplate(msg.sender));
        _createAndCustomizeShip(msg.sender, _buildSentinelTemplate(msg.sender));

        gameResults.addLoss(msg.sender);

        emit TutorialCompleted(msg.sender, false, 3);
    }

    function _markTutorialCompleted(address player) internal {
        if (tutorialCompleted[player]) revert TutorialAlreadyCompleted();
        tutorialCompleted[player] = true;
    }

    function _createAndCustomizeShip(address player, Ship memory template) internal {
        ships.createSpecificShip(player, template);
    }

    function _buildResoluteTemplate(
        address owner
    ) internal pure returns (Ship memory s) {
        s.name = "Resolute";
        s.owner = owner;
        s.equipment = Equipment({
            mainWeapon: MainWeapon.PlasmaCannon,
            armor: Armor.Light,
            shields: Shields.Light,
            special: Special.EMP
        });
        s.traits = Traits({
            serialNumber: 0,
            colors: Colors({
                h1: 200,
                s1: 80,
                l1: 50,
                h2: 220,
                s2: 70,
                l2: 40,
                h3: 0,
                s3: 0,
                l3: 0
            }),
            variant: 1,
            // Tier indices 0–2 for costs/attributes (not raw stat totals)
            accuracy: 1,
            hull: 2,
            speed: 2
        });
    }

    function _buildVigilantTemplate(
        address owner
    ) internal pure returns (Ship memory s) {
        s.name = "Vigilant";
        s.owner = owner;
        s.equipment = Equipment({
            mainWeapon: MainWeapon.Railgun,
            armor: Armor.Medium,
            shields: Shields.Medium,
            special: Special.RepairDrones
        });
        s.traits = Traits({
            serialNumber: 0,
            colors: Colors({
                h1: 250,
                s1: 90,
                l1: 60,
                h2: 270,
                s2: 80,
                l2: 50,
                h3: 0,
                s3: 0,
                l3: 0
            }),
            variant: 2,
            accuracy: 2,
            hull: 2,
            speed: 2
        });
    }

    function _buildSentinelTemplate(
        address owner
    ) internal pure returns (Ship memory s) {
        s.name = "Sentinel";
        s.owner = owner;
        s.equipment = Equipment({
            mainWeapon: MainWeapon.Laser,
            armor: Armor.Light,
            shields: Shields.Light,
            special: Special.None
        });
        s.traits = Traits({
            serialNumber: 0,
            colors: Colors({
                h1: 150,
                s1: 70,
                l1: 55,
                h2: 170,
                s2: 60,
                l2: 45,
                h3: 0,
                s3: 0,
                l3: 0
            }),
            variant: 3,
            accuracy: 1,
            hull: 1,
            speed: 2
        });
    }
}
