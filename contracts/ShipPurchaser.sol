// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IShips.sol";

contract ShipPurchaser is Ownable, ReentrancyGuard {
    error InvalidReferral();
    error InvalidPurchase(uint _tier, uint _amount);
    error ArrayLengthMismatch();
    error NotAuthorized(address);
    error InsufficientFunds(uint _required, uint _available);

    IShips public immutable ships;
    IERC20 public immutable universalCredits;

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

    uint8[] public purchaseTiers;
    uint8[] public tierShips;
    uint[] public tierPrices;

    mapping(address => uint) public referralCount;
    mapping(address => bool) public isAllowedToCreateShips;

    constructor(address _ships, address _universalCredits) Ownable(msg.sender) {
        ships = IShips(_ships);
        universalCredits = IERC20(_universalCredits);

        purchaseTiers = [1, 2, 3, 4, 5];
        tierShips = [5, 11, 28, 60, 125];
        // Using same tier structure but with UC tokens instead of ether
        tierPrices = [
            4.99 ether, // 4.99 UC
            9.99 ether, // 9.99 UC
            24.99 ether, // 24.99 UC
            49.99 ether, // 49.99 UC
            99.99 ether // 99.99 UC
        ];
    }

    function purchaseWithUC(
        address _to,
        uint _tier,
        address _referral
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
        ships.createShips(_to, totalShips);

        // Process referral
        _processReferral(_referral, totalShips, price);
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

    function getPurchaseInfo()
        external
        view
        returns (uint8[] memory, uint8[] memory, uint[] memory)
    {
        return (purchaseTiers, tierShips, tierPrices);
    }

    function withdrawUC() public onlyOwner {
        uint balance = universalCredits.balanceOf(address(this));
        require(
            universalCredits.transfer(owner(), balance),
            "UC withdrawal failed"
        );
    }
}
