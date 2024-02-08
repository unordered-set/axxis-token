// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AXXISSale is UUPSUpgradeable, OwnableUpgradeable {
    uint40 public constant publicRoundAllocation = 120_000_000_000;

    uint40 public totalSold;
    uint32 public saleEndTimestamp;
    mapping(address => uint40) public allocations;
    mapping(IERC20 => uint256) public priceDivisors;

    event TokensBought(
        address indexed buyer,
        uint256 amount,
        IERC20 currency,
        uint256 price
    );

    error SaleEnded(uint32 saleEndTimestamp, uint32 currentTimestamp);
    error UnsupportedCurrency(IERC20 currency);
    error OutOfStock(uint40 totalSold, uint40 publicRoundAllocation);

    constructor() {
        _disableInitializers();
    }

    // Contract starts with infinite (uint32 max) sale end timestamp.
    function initialize(
        address owner,
        IERC20[] calldata supportedCurrencies
    ) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(owner);

        saleEndTimestamp = type(uint32).max;

        for (uint8 i = 0; i < supportedCurrencies.length; ) {
            priceDivisors[supportedCurrencies[i]] =
                10 ** (supportedCurrencies[i].decimals() - 2); // 0.01 of the currency
            unchecked {
                i += 1;
            }
        }
    }

    // This function also can work as a pause function.
    function setEndTimestamp(uint256 timestamp) external onlyOwner {
        saleEndTimestamp = uint32(timestamp);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function buy(IERC20 currency, uint256 amount) external {
        uint32 currentTimestamp = uint32(block.timestamp);
        if (saleEndTimestamp < currentTimestamp) {
            revert SaleEnded(saleEndTimestamp, currentTimestamp);
        }
        uint256 priceDivisor = priceDivisors[currency];
        if (priceDivisor == 0) {
            revert UnsupportedCurrency(currency);
        }
        uint40 allocation = uint40(amount / priceDivisor);
        totalSold += allocation;
        if (totalSold > publicRoundAllocation) {
            revert OutOfStock(totalSold, publicRoundAllocation);
        }
        allocations[msg.sender] += allocation;
        
        uint256 price = uint256(allocation) * priceDivisor;
        currency.transferFrom(msg.sender, owner(), price);
        emit TokensBought(msg.sender, allocation, currency, price);
    }
}
