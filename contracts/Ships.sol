// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// TODO: CRITICAL Confirm which reentrancy guard to use
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import "./Types.sol";
import "./IOnchainRandomShipNames.sol";
import "./IRenderer.sol";
import "./IRandomManager.sol";

contract Ships is ERC721, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => Ship) public ships;
    uint public shipCount;

    mapping(address => EnumerableSet.UintSet) private shipsOwned;
    mapping(address => uint) public onboardingStep;

    mapping(address => uint) public referralCount;

    uint[] public referralPercentages = [0, 10, 20, 35, 50];
    // Amount of Flow sold to reach each tier
    uint[] public referralStages = [
        100 ether,
        1000 ether,
        10000 ether,
        50000 ether,
        100000 ether
    ];

    error InvalidPayment();
    error InvalidReferral();
    error NotAuthorized(address);
    error NotYourShip(uint);
    error InvalidId();
    error ShipDestroyed();
    error ShipInGame();
    error ShipInLobby();
    error OldShipCost();
    error BadTeamCost();
    error MintPaused();
    error InvalidRenderer();
    error ShipConstructed(uint);

    address public gameAddress;
    address public lobbyAddress;

    uint public shipPrice = 1 ether; // 1 Flow
    uint public tenPackPrice = 8 ether; // 8 Flow

    Costs public costs;
    uint public costsVersion;

    bool public paused;

    IOnchainRandomShipNames public shipNames;
    IRenderer public renderer;
    IRandomManager public randomManager;

    uint64 randomSeed = 0;
    uint8 numberOfVariants = 4;

    // Only Owner TODO
    // Withdrawal
    // Set costs
    // Set prices
    // Set game address
    // Set lobby address
    // Set ship names
    // Set referral stages
    // Set referral percentages
    constructor(
        address _shipNames,
        address _renderer
    ) ERC721("Warpflow Ships", "SHIP") Ownable(msg.sender) {
        shipNames = IOnchainRandomShipNames(_shipNames);
        renderer = IRenderer(_renderer);

        costs.version = 1;
        costs.baseCost = [10, 20, 30, 40];

        costs.accuracy = [0, 10, 25];
        costs.brawling = [0, 10, 25];
        costs.hull = [0, 10, 25];
        costs.speed = [0, 10, 25];

        costs.mainWeapon = [25, 30, 40, 10];
        costs.pointDefense = [0, 20, 30, 30];
        costs.armor = [0, 5, 10, 15];
        costs.shields = [0, 10, 20, 30];
        costs.special = [0, 10, 20, 15];
    }

    /**
     * @dev PUBLIC
     */

    function mintShip(
        address _to,
        address _referral
    ) public payable nonReentrant {
        if (msg.value != shipPrice) {
            revert InvalidPayment();
        }

        if (_referral == address(0)) {
            revert InvalidReferral();
        }

        _mintShip(_to);
        _processReferral(_referral, shipPrice);
    }

    function mintTenPack(
        address _to,
        address _referral
    ) public payable nonReentrant {
        if (msg.value != tenPackPrice) {
            revert InvalidPayment();
        }

        if (_referral == address(0)) {
            revert InvalidReferral();
        }

        for (uint i = 0; i < 10; i++) {
            _mintShip(_to);
        }

        _processReferral(_referral, tenPackPrice);
    }

    function constructShips(uint[] memory _ids) public {
        for (uint i = 0; i < _ids.length; i++) {
            constructShip(_ids[i]);
        }
    }

    function constructShip(uint _id) public {
        Ship storage newShip = ships[_id];

        if (newShip.owner != msg.sender) {
            revert NotYourShip(_id);
        }

        if (newShip.constructed) {
            revert ShipConstructed(_id);
        }

        newShip.constructed = true;

        uint64 randomBase = randomManager.fulfillRandomRequest(
            newShip.traits.serialNumber
        );

        randomSeed++;
        newShip.name = shipNames.getRandomShipName(
            bytes32(
                uint256(keccak256(abi.encodePacked(randomSeed, randomBase)))
            )
        );

        newShip.traits.class = Class(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        // r g b 1 and 2 values are 0 to 255
        randomSeed++;
        newShip.traits.r1 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.g1 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.b1 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.r2 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.g2 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.b2 = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 256
        );

        randomSeed++;
        newShip.traits.accuracy = uint8(
            getTierOfTrait(
                uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 100
            )
        );

        randomSeed++;
        newShip.traits.brawling = uint8(
            getTierOfTrait(
                uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 100
            )
        );

        randomSeed++;
        newShip.traits.hull = uint8(
            getTierOfTrait(
                uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 100
            )
        );

        randomSeed++;
        newShip.traits.speed = uint8(
            getTierOfTrait(
                uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 100
            )
        );

        randomSeed++;
        newShip.traits.variant = uint8(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) %
                numberOfVariants
        );

        randomSeed++;
        newShip.equipment.mainWeapon = MainWeapon(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        randomSeed++;
        newShip.equipment.pointDefense = PointDefense(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        randomSeed++;
        newShip.equipment.armor = Armor(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        randomSeed++;
        newShip.equipment.shields = Shields(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        randomSeed++;
        newShip.equipment.special = Special(
            uint(keccak256(abi.encodePacked(randomSeed, randomBase))) % 4
        );

        // TODO: Should it be adjustable chance for shiny?
        uint shinyChance = uint(
            keccak256(abi.encodePacked(randomSeed, randomBase))
        ) % 100;
        if (shinyChance == 0) {
            newShip.shiny = true;
        }

        // Generated a weighted random number to determine the starting number of enemies destroyed
        // 75% chance that the number is between 1 and 5
        // 15% chance that the number is between 6 and 10
        // 5% chance that the number is between 11 and 50
        // 4% chance that the number is between 51 and 100
        // 1% chance that the number is between 101 and 150

        randomSeed++;
        uint shipsDestroyed = uint(
            keccak256(abi.encodePacked(randomSeed, randomBase))
        ) % 100;
        if (shipsDestroyed < 75) {
            newShip.shipsDestroyed = uint16(1 + (shipsDestroyed % 5));
        } else if (shipsDestroyed < 90) {
            newShip.shipsDestroyed = uint16(6 + (shipsDestroyed % 5));
        } else if (shipsDestroyed < 95) {
            newShip.shipsDestroyed = uint16(11 + (shipsDestroyed % 40));
        } else if (shipsDestroyed < 99) {
            newShip.shipsDestroyed = uint16(51 + (shipsDestroyed % 50));
        } else {
            newShip.shipsDestroyed = uint16(101 + (shipsDestroyed % 50));
        }

        newShip.costsVersion = costs.version;

        newShip.cost = setCostOfShip(_id);
    }

    function setCostOfShip(uint _id) public view returns (uint16) {
        Ship storage ship = ships[_id];

        uint16 unadjustedCost = uint16(
            costs.baseCost[uint8(ship.traits.class)] +
                costs.accuracy[uint8(ship.traits.accuracy)] +
                costs.brawling[uint8(ship.traits.brawling)] +
                costs.hull[uint8(ship.traits.hull)] +
                costs.speed[uint8(ship.traits.speed)] +
                costs.mainWeapon[uint8(ship.equipment.mainWeapon)] +
                costs.pointDefense[uint8(ship.equipment.pointDefense)] +
                costs.armor[uint8(ship.equipment.armor)] +
                costs.shields[uint8(ship.equipment.shields)] +
                costs.special[uint8(ship.equipment.special)]
        );

        // TODO: Cap for rank to cost
        // For now cost is reduced by  0% for rank 1, 10% for rank 2, 20% for rank 3, 30% for rank 4
        uint16 rank = getRank(ship.shipsDestroyed);
        uint16 rankCost = (unadjustedCost * rank) / 100;
        if (rankCost > (unadjustedCost * 30) / 100) {
            rankCost = (unadjustedCost * 30) / 100;
        }

        uint16 finalCost = unadjustedCost - rankCost;

        return finalCost;
    }

    /**
     * @dev INTERNAL
     */

    function _mintShip(address _to) internal {
        if (paused) {
            revert MintPaused();
        }

        shipCount++;
        Ship storage newShip = ships[shipCount];
        newShip.id = shipCount;
        newShip.owner = _to;

        newShip.traits.serialNumber = randomManager.requestRandomness();

        _safeMint(_to, shipCount);
    }

    function _processReferral(address _referrer, uint _amount) internal {
        referralCount[_referrer] += _amount;

        uint referralPercentage = 1; // For testing, maybe leave and see what happens

        for (uint i = referralStages.length; i > 0; i--) {
            if (referralCount[_referrer] >= referralStages[i - 1]) {
                referralPercentage = referralPercentages[i - 1];
                break;
            }
        }

        uint referralAmount = (_amount * referralPercentage) / 100;

        (bool success, ) = payable(_referrer).call{value: referralAmount}("");
        require(success, "Referral transfer failed");
    }

    /**
     * @dev OWNER
     */

    function setShipPrice(uint _price) public onlyOwner {
        shipPrice = _price;
    }

    function setTenPackPrice(uint _price) public onlyOwner {
        tenPackPrice = _price;
    }

    function setGameAddress(address _gameAddress) public onlyOwner {
        gameAddress = _gameAddress;
    }

    function setLobbyAddress(address _lobbyAddress) public onlyOwner {
        lobbyAddress = _lobbyAddress;
    }

    function setShipNames(address _shipNames) public onlyOwner {
        shipNames = IOnchainRandomShipNames(_shipNames);
    }

    function setRandomManager(address _randomManager) public onlyOwner {
        randomManager = IRandomManager(_randomManager);
    }

    function setReferralStages(uint[] memory _referralStages) public onlyOwner {
        referralStages = _referralStages;
    }

    function setReferralPercentages(
        uint[] memory _referralPercentages
    ) public onlyOwner {
        referralPercentages = _referralPercentages;
    }

    function setCosts(Costs memory _costs) public onlyOwner {
        costsVersion++;
        costs = _costs;
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

    function setNumberOfVariants(uint8 _numberOfVariants) public onlyOwner {
        numberOfVariants = _numberOfVariants;
    }

    /**
     * @dev PURE
     */

    // TODO: Do tiers need to be adjustable?
    function getTierOfTrait(uint _trait) public pure returns (uint8) {
        if (_trait < 50) {
            return 0;
        } else if (_trait < 80) {
            return 1;
        } else {
            return 2;
        }
    }

    function getRank(uint _shipsDestroyed) public pure returns (uint8) {
        // Rank is the number of digits in the number of ships destroyed
        return uint8(countDigits(_shipsDestroyed));
    }

    function countDigits(uint num) public pure returns (uint) {
        if (num == 0) return 1;

        uint digits = 0;
        while (num != 0) {
            digits++;
            num /= 10;
        }
        return digits;
    }
}
