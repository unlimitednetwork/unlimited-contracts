// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/IPriceFeedAggregator.sol";
import "../external/interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../shared/UnlimitedOwnable.sol";

/**
 * @title Simple Price Feed Aggregator
 * @notice Aggregates prices from one or multiple price feeds.
 * Provides min and max price and asset to usd conversion
 */
contract PriceFeedAggregator is IPriceFeedAggregator, UnlimitedOwnable {
    /* ========== CONSTANTS ========== */

    uint256 constant USD_MULTIPLIER = 1e8;

    /* ========== STATE VARIABLES ========== */

    IPriceFeed[] priceFeeds;

    string public name;
    uint256 public immutable assetDecimals;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the PriceFeedAggregator contract.
     * @param unlimitedOwner_ The address of the unlimited owner.
     * @param name_ The name of the price feed aggregator.
     * @param assetDecimals_ The decimals of the asset.
     * @param priceFeeds_ The addresses of the price feeds.
     */
    constructor(
        IUnlimitedOwner unlimitedOwner_,
        string memory name_,
        uint256 assetDecimals_,
        IPriceFeed[] memory priceFeeds_
    ) UnlimitedOwnable(unlimitedOwner_) {
        name = name_;
        assetDecimals = assetDecimals_;
        priceFeeds = priceFeeds_;
    }

    /* ========== PRICE FEEDS ========== */

    /**
     * @notice Adds a price feeds
     * @param priceFeed_ the price feed
     */
    function addPriceFeed(IPriceFeed priceFeed_) external onlyOwner {
        priceFeeds.push(priceFeed_);
    }

    /**
     * @notice Removes PriceFeed at the index
     * @param index_ the index of the price feed
     */
    function removePriceFeed(uint256 index_) external onlyOwner {
        require(index_ < priceFeeds.length, "PriceFeedAggregator::removePriceFeed: index out of bounds");
        priceFeeds[index_] = priceFeeds[priceFeeds.length - 1];
        priceFeeds.pop();
    }

    /* ========== PRICE VIEW FUNCTIONS ========== */

    /**
     * @notice returns the current minimum price
     */

    function minPrice() external view returns (int256) {
        (int256 _minPrice,) = minMaxPrices();
        return _minPrice;
    }

    /**
     * @notice returns the current maximum price
     */
    function maxPrice() external view returns (int256) {
        (, int256 _maxPrice) = minMaxPrices();
        return _maxPrice;
    }

    /**
     * @notice returns minimum and maximum prices
     */
    function minMaxPrices() public view returns (int256, int256) {
        require(priceFeeds.length >= 2, "PriceFeedAggregator::minMaxPrices: less than two PriceFeeds");
        return _minMaxFromMultiplePriceFeeds();
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _minMaxFromMultiplePriceFeeds() internal view returns (int256, int256) {
        int256 _minPrice = 2 ** 128;
        int256 _maxPrice = 0;
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            int256 _price = priceFeeds[i].price();
            if (_price < _minPrice) {
                _minPrice = _price;
            }
            if (_price > _maxPrice) {
                _maxPrice = _price;
            }
        }
        return (_minPrice, _maxPrice);
    }
}
