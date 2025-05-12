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
}
