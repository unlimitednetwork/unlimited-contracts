// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../external/interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../interfaces/IPriceFeed.sol";

/**
 * @title ChainlinkUsdPriceFeedPrevious
 * @notice Price feed that returns the previous price from Chainlink.
 * @dev The previous price is used by PriceFeedAggregator in case there is only one price feed. By this a price spread
 * can be simulated. A price spread is used to offer different prices for buy and sell operations.
 */
contract ChainlinkUsdPriceFeedPrevious is IPriceFeed {
    AggregatorV2V3Interface internal immutable chainlinkPriceFeed;

    /**
     * @notice Constructs the ChainlinkUsdPriceFeed contract.
     * @param chainlinkPriceFeed_ The address of the Chainlink price feed.
     */
    constructor(AggregatorV2V3Interface chainlinkPriceFeed_) {
        chainlinkPriceFeed = chainlinkPriceFeed_;
    }

    /**
     * @notice Returns previous price
     * @return the price from the previous round
     */
    function price() external view returns (int256) {
        uint256 roundId = chainlinkPriceFeed.latestRound();
        (, int256 _price,,,) = chainlinkPriceFeed.getRoundData(uint80(roundId) - 1);
        return _price;
    }
}
