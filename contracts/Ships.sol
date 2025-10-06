// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// TODO: CRITICAL Confirm which reentrancy guard to use
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import "./Types.sol";
import "./IRenderer.sol";
import "./IRandomManager.sol";
import "./IGenerateNewShip.sol";
import "./IUniversalCredits.sol";

contract Ships is ERC721, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => Ship) public ships;
    uint public shipCount;

    mapping(address => EnumerableSet.UintSet) private shipsOwned;
    mapping(address => bool) public hasClaimedFreeShips;
    mapping(address => uint) public amountPurchased;

    mapping(address => uint) public onboardingStep;

    mapping(address => uint) public referralCount;

    // Static - Contract with the world
    uint8[] public referralPercentages = [0, 10, 20, 35, 50];
    // Amount of Ships sold to reach each tier
    uint32[] public referralStages = [
        100, // 100 ships sold
        1000, // 1000 ships sold
        10000, // 10000 ships sold
        50000, // 50000 ships sold
        100000 // 100000 ships sold
    ];

    error InvalidReferral();
    error NotAuthorized(address);
    error NotYourShip(uint);
    error InvalidId();
    error ShipDestroyed();
    error ShipInGame();
    error ShipInLobby();
    error OldShipCost();
    error MintPaused();
    error InvalidRenderer();
    error ShipConstructed(uint);
    error ShipInFleet(uint);
    error InsufficientPurchases(address);
    error InvalidPurchase(uint _tier, uint _amount);
    error ArrayLengthMismatch();
    error ShipAlreadyDestroyed(uint);

    struct ContractConfig {
        address gameAddress;
        address lobbyAddress;
        address fleetsAddress;
        IRenderMetadata metadataRenderer;
        IRandomManager randomManager;
        IGenerateNewShip shipGenerator;
    }

    ContractConfig public config;

    uint8[] public purchaseTiers;
    uint8[] public tierShips;
    uint[] public tierPrices;

    Costs public costs;
    uint public costsVersion;

    bool public paused;

    uint16 numberOfVariants = 1;

    event MetadataUpdate(uint256 _tokenId);

    // ERC-5192 Minimal Soulbound extension (no extra storage required)
    // See: https://eips.ethereum.org/EIPS/eip-5192
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    mapping(address => bool) public isAllowedToCreateShips;

    // TODO: Should variants have different weapons or props?

    IUniversalCredits public universalCredits;
    uint public recycleReward = 0.1 ether; // 0.1 UC tokens

    // Only Owner TODO
    // Withdrawal

    constructor(
        address _renderer
    ) ERC721("Warpflow Ships", "SHIP") Ownable(msg.sender) {
        config.metadataRenderer = IRenderMetadata(_renderer);

        costs.version = 1;
        costs.baseCost = 50;

        costs.accuracy = [0, 10, 25];
        costs.hull = [0, 10, 25];
        costs.speed = [0, 10, 25];

        costs.mainWeapon = [25, 30, 40, 40];
        costs.armor = [0, 5, 10, 15];
        costs.shields = [0, 10, 20, 30];
        costs.special = [0, 10, 20, 15];

        // Variant 0 has no modifiers, already exists as zeroes

        purchaseTiers = [1, 2, 3, 4, 5];
        tierShips = [5, 11, 28, 60, 125];
        //              0%, 10%, 15%, 20%, 25%
        tierPrices = [
            4.99 ether,
            9.99 ether,
            24.99 ether,
            49.99 ether,
            99.99 ether
        ];
    }

    /**
     * @dev PUBLIC
     */

    // For purchases with ERC20s such as Universal Credits
    // or anything else I think of

    function createShips(address _to, uint _amount) public {
        if (!isAllowedToCreateShips[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }

        for (uint i = 0; i < _amount; i++) {
            _mintShip(_to);
        }

        // TODO: CRITICAL -> Evaluate side effects of this

        amountPurchased[_to] += _amount;
    }

    function purchaseWithFlow(
        address _to,
        uint _tier,
        address _referral
    ) public payable nonReentrant {
        if (msg.value != tierPrices[_tier]) {
            revert InvalidPurchase(_tier, msg.value);
        }

        if (_referral == address(0)) {
            revert InvalidReferral();
        }

        uint totalShips = tierShips[_tier];

        for (uint i = 0; i < totalShips; i++) {
            _mintShip(_to);
        }

        _processReferral(_referral, totalShips, tierPrices[_tier]);

        amountPurchased[_to] += totalShips;
    }

    function constructShips(uint[] memory _ids) public {
        for (uint i = 0; i < _ids.length; i++) {
            constructShip(_ids[i]);
        }
    }

    function constructAllMyShips() public {
        uint[] memory ids = shipsOwned[msg.sender].values();
        for (uint i = 0; i < ids.length; i++) {
            if (!ships[ids[i]].shipData.constructed) {
                constructShip(ids[i]);
            }
        }
    }

    // Used for bonuses, special ships, events, etc.
    // TODO CRITICAL:
    // This allows players to predict which ships to overwrite
    // with special ships.
    // I don't think I care, but should I?
    function constructSpecificShip(uint _id, Ship memory _ship) public {
        emit MetadataUpdate(_id);

        Ship storage newShip = ships[_id];

        if (!isAllowedToCreateShips[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }

        if (newShip.shipData.constructed) {
            revert ShipConstructed(_id);
        }

        // TODO: I'm not sure what I'm saving/doing passing this
        // to the other contract, but it gives me the ability to
        // update it later.
        Ship memory generatedShip = config.shipGenerator.generateSpecificShip(
            _id,
            newShip.traits.serialNumber,
            _ship
        );

        newShip.name = generatedShip.name;
        newShip.traits = generatedShip.traits;
        newShip.equipment = generatedShip.equipment;
        newShip.shipData.shiny = generatedShip.shipData.shiny;
        newShip.shipData.shipsDestroyed = generatedShip.shipData.shipsDestroyed;
        newShip.shipData.costsVersion = costs.version;
        newShip.shipData.constructed = true;

        _setCostOfShip(_id);
    }

    function constructShip(uint _id) public {
        emit MetadataUpdate(_id);

        Ship storage newShip = ships[_id];

        if (newShip.owner != msg.sender) {
            revert NotYourShip(_id);
        }

        if (newShip.shipData.constructed) {
            revert ShipConstructed(_id);
        }

        uint64 randomBase = config.randomManager.fulfillRandomRequest(
            newShip.traits.serialNumber
        );

        Ship memory generatedShip = config.shipGenerator.generateShip(
            _id,
            newShip.traits.serialNumber,
            randomBase,
            numberOfVariants
        );

        // Copy generated ship data to storage
        newShip.name = generatedShip.name;
        newShip.traits = generatedShip.traits;
        newShip.equipment = generatedShip.equipment;
        newShip.shipData.shiny = generatedShip.shipData.shiny;
        newShip.shipData.shipsDestroyed = generatedShip.shipData.shipsDestroyed;
        newShip.shipData.costsVersion = costs.version;
        newShip.shipData.constructed = true;

        _setCostOfShip(_id);
    }

    function setCostOfShip(uint _id) public {
        if (msg.sender != owner() && msg.sender != config.gameAddress) {
            revert NotAuthorized(msg.sender);
        }

        _setCostOfShip(_id);
    }

    function _setCostOfShip(uint _id) internal {
        Ship storage ship = ships[_id];

        uint16 unadjustedCost = uint16(
            costs.baseCost +
                costs.accuracy[uint8(ship.traits.accuracy)] +
                costs.hull[uint8(ship.traits.hull)] +
                costs.speed[uint8(ship.traits.speed)] +
                costs.mainWeapon[uint8(ship.equipment.mainWeapon)] +
                costs.armor[uint8(ship.equipment.armor)] +
                costs.shields[uint8(ship.equipment.shields)] +
                costs.special[uint8(ship.equipment.special)]
        );

        // // TODO: Cap for rank to cost
        // // For now cost is reduced by  0% for rank 1, 10% for rank 2, 20% for rank 3, 30% for rank 4 and above
        // uint16 rank = getRank(ship.shipData.shipsDestroyed);
        // uint16 rankCost;
        // if (rank == 1) {
        //     rankCost = (unadjustedCost * 0) / 100;
        // } else if (rank == 2) {
        //     rankCost = (unadjustedCost * 10) / 100;
        // } else if (rank == 3) {
        //     rankCost = (unadjustedCost * 20) / 100;
        // } else if (rank >= 4) {
        //     rankCost = (unadjustedCost * 30) / 100;
        // }

        // uint16 finalCost = unadjustedCost - rankCost;

        ship.shipData.cost = unadjustedCost;
    }

    /**
     * @dev Lobby and GameFunctions
     */

    function setInFleet(uint _id, bool _inFleet) public {
        if (
            msg.sender != config.lobbyAddress &&
            msg.sender != config.gameAddress &&
            msg.sender != config.fleetsAddress
        ) {
            revert NotAuthorized(msg.sender);
        }

        ships[_id].shipData.inFleet = _inFleet;

        // ERC-5192: Lock when added to fleet; unlock when removed (purely via events)
        if (_inFleet) emit Locked(_id);
        else emit Unlocked(_id);
    }

    /**
     * @dev INTERNAL
     */

    // Override erc721 update
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        // Skip destroyed check for burning (when to is address(0))
        if (to != address(0)) {
            require(
                ships[tokenId].shipData.timestampDestroyed == 0,
                "Ship destroyed"
            );
        }

        // Always check if ship is in fleet
        if (ships[tokenId].shipData.inFleet) {
            revert ShipInFleet(tokenId);
        }

        address oldOwner = ships[tokenId].owner;

        // Skip transfer check for minting (when oldOwner is address(0))
        if (oldOwner != address(0)) {
            if (amountPurchased[oldOwner] < 10) {
                revert InsufficientPurchases(oldOwner);
            }
            if (to != address(0) && amountPurchased[to] < 10) {
                revert InsufficientPurchases(to);
            }
            // Handle ownership list
            shipsOwned[oldOwner].remove(tokenId);
        }

        // Only add to shipsOwned if not burning
        if (to != address(0)) {
            shipsOwned[to].add(tokenId);
            ships[tokenId].owner = to;
        }

        // ERC-5192: if burning (to == address(0)) emit Locked for final state
        if (to == address(0)) emit Locked(tokenId);

        return super._update(to, tokenId, auth);
    }

    function _mintShip(address _to) internal {
        if (paused) {
            revert MintPaused();
        }

        shipCount++;
        Ship storage newShip = ships[shipCount];
        newShip.id = shipCount;

        newShip.traits.serialNumber = config.randomManager.requestRandomness();

        _safeMint(_to, shipCount);

        // Set owner after minting to avoid check in _update
        newShip.owner = _to;

        // ERC-5192: Ships start unlocked (emit for indexers if desired)
        emit Unlocked(shipCount);
    }

    function _processReferral(
        address _referrer,
        uint _shipsSold,
        uint _salePrice
    ) internal {
        referralCount[_referrer] += _shipsSold;

        uint referralPercentage = 1; // For testing, maybe leave and see what happens

        for (uint i = referralStages.length; i > 0; i--) {
            if (referralCount[_referrer] >= referralStages[i - 1]) {
                referralPercentage = referralPercentages[i - 1];
                break;
            }
        }

        uint referralAmount = (_salePrice * referralPercentage) / 100;

        (bool success, ) = payable(_referrer).call{value: referralAmount}("");
        require(success, "Referral transfer failed");
    }

    /**
     * @dev OWNER
     */

    function setIsAllowedToCreateShips(
        address _address,
        bool _isAllowed
    ) public onlyOwner {
        isAllowedToCreateShips[_address] = _isAllowed;
    }

    function setTimestampDestroyed(uint _id, uint _destroyerId) public {
        if (msg.sender != owner() && msg.sender != config.gameAddress) {
            revert NotAuthorized(msg.sender);
        }
        if (ships[_id].shipData.timestampDestroyed != 0) {
            revert ShipAlreadyDestroyed(_id);
        }
        ships[_id].shipData.timestampDestroyed = block.timestamp;

        // ERC-5192: Lock when destroyed
        emit Locked(_id);

        ships[_destroyerId].shipData.shipsDestroyed++;

        // Pay the destroyer 1/4 of salvage value (base recycleReward)
        address destroyerOwner = ships[_destroyerId].owner;
        if (destroyerOwner != address(0)) {
            uint quarterSalvage = recycleReward / 4;
            if (quarterSalvage > 0) {
                universalCredits.mint(destroyerOwner, quarterSalvage);
            }
        }

        emit MetadataUpdate(_id);
    }

    function setPurchaseInfo(
        uint8[] memory _purchaseTiers,
        uint8[] memory _tierShips,
        uint[] memory _tierPrices
    ) public onlyOwner {
        if (
            _purchaseTiers.length != _tierShips.length ||
            _tierShips.length != _tierPrices.length
        ) {
            revert ArrayLengthMismatch();
        }
        purchaseTiers = _purchaseTiers;
        tierShips = _tierShips;
        tierPrices = _tierPrices;
    }

    function setConfig(
        address _gameAddress,
        address _lobbyAddress,
        address _fleetsAddress,
        address _shipGenerator,
        address _randomManager,
        address _metadataRenderer
    ) public onlyOwner {
        if (_gameAddress != address(0)) {
            config.gameAddress = _gameAddress;
        }
        if (_lobbyAddress != address(0)) {
            config.lobbyAddress = _lobbyAddress;
        }
        if (_fleetsAddress != address(0)) {
            config.fleetsAddress = _fleetsAddress;
        }
        if (_shipGenerator != address(0)) {
            config.shipGenerator = IGenerateNewShip(_shipGenerator);
        }
        if (_randomManager != address(0)) {
            config.randomManager = IRandomManager(_randomManager);
        }
        if (_metadataRenderer != address(0)) {
            config.metadataRenderer = IRenderMetadata(_metadataRenderer);
        }
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

    function setUniversalCredits(address _universalCredits) public onlyOwner {
        universalCredits = IUniversalCredits(_universalCredits);
    }

    function setRecycleReward(uint _newReward) public onlyOwner {
        recycleReward = _newReward;
    }

    function claimFreeShips() public {
        require(!hasClaimedFreeShips[msg.sender], "Already claimed free ships");

        // Grant 10 free ships
        for (uint i = 0; i < 10; i++) {
            _mintShip(msg.sender);
        }

        hasClaimedFreeShips[msg.sender] = true;
    }

    /**
     * @dev VIEW
     */

    function getCosts() public view returns (uint, Costs memory) {
        return (costsVersion, costs);
    }

    function getCurrentCostsVersion() public view returns (uint16) {
        return costs.version;
    }

    function getShip(uint _id) public view returns (Ship memory) {
        return ships[_id];
    }

    function isShipDestroyed(uint _id) public view returns (bool) {
        return ships[_id].shipData.timestampDestroyed != 0;
    }

    // ERC-5192: minimal interface view - derived from existing state
    function locked(uint256 tokenId) external view returns (bool) {
        Ship storage s = ships[tokenId];
        if (s.shipData.timestampDestroyed != 0) return true;
        return s.shipData.inFleet;
    }

    function getPurchaseInfo()
        public
        view
        returns (
            uint8[] memory _purchaseTiers,
            uint8[] memory _tierShips,
            uint[] memory _tierPrices
        )
    {
        return (purchaseTiers, tierShips, tierPrices);
    }

    function tokenURI(uint _id) public view override returns (string memory) {
        return config.metadataRenderer.tokenURI(ships[_id]);
    }

    function getShipIdsOwned(
        address _owner
    ) public view returns (uint[] memory) {
        return shipsOwned[_owner].values();
    }

    // // TODO CRITICAL: This almost certainly needs to be paginated
    // function getShipsOwned(address _owner) public view returns (Ship[] memory) {
    //     uint[] memory ids = getShipIdsOwned(_owner);
    //     Ship[] memory shipsFetched = new Ship[](ids.length);
    //     for (uint i = 0; i < ids.length; i++) {
    //         shipsFetched[i] = ships[ids[i]];
    //     }
    //     return shipsFetched;
    // }

    function getShipsByIds(
        uint[] memory _ids
    ) public view returns (Ship[] memory) {
        Ship[] memory shipsFetched = new Ship[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            shipsFetched[i] = ships[_ids[i]];
        }
        return shipsFetched;
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

    function shipBreaker(uint[] calldata _shipIds) public nonReentrant {
        uint totalReward = 0;

        for (uint i = 0; i < _shipIds.length; i++) {
            uint shipId = _shipIds[i];

            // Cache storage reference to avoid repeated SLOADs
            Ship storage s = ships[shipId];

            // Check if caller owns the ship
            // TODO: I'm 85% sure this is redundant.
            if (s.owner != msg.sender) {
                revert NotYourShip(shipId);
            }

            // Determine recycle reward based on destruction state PRIOR to this call
            bool wasDestroyed = s.shipData.timestampDestroyed != 0;
            uint rewardForThisShip = wasDestroyed
                ? (recycleReward / 2)
                : recycleReward;

            // Mark ship as destroyed and burn it
            s.shipData.timestampDestroyed = block.timestamp;
            emit Locked(shipId);
            _burn(shipId);

            // Add to total reward
            totalReward += rewardForThisShip;
        }

        // Mint reward tokens to the owner
        if (totalReward > 0) {
            universalCredits.mint(msg.sender, totalReward);
        }
    }
}
