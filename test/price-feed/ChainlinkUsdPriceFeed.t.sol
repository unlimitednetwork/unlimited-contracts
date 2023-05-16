// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/ChainlinkUsdPriceFeedPrevious.sol";
import "test/mocks/MockV3Aggregator.sol";

contract ChainlinkUsdPriceFeedTest is Test {
    MockV3Aggregator mockAggregator;
    ChainlinkUsdPriceFeed chainlinkUsdPriceFeed;

    function setUp() public {
        // set previous price to 111
        mockAggregator = new MockV3Aggregator(18, 111 * 1e18);
        // set last price to 222
        mockAggregator.updateAnswer(222 * 1e18);
        chainlinkUsdPriceFeed = new ChainlinkUsdPriceFeed(
            mockAggregator
        );
    }

    // returns last price
    function testReturnsLastPrice() public {
        assertEq(chainlinkUsdPriceFeed.price(), 222 * 1e18);
    }

    function testLastPrices() public {
        IPriceFeed chainlinkPriceFeedPrevious = new ChainlinkUsdPriceFeedPrevious(
            mockAggregator
        );
        assertEq(chainlinkPriceFeedPrevious.price(), 111 * 1e18);
    }
}
