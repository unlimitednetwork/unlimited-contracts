// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "./WithTradePair.sol";

contract TradePairAdminSettingsTest is Test, WithTradePair {
    function setUp() public {
        deployTradePair();
        vm.startPrank(UNLIMITED_OWNER);
    }

    function testInitialize() public {
        // ACT
        tradePair = new TradePair(
            mockUnlimitedOwner,
            mockTradeManager,
            mockUserManager,
            mockFeeManager
        );

        tradePair.initialize({
            name: "Ethereum Trade Pair",
            collateral: collateral,
            assetDecimals: ASSET_DECIMALS,
            priceFeedAdapter: mockPriceFeedAdapter,
            liquidityPoolAdapter: mockLiquidityPoolAdapter
        });

        // ASSERT
        // Set in constructor
        assertEq(address(tradePair.tradeManager()), address(mockTradeManager));
        assertEq(address(tradePair.userManager()), address(mockUserManager));
        assertEq(address(tradePair.feeManager()), address(mockFeeManager));

        // Set in initializer
        assertEq(address(tradePair.collateral()), address(collateral));
        assertEq(address(tradePair.priceFeedAdapter()), address(mockPriceFeedAdapter));
        assertEq(address(tradePair.liquidityPoolAdapter()), address(mockLiquidityPoolAdapter));
        assertEq(tradePair.name(), "Ethereum Trade Pair");
    }

    function testSetMaxFundingFeeRate() public {
        tradePair.setMaxFundingFeeRate(123_456);
        (,, int256 fundingFeeRate,,,,) = tradePair.feeIntegral();
        assertEq(fundingFeeRate, 123_456);
    }

    function testSetBorrowFeeRate() public {
        tradePair.setBorrowFeeRate(123_456);
        (,,,,, int256 borrowFeeRate,) = tradePair.feeIntegral();
        assertEq(borrowFeeRate, 123_456);
    }

    function testSeFeeBufferFactor() public {
        tradePair.setFeeBufferFactor(123_456);
        (, int256 bufferFactor) = tradePair.feeBuffer();
        assertEq(bufferFactor, 123_456);
    }

    function testSetMaxExcessRatio() public {
        tradePair.setMaxExcessRatio(MAX_EXCESS_RATIO + 1);
    }

    function testSetLiquidatorReward() public {
        tradePair.setLiquidatorReward(LIQUIDATOR_REWARD);
        assertEq(tradePair.liquidatorReward(), LIQUIDATOR_REWARD);
    }

    function testSetMinLeverage() public {
        tradePair.setMinLeverage(MIN_LEVERAGE);
        assertEq(tradePair.minLeverage(), MIN_LEVERAGE);
    }

    function testSetMinLeverageRequire() public {
        vm.expectRevert("TradePair::setMinLeverage: Leverage too small");
        tradePair.setMinLeverage(MIN_LEVERAGE - 1);
    }

    function testSetMaxLeverage() public {
        vm.expectRevert("TradePair::setMaxLeverage: Leverage to high");
        tradePair.setMaxLeverage(MAX_LEVERAGE + 1);
    }

    function testSetMaxLeverageRequire() public {
        tradePair.setMaxLeverage(MAX_LEVERAGE);
        assertEq(tradePair.maxLeverage(), MAX_LEVERAGE);
    }

    function testSetMinMargin() public {
        tradePair.setMinMargin(MIN_MARGIN);
        assertEq(tradePair.minMargin(), MIN_MARGIN);
    }

    function testSetVolumeLimit() public {
        tradePair.setVolumeLimit(VOLUME_LIMIT);
        assertEq(tradePair.volumeLimit(), VOLUME_LIMIT);
    }
}
