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
import "./IShipAttributes.sol";

contract Ships is ERC721, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => Ship) public ships;
    uint public shipCount;

    mapping(address => EnumerableSet.UintSet) private shipsOwned;
    mapping(address => uint256) public lastClaimTimestamp;
    mapping(address => uint) public amountPurchased;

    // 4 weeks in seconds (28 days * 24 hours * 60 minutes * 60 seconds)
    uint256 public claimCooldownPeriod = 28 days;

    mapping(address => uint) public referralCount;

    // Hardcoded referral tiers (saves bytecode size)
    // Stages: 100, 1000, 10000, 50000, 100000 ships sold
    // Percentages: 0%, 10%, 20%, 35%, 50%

    error InvalidReferral();
    error NotAuthorized(address);
    error NotYourShip(uint);
    error ShipDestroyed();
    error MintPaused();
    error ShipConstructed(uint);
    error ShipInFleet(uint);
    error InsufficientPurchases(address);
    error InvalidPurchase(uint _tier, uint _amount);
    error ArrayLengthMismatch();
    error ShipAlreadyDestroyed(uint);
    error CannotRecycleFreeShip(uint);
    error InvalidVariant(uint16);
    error ReferralTransferFailed();
    error WithdrawalFailed();
    error ClaimCooldownNotPassed();

    struct ContractConfig {
        address gameAddress;
        address lobbyAddress;
        address fleetsAddress;
        IRenderMetadata metadataRenderer;
        IRandomManager randomManager;
        IGenerateNewShip shipGenerator;
        IShipAttributes shipAttributes;
    }

    ContractConfig public config;

    uint8[] public purchaseTiers;
    uint8[] public tierShips;
    uint[] public tierPrices;

    bool public paused;

    uint16 public maxVariant = 1;

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

    function createShips(address _to, uint _amount, uint16 _variant) public {
        if (!isAllowedToCreateShips[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }

        for (uint i = 0; i < _amount; i++) {
            _mintShip(_to, _variant);
        }

        // TODO: CRITICAL -> Evaluate side effects of this

        amountPurchased[_to] += _amount;
    }

    function purchaseWithFlow(
        address _to,
        uint _tier,
        address _referral,
        uint16 _variant
    ) public payable nonReentrant {
        if (msg.value != tierPrices[_tier]) {
            revert InvalidPurchase(_tier, msg.value);
        }

        if (_referral == address(0)) {
            revert InvalidReferral();
        }

        uint totalShips = tierShips[_tier];

        for (uint i = 0; i < totalShips; i++) {
            _mintShip(_to, _variant);
        }

        _processReferral(_referral, totalShips, tierPrices[_tier]);

        amountPurchased[_to] += totalShips;
    }

    function constructShips(uint[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            constructShip(_ids[i]);
        }
    }

    function constructAllMyShips() external {
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
    function customizeShip(uint _id, Ship calldata _ship) external {
        emit MetadataUpdate(_id);

        Ship storage ship = ships[_id];

        if (!isAllowedToCreateShips[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }

        if (ship.shipData.timestampDestroyed != 0) {
            revert ShipDestroyed();
        }

        if (ship.shipData.inFleet) {
            revert ShipInFleet(_id);
        }

        // Calculate modifications by comparing old and new
        uint16 amountModified = _calculateModifications(ship, _ship);

        // Update ship properties (preserve immutable traits like serialNumber)
        ship.name = _ship.name;
        ship.traits.accuracy = _ship.traits.accuracy;
        ship.traits.hull = _ship.traits.hull;
        ship.traits.speed = _ship.traits.speed;
        ship.traits.variant = _ship.traits.variant;
        ship.traits.colors = _ship.traits.colors;
        ship.equipment = _ship.equipment;

        // Update shiny status if provided (counts as 3 modifications)
        if (ship.shipData.shiny != _ship.shipData.shiny) {
            ship.shipData.shiny = _ship.shipData.shiny;
        }

        // Update modified amount (add to existing if constructed, set if not)
        if (ship.shipData.constructed) {
            ship.shipData.modified += amountModified;
        } else {
            ship.shipData.modified = amountModified;
            ship.shipData.constructed = true;
            ship.shipData.costsVersion = config
                .shipAttributes
                .getCurrentCostsVersion();
        }

        _setCostOfShip(_id);
    }

    function _calculateModifications(
        Ship storage _currentShip,
        Ship memory _newShip
    ) internal view returns (uint16) {
        uint16 modifications = 0;

        // Count equipment changes (add 1 for each changed property)
        if (
            _currentShip.equipment.mainWeapon != _newShip.equipment.mainWeapon
        ) {
            modifications++;
        }
        if (_currentShip.equipment.armor != _newShip.equipment.armor) {
            modifications++;
        }
        if (_currentShip.equipment.shields != _newShip.equipment.shields) {
            modifications++;
        }
        if (_currentShip.equipment.special != _newShip.equipment.special) {
            modifications++;
        }

        // Calculate trait changes (total absolute difference)
        uint8 accuracyDiff = _newShip.traits.accuracy >
            _currentShip.traits.accuracy
            ? _newShip.traits.accuracy - _currentShip.traits.accuracy
            : _currentShip.traits.accuracy - _newShip.traits.accuracy;
        uint8 hullDiff = _newShip.traits.hull > _currentShip.traits.hull
            ? _newShip.traits.hull - _currentShip.traits.hull
            : _currentShip.traits.hull - _newShip.traits.hull;
        uint8 speedDiff = _newShip.traits.speed > _currentShip.traits.speed
            ? _newShip.traits.speed - _currentShip.traits.speed
            : _currentShip.traits.speed - _newShip.traits.speed;

        modifications += accuracyDiff + hullDiff + speedDiff;

        // Count shiny status change as 3 modifications
        if (_currentShip.shipData.shiny != _newShip.shipData.shiny) {
            modifications += 3;
        }

        return modifications;
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
            newShip.traits.variant
        );

        // Copy generated ship data to storage
        // We already have variant, it was set at purchase
        // as was the serial number
        newShip.name = generatedShip.name;
        newShip.traits = generatedShip.traits;
        newShip.equipment = generatedShip.equipment;
        newShip.shipData.shiny = generatedShip.shipData.shiny;
        newShip.shipData.shipsDestroyed = generatedShip.shipData.shipsDestroyed;
        newShip.shipData.costsVersion = config
            .shipAttributes
            .getCurrentCostsVersion();
        newShip.shipData.constructed = true;
        // modified defaults to 0 (false) for regular construction

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
        ship.shipData.cost = config.shipAttributes.calculateShipCost(ship);
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
            if (ships[tokenId].shipData.timestampDestroyed != 0) {
                revert ShipDestroyed();
            }
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

    function _mintShip(address _to, uint16 _variant) internal {
        if (paused) {
            revert MintPaused();
        }

        if (_variant > maxVariant || _variant == 0) {
            revert InvalidVariant(_variant);
        }

        shipCount++;
        Ship storage newShip = ships[shipCount];
        newShip.id = shipCount;

        newShip.traits.serialNumber = config.randomManager.requestRandomness();
        newShip.traits.variant = _variant;

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

        uint referralPercentage;
        uint totalSold = referralCount[_referrer];

        // Hardcoded referral tiers (stages: 100, 1000, 10000, 50000, 100000)
        // Percentages: 0%, 10%, 20%, 35%, 50%
        if (totalSold >= 100000) {
            referralPercentage = 50;
        } else if (totalSold >= 50000) {
            referralPercentage = 35;
        } else if (totalSold >= 10000) {
            referralPercentage = 20;
        } else if (totalSold >= 1000) {
            referralPercentage = 10;
        } else if (totalSold >= 100) {
            // Tier 0 has 0%, so use tier 1's percentage (10%)
            referralPercentage = 10;
        } else {
            // Default to 1% for testing (below 100 ships)
            referralPercentage = 1;
        }

        uint referralAmount = (_salePrice * referralPercentage) / 100;

        (bool success, ) = payable(_referrer).call{value: referralAmount}("");
        if (!success) revert ReferralTransferFailed();
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
            universalCredits.mint(destroyerOwner, recycleReward >> 2); // Division by 4
        }

        emit MetadataUpdate(_id);
    }

    function setPurchaseInfo(
        uint8[] calldata _purchaseTiers,
        uint8[] calldata _tierShips,
        uint[] calldata _tierPrices
    ) external onlyOwner {
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
        address _metadataRenderer,
        address _shipAttributes,
        address _universalCredits
    ) public onlyOwner {
        config.gameAddress = _gameAddress;
        config.lobbyAddress = _lobbyAddress;
        config.fleetsAddress = _fleetsAddress;
        config.shipGenerator = IGenerateNewShip(_shipGenerator);
        config.randomManager = IRandomManager(_randomManager);
        config.metadataRenderer = IRenderMetadata(_metadataRenderer);
        config.shipAttributes = IShipAttributes(_shipAttributes);
        universalCredits = IUniversalCredits(_universalCredits);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        if (!success) revert WithdrawalFailed();
    }

    function setMaxVariant(uint16 _maxVariant) public onlyOwner {
        maxVariant = _maxVariant;
    }

    function setRecycleReward(uint _newReward) public onlyOwner {
        recycleReward = _newReward;
    }

    function setClaimCooldownPeriod(
        uint256 _newCooldownPeriod
    ) public onlyOwner {
        claimCooldownPeriod = _newCooldownPeriod;
    }

    // function setShipModified(uint _id, bool _modified) public onlyOwner {
    //     Ship storage ship = ships[_id];
    //     if (ship.id == 0) {
    //         revert InvalidId();
    //     }
    //     ship.shipData.modified = _modified;
    //     emit MetadataUpdate(_id);
    // }

    function claimFreeShips(uint16 _variant) external {
        uint256 lastClaim = lastClaimTimestamp[msg.sender];
        uint256 currentTime = block.timestamp;

        // Check if 4 weeks have passed since last claim (or if never claimed)
        if (lastClaim > 0) {
            if (currentTime < lastClaim + claimCooldownPeriod) {
                revert ClaimCooldownNotPassed();
            }
        }

        // Grant 10 free ships
        for (uint i = 0; i < 10; i++) {
            _mintShip(msg.sender, _variant);
            // Mark the ship as free (shipCount was incremented in _mintShip, so it's the ID of the ship just minted)
            ships[shipCount].shipData.isFreeShip = true;
        }

        // Record the timestamp of this claim
        lastClaimTimestamp[msg.sender] = currentTime;
    }

    /**
     * @dev VIEW
     */

    function getShip(uint _id) external view returns (Ship memory) {
        return ships[_id];
    }

    // Used by game contract
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
        external
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
    ) external view returns (uint[] memory) {
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
        uint[] calldata _ids
    ) external view returns (Ship[] memory) {
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
        return _trait < 50 ? 0 : (_trait < 80 ? 1 : 2);
    }

    function shipBreaker(uint[] calldata _shipIds) external nonReentrant {
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

            // Prevent recycling of free ships
            if (s.shipData.isFreeShip) {
                revert CannotRecycleFreeShip(shipId);
            }

            // Determine recycle reward based on destruction state PRIOR to this call
            bool wasDestroyed = s.shipData.timestampDestroyed != 0;
            uint rewardForThisShip = wasDestroyed
                ? (recycleReward >> 1) // Division by 2
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
