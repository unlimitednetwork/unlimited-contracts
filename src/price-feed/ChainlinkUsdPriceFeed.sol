// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../external/interfaces/chainlink/AggregatorV3Interface.sol";
import "../interfaces/IPriceFeed.sol";

contract ChainlinkUsdPriceFeed is IPriceFeed {
    AggregatorV3Interface internal immutable chainlinkPriceFeed;

    /**
     * @notice Constructs the ChainlinkUsdPriceFeed contract.
     * @param chainlinkPriceFeed_ The address of the Chainlink price feed.
     */
    constructor(AggregatorV3Interface chainlinkPriceFeed_) {
        chainlinkPriceFeed = chainlinkPriceFeed_;
    }

    /**
     * @notice Returns last price
     * @return the price from the last round
     */
    function price() external view returns (int256) {
        (uint80 assetbaseRoundID, int256 answer,, uint256 baseTimestamp, uint80 baseAnsweredInRound) =
            chainlinkPriceFeed.latestRoundData();
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
