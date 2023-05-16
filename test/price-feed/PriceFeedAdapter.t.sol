// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/PriceFeedAdapter.sol";
import "test/mocks/MockPriceFeedAggregator.sol";
import "test/setup/Constants.sol";

contract PriceFeedAdapterTest is Test {
    IPriceFeedAdapter priceFeedAdapter;
    MockPriceFeedAggregator assetPriceFeedAggregator;
    MockPriceFeedAggregator collateralPriceFeedAggregator;

    function setUp() public {
        assetPriceFeedAggregator = new MockPriceFeedAggregator(
            "Asset Price Feed Aggregator",
            111 * 1e8,
            222 * 1e8
        );
        collateralPriceFeedAggregator = new MockPriceFeedAggregator(
            "Collateral Price Feed Aggregator",
            1e8,
            1e8
        );

        priceFeedAdapter = new PriceFeedAdapter("Test", assetPriceFeedAggregator, collateralPriceFeedAggregator, 18, 6);
    }

    function testCollateralToAsset() public {
        assertEq(priceFeedAdapter.collateralToAssetMax(111 * 1e6), 1 * 1e18, "max");
        assertEq(priceFeedAdapter.collateralToAssetMin(222 * 1e6), 1 * 1e18, "min");
    }

    function testAssetToCollateral() public {
        assertEq(priceFeedAdapter.assetToCollateralMax(1 * 1e18), 222 * 1e6, "max");
        assertEq(priceFeedAdapter.assetToCollateralMin(1 * 1e18), 111 * 1e6, "min");
    }

    function testCollateralPrice() public {
        collateralPriceFeedAggregator.update(99 * 1e6, 101 * 1e6);
        assertEq(priceFeedAdapter.collateralToAssetMax(111 * 1e6), 101 * 1e16, "max asset");
        assertEq(priceFeedAdapter.collateralToAssetMin(222 * 1e6), 99 * 1e16, "min asset");
        assertEq(priceFeedAdapter.assetToCollateralMax(99 * 1e16), 222 * 1e6, "max collateral");
        assertEq(priceFeedAdapter.assetToCollateralMin(101 * 1e16), 111 * 1e6, "min collateral");
    }

    function testCollateralToUsd() public {
        collateralPriceFeedAggregator.update(99 * 1e6, 101 * 1e6);
        assertEq(priceFeedAdapter.collateralToUsdMax(100 * 1e6), 101 * 1e8, "max");
        assertEq(priceFeedAdapter.collateralToUsdMin(100 * 1e6), 99 * 1e8, "min");
    }

    function testAssetToUsd() public {
        assertEq(priceFeedAdapter.assetToUsdMax(1 * 1e18), 222 * 1e8, "max");
        assertEq(priceFeedAdapter.assetToUsdMin(1 * 1e18), 111 * 1e8, "min");
    }

    function testMarkPricesIsDenominatedInCollateral() public {
        assetPriceFeedAggregator.update(24 * 1e8, 30 * 1e8);
        collateralPriceFeedAggregator.update(75 * 1e6, 120 * 1e6);

        // Min Price: 24 / 1.20 = 20
        assertEq(priceFeedAdapter.markPriceMin(), 20 * 1e6, "min asset price");
        // Max Price: 30 / 0.75 = 40
        assertEq(priceFeedAdapter.markPriceMax(), 40 * 1e6, "max asset price");
    }
}
