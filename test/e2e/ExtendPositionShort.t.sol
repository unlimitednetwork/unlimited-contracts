// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract ExtendPositionShortTest is WithFullFixtures {
    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

    uint256 positionId;
    uint256 liquidityAmount;

    function setUp() public {
        vm.warp(1 hours);
        _deployMainContracts();

        // NOTE: only for test purposes
        collateral = new MockToken();
        collateral.setDecimals(6);

        liquidityPool0 = _deployLiquidityPool(controller, collateral, "LP1");
        liquidityPool1 = _deployLiquidityPool(controller, collateral, "LP2");

        LiquidityPoolConfig[] memory liquidityConfig = new LiquidityPoolConfig[](2);
        liquidityConfig[0] = LiquidityPoolConfig(address(liquidityPool0), uint96(FULL_PERCENT));
        liquidityConfig[1] = LiquidityPoolConfig(address(liquidityPool1), uint96(FULL_PERCENT));

        liquidityPoolAdapter = _deployLiquidityPoolAdapter(controller, feeManager, collateral, liquidityConfig);

        // Deploy price feeds
        priceFeedAdapter = _deployPriceFeed(controller);

        tradePair0 = _deployTradePair(
            controller, userManager, feeManager, tradeManager, collateral, priceFeedAdapter, liquidityPoolAdapter
        );

        // Set Liquidator reward to zero to make bankruptcy price calculation simpler
        tradePair0.setLiquidatorReward(0);

        // ADD LIQUIDITY
        liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        positionId = _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, true);
        vm.roll(2);
    }

    function testExtendPositionSimple() public {
        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB_PK, tradeManager, tradePair0, positionId, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT FEES GET COLLECTED (should be double the amount of open position fees)
        assertEq(collateral.balanceOf(address(STAKERS_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 18 / 100, "stakers");
        assertEq(collateral.balanceOf(address(DEV_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 12 / 100, "dev");
        assertEq(collateral.balanceOf(address(INSURANCE_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 10 / 100, "insurance");

        assertEq(collateral.balanceOf(address(tradePair0)), 2 * MARGIN_0, "tradePair0");
        assertEq(collateral.balanceOf(BOB), 0, "bob");

        // ASSERT POSITION DETAILS
        assertEq(tradePair0.detailsOfPosition(positionId).margin, 2 * MARGIN_0, "margin");
        assertEq(tradePair0.detailsOfPosition(positionId).leverage, LEVERAGE_0, "leverage");
        assertEq(tradePair0.detailsOfPosition(positionId).assetAmount, 2 * ASSET_AMOUNT_0, "assetAmount");
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0, "entryPrice");
    }

    function testExtendPositionWithProfit() public {
        // CHANGE PRICE
        int256 newPrice = int256(1_000 * PRICE_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        //  should be 2/3 first price and 1/3 second price
        int256 newEntryPrice = (ASSET_PRICE_0 + newPrice * 2) / 3;

        uint256 newAssetAmount = ASSET_AMOUNT_0 * 3;

        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB_PK, tradeManager, tradePair0, positionId, newPrice, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT FEES GET COLLECTED (should be double the amount of open position fees)
        assertEq(collateral.balanceOf(address(STAKERS_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 18 / 100, "stakers");
        assertEq(collateral.balanceOf(address(DEV_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 12 / 100, "dev");
        assertEq(collateral.balanceOf(address(INSURANCE_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 10 / 100, "insurance");

        assertEq(collateral.balanceOf(address(tradePair0)), 2 * MARGIN_0, "tradePair0");
        assertEq(collateral.balanceOf(BOB), 0, "bob");

        // ASSERT POSITION DETAILS
        assertEq(tradePair0.detailsOfPosition(positionId).margin, 2 * MARGIN_0, "margin");
        assertEq(tradePair0.detailsOfPosition(positionId).volume, 2 * VOLUME_0, "volume");
        assertEq(tradePair0.detailsOfPosition(positionId).leverage, LEVERAGE_0, "leverage");
        assertEq(tradePair0.detailsOfPosition(positionId).assetAmount, newAssetAmount, "assetAmount");
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice, newEntryPrice, "entryPrice");
    }

    function testExtendPositionWithLoss() public {
        // CHANGE PRICE
        int256 newPrice = int256(2_200 * PRICE_MULTIPLIER);

        int256 newEntryPrice = (ASSET_PRICE_0 * 22 / 20 + newPrice) * 20 / 42;

        // rounding error occurs here expectedly
        uint256 newAssetAmount = ASSET_AMOUNT_0 * 42 / 22;

        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB_PK, tradeManager, tradePair0, positionId, newPrice, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT FEES GET COLLECTED (should be double the amount of open position fees)
        assertEq(collateral.balanceOf(address(STAKERS_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 18 / 100, "stakers");
        assertEq(collateral.balanceOf(address(DEV_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 12 / 100, "dev");
        assertEq(collateral.balanceOf(address(INSURANCE_ADDRESS)), 2 * OPEN_POSITION_FEE_0 * 10 / 100, "insurance");

        assertEq(collateral.balanceOf(address(tradePair0)), 2 * MARGIN_0, "tradePair0");
        assertEq(collateral.balanceOf(BOB), 0, "bob");

        // ASSERT POSITION DETAILS
        assertEq(tradePair0.detailsOfPosition(positionId).margin, 2 * MARGIN_0, "margin");
        assertEq(tradePair0.detailsOfPosition(positionId).leverage, LEVERAGE_0, "leverage");
        assertEq(tradePair0.detailsOfPosition(positionId).assetAmount, newAssetAmount, "assetAmount");
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice / 1e8, newEntryPrice / 1e8, "entryPrice");
    }

    /* ========== HELPER FUNCTIONS =========== */

    function _depositLiquidity(ILiquidityPool liquidityPool, address user, uint256 amount)
        private
        prank(user)
        returns (uint256 shares)
    {
        collateral.approve(address(liquidityPool), amount);
        shares = liquidityPool.deposit(amount, 0);
    }
}
