// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../external/interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../interfaces/IPriceFeed.sol";

contract ChainlinkUsdPriceFeed is IPriceFeed {
    AggregatorV2V3Interface internal immutable chainlinkPriceFeed;

    /**
     * @notice Constructs the ChainlinkUsdPriceFeed contract.
     * @param chainlinkPriceFeed_ The address of the Chainlink price feed.
     */
    constructor(AggregatorV2V3Interface chainlinkPriceFeed_) {
        chainlinkPriceFeed = chainlinkPriceFeed_;
    }

    /**
     * @notice Returns last price
     * @return the price from the last round
     */
    function price() external view returns (int256) {
        return chainlinkPriceFeed.latestAnswer();
    }
}
