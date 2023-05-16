// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/PriceFeedAggregator.sol";
import "src/sys-controller/UnlimitedOwner.sol";
import "test/mocks/MockPriceFeed.sol";
import "test/setup/Constants.sol";

contract PriceFeedAggregatorTest is Test {
    IPriceFeedAggregator priceFeedAggregator;
    MockPriceFeed priceFeed1;
    MockPriceFeed priceFeed2;
    UnlimitedOwner unlimitedOwner;

    function setUp() public {
        priceFeed1 = new MockPriceFeed(
            ASSET_PRICE_0
        );
        priceFeed2 = new MockPriceFeed(
            ASSET_PRICE_0
        );

        IPriceFeed[] memory priceFeeds;

        unlimitedOwner = new UnlimitedOwner();
        unlimitedOwner.initialize();

        priceFeedAggregator = new PriceFeedAggregator(unlimitedOwner, "Test", 18, priceFeeds);
    }

    function testOnlyOwner() public {
        vm.prank(ALICE);
        vm.expectRevert("UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
        priceFeedAggregator.addPriceFeed(priceFeed1);
    }

    function testAcceptsTwoPriceFeeds() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
    }

    function testReturnsTwoDifferentPrices() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeed1.update(100);
        priceFeed2.update(200);
        assertEq(priceFeedAggregator.minPrice(), 100);
        assertEq(priceFeedAggregator.maxPrice(), 200);
    }

    function testAlsoWorksWithDifferentOrder() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeed1.update(200);
        priceFeed2.update(100);
        assertEq(priceFeedAggregator.minPrice(), 100);
        assertEq(priceFeedAggregator.maxPrice(), 200);
    }

    function testShouldReturnMinPrice() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeed1.update(100);
        priceFeed2.update(200);
        int256 minPrice = priceFeedAggregator.minPrice();
        assertEq(minPrice, 100);
    }

    function testShouldReturnMaxPrice() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeed1.update(100);
        priceFeed2.update(200);
        int256 maxPrice = priceFeedAggregator.maxPrice();
        assertEq(maxPrice, 200);
    }

    function testSetOnlyOnePriceFeed() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        vm.expectRevert("PriceFeedAggregator::minMaxPrices: less than two PriceFeeds");
        priceFeedAggregator.minPrice();
    }

    function testSetThreePriceFeed() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeedAggregator.addPriceFeed(
            new MockPriceFeed(
                333
            )
        );
        priceFeed1.update(111);
        priceFeed2.update(222);
        priceFeed2.update(222);
        assertEq(priceFeedAggregator.minPrice(), 111);
        assertEq(priceFeedAggregator.maxPrice(), 333);
    }

    function testRemovePriceFeed() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeedAggregator.removePriceFeed(0);
        vm.expectRevert("PriceFeedAggregator::minMaxPrices: less than two PriceFeeds");
        priceFeedAggregator.minPrice();
    }

    function testRemovePriceFeedAtIndexOne() public {
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        priceFeed2.update(111);
        priceFeedAggregator.removePriceFeed(1);
        assertEq(priceFeedAggregator.maxPrice(), 111);
    }

    function testConstruct() public {
        // ARRANGE
        IPriceFeed[] memory priceFeeds = new IPriceFeed[](2);
        priceFeeds[0] = priceFeed1;
        priceFeeds[1] = priceFeed2;
        priceFeed1.update(100);
        priceFeed2.update(200);

        // ACT
        priceFeedAggregator = new PriceFeedAggregator(unlimitedOwner, "test", 18, priceFeeds);

        // ASSERT
        assertEq(priceFeedAggregator.minPrice(), 100);
        assertEq(priceFeedAggregator.maxPrice(), 200);
    }

    function testIndexOutOfBoundsAtRemovePriceFeeds() public {
        priceFeedAggregator.addPriceFeed(priceFeed1);
        priceFeedAggregator.addPriceFeed(priceFeed2);
        vm.expectRevert("PriceFeedAggregator::removePriceFeed: index out of bounds");
        priceFeedAggregator.removePriceFeed(2);
    }
}
