// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IShips.sol";
import "./IUniversalCredits.sol";

contract ShipPurchaser is Ownable, ReentrancyGuard {
    error InvalidReferral();
    error InvalidPurchase(uint _tier, uint _amount);
    error ArrayLengthMismatch();
    error NotAuthorized(address);
    error InsufficientFunds(uint _required, uint _available);

    IShips public immutable ships;
    IERC20 public immutable universalCredits;
    IUniversalCredits public immutable universalCreditsMintable;

    // Static - Contract with the world
    // Hardcoded referral tiers (stages: 1000, 10000, 50000, 100000)
    // Percentages: 0%, 10%, 20%, 35%, 50%
    uint8[] public referralPercentages = [0, 10, 20, 35, 50];
    // Amount of Ships sold to reach each tier
    uint32[] public referralStages = [
        1000, // 1000 ships sold
        10000, // 10000 ships sold
        50000, // 50000 ships sold
        100000 // 100000 ships sold
    ];

    uint8[] public tierShips;
    uint[] public tierPrices;

    mapping(address => uint) public referralCount;
    mapping(address => bool) public isAllowedToCreateShips;

    constructor(address _ships, address _universalCredits) Ownable(msg.sender) {
        ships = IShips(_ships);
        universalCredits = IERC20(_universalCredits);
        universalCreditsMintable = IUniversalCredits(_universalCredits);

        tierShips = [5, 11, 22, 40, 60];
        // Using same tier structure but with UC tokens instead of ether
        tierPrices = [
            4.99 ether, // 4.99 UC
            9.99 ether, // 9.99 UC
            19.99 ether, // 19.99 UC
            34.99 ether, // 34.99 UC
            49.99 ether // 49.99 UC
        ];
    }

    function purchaseWithUC(
        address _to,
        uint8 _tier,
        address _referral,
        uint16 _variant
    ) public nonReentrant {
        if (_referral == address(0)) {
            revert InvalidReferral();
        }

        uint totalShips = tierShips[_tier];
        uint price = tierPrices[_tier];

        // Check balance before attempting transfer
        uint balance = universalCredits.balanceOf(msg.sender);
        if (balance < price) {
            revert InsufficientFunds(price, balance);
        }

        // Transfer UC tokens from buyer to this contract
        require(
            universalCredits.transferFrom(msg.sender, address(this), price),
            "UC transfer failed"
        );

        // Create ships for the buyer
        ships.createShips(_to, totalShips, _variant, _tier);

        // Process referral
        _processReferral(_referral, totalShips, price);
    }

    /**
     * @dev Direct UTC Purchase - 1:1 with tier prices
     *
     * This function allows players to purchase UTC directly for FLOW at a 1:1 rate.
     * The UTC amount matches the FLOW price for each tier.
     *
     * For each tier:
     * - Tier 0: 4.99 UTC for 4.99 FLOW
     * - Tier 1: 9.99 UTC for 9.99 FLOW
     * - Tier 2: 24.99 UTC for 24.99 FLOW
     * - Tier 3: 49.99 UTC for 49.99 FLOW
     * - Tier 4: 99.99 UTC for 99.99 FLOW
     */
    function purchaseUTCWithFlow(
        address _to,
        uint _tier
    ) public payable nonReentrant {
        if (_tier >= tierPrices.length) {
            revert InvalidPurchase(_tier, msg.value);
        }

        uint price = tierPrices[_tier];
        if (msg.value != price) {
            revert InvalidPurchase(_tier, msg.value);
        }

        // Mint UTC 1:1 with the price paid
        universalCreditsMintable.mint(_to, price);
    }

    function _processReferral(
        address _referrer,
        uint _shipsSold,
        uint _salePrice
    ) internal {
        referralCount[_referrer] += _shipsSold;

        uint referralPercentage = 0; // Default 0% for < 1000 ships

        for (uint i = referralStages.length; i > 0; i--) {
            if (referralCount[_referrer] >= referralStages[i - 1]) {
                referralPercentage = referralPercentages[i - 1];
                break;
            }
        }

        uint referralAmount = (_salePrice * referralPercentage) / 100;

        // Transfer UC tokens to referrer
        require(
            universalCredits.transfer(_referrer, referralAmount),
            "Referral transfer failed"
        );
    }

    /**
     * @dev OWNER
     */

    function setPurchaseInfo(
        uint8[] memory _tierShips,
        uint[] memory _tierPrices
    ) public onlyOwner {
        if (_tierShips.length != _tierPrices.length) {
            revert ArrayLengthMismatch();
        }
        tierShips = _tierShips;
        tierPrices = _tierPrices;
    }

    function getPurchaseInfo()
        external
        view
        returns (uint8[] memory, uint[] memory)
    {
        return (tierShips, tierPrices);
    }

    function withdrawUC() public onlyOwner {
        uint balance = universalCredits.balanceOf(address(this));
        require(
            universalCredits.transfer(owner(), balance),
            "UC withdrawal failed"
        );
    }

    function withdrawFlow() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "FLOW withdrawal failed");
    }
}
