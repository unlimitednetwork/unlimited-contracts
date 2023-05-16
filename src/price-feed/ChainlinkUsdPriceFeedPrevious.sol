// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../external/interfaces/chainlink/AggregatorV3Interface.sol";
import "../interfaces/IPriceFeed.sol";

/**
 * @title ChainlinkUsdPriceFeedPrevious
 * @notice Price feed that returns the previous price from Chainlink.
 * @dev The previous price is used by PriceFeedAggregator in case there is only one price feed. By this a price spread
 * can be simulated. A price spread is used to offer different prices for buy and sell operations.
 */
contract ChainlinkUsdPriceFeedPrevious is IPriceFeed {
    AggregatorV3Interface internal immutable chainlinkPriceFeed;

    /**
     * @notice Constructs the ChainlinkUsdPriceFeed contract.
     * @param chainlinkPriceFeed_ The address of the Chainlink price feed.
     */
    constructor(AggregatorV3Interface chainlinkPriceFeed_) {
        chainlinkPriceFeed = chainlinkPriceFeed_;
    }

    /**
     * @notice Returns previous price
     * @return the price from the previous round
     */
    function price() external view returns (int256) {
        // Retrice current round data
        (uint80 roundId,,,,) = chainlinkPriceFeed.latestRoundData();

        // Now get data from the previous round
        (uint80 assetbaseRoundID, int256 answer,, uint256 baseTimestamp, uint80 baseAnsweredInRound) =
            chainlinkPriceFeed.getRoundData(uint80(roundId) - 1);
        require(answer > 0, "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: answer <= 0");
        require(
            baseAnsweredInRound >= assetbaseRoundID,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: stale price"
        );
        require(
            baseTimestamp > 0,
            "UnlimitedPriceFeedAdapter::_getChainLinkPrice:assetChainlinkPriceFeed: round not complete"
        );

        return answer;
    }
}
