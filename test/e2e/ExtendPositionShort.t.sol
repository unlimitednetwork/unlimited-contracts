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

        // ADD LIQUIDITY
        liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, true);
        vm.roll(2);
    }

    function testExtendPositionSimple() public {
        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB, tradePair0, positionId, INITIAL_BALANCE, LEVERAGE_0, ASSET_PRICE_0);

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
        assertEq(tradePair0.detailsOfPosition(positionId).PnL, 0, "PnL");
        assertEq(tradePair0.detailsOfPosition(positionId).bankruptcyPrice, ASSET_PRICE_0 * 6 / 5, "bankruptcyPrice");
    }

    function testExtendPositionWithProfit() public {
        // price halfes, so PnL should be 2.5x margin
        int256 expectedPnL = int256(MARGIN_0) * 5 / 2;

        // CHANGE PRICE
        int256 newPrice = int256(1_000 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        //  should be 2/3 first price and 1/3 second price
        int256 newEntryPrice = (ASSET_PRICE_0 + newPrice * 2) / 3;

        // newEntryPrice * 4 / 5
        int256 newBankruptcyPrice = (ASSET_PRICE_0 + newPrice * 2) * 6 / 3 / 5;
        uint256 newAssetAmount = ASSET_AMOUNT_0 * 3;

        assertEq(tradePair0.detailsOfPosition(positionId).PnL, expectedPnL, "PnL before");

        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB, tradePair0, positionId, INITIAL_BALANCE, LEVERAGE_0, newPrice);

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
        assertEq(tradePair0.detailsOfPosition(positionId).PnL, expectedPnL, "PnL after (should not change)");
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice, newEntryPrice, "entryPrice");
        assertEq(
            tradePair0.detailsOfPosition(positionId).bankruptcyPrice,
            newBankruptcyPrice - 1,
            "bankruptcyPrice, -1 bc rounding error"
        );
    }

    function testExtendPositionWithLoss() public {
        // price doubles, so PnL should be 5x margin.
        int256 expectedPnL = -int256(MARGIN_0) / 2;

        // CHANGE PRICE
        int256 newPrice = int256(2_200 * COLLATERAL_MULTIPLIER);

        int256 newEntryPrice = (ASSET_PRICE_0 * 22 / 20 + newPrice) * 20 / 42;

        // newEntryPrice * 6 / 5
        int256 newBankruptcyPrice = newEntryPrice * 6 / 5;

        // rounding error occurs here expectedly
        uint256 newAssetAmount = ASSET_AMOUNT_0 * 42 / 22;

        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        assertEq(tradePair0.detailsOfPosition(positionId).PnL, expectedPnL, "PnL before");

        // EXTEND POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _extendPosition(BOB, tradePair0, positionId, INITIAL_BALANCE, LEVERAGE_0, newPrice);

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
        assertEq(
            tradePair0.detailsOfPosition(positionId).PnL,
            expectedPnL + 1,
            "PnL after (should not change) +1 bc. of rounding errors from assetAmount"
        );
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice, newEntryPrice, "entryPrice");
        assertEq(tradePair0.detailsOfPosition(positionId).bankruptcyPrice, newBankruptcyPrice, "bankruptcyPrice");
    }

    /* ========== HELPER FUNCTIONS =========== */

    function _closePosition(address user, ITradePair tradePair, uint256 positionId_, int256 constraintPrice)
        private
        prank(user)
    {
        ClosePositionParams memory closePositionParams = ClosePositionParams(address(tradePair), positionId_);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.closePosition(closePositionParams, constraints, updateData);
    }

    function _extendPosition(
        address user,
        ITradePair tradePair,
        uint256 positionId_,
        uint256 addedMargin,
        uint256 addedLeverage,
        int256 constraintPrice
    ) private prank(user) {
        ExtendPositionParams memory extendPositionParams =
            ExtendPositionParams(address(tradePair), positionId_, addedMargin, addedLeverage);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), addedMargin);

        tradeManager.extendPosition(extendPositionParams, constraints, updateData);
    }

    function _extendPositionToLeverage(
        address user,
        ITradePair tradePair,
        uint256 positionId_,
        uint256 targetLeverage,
        int256 constraintPrice
    ) private prank(user) {
        ExtendPositionToLeverageParams memory extendPositionToLeverageParams =
            ExtendPositionToLeverageParams(address(tradePair), positionId_, targetLeverage);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.extendPositionToLeverage(extendPositionToLeverageParams, constraints, updateData);
    }

    function _openPosition(address user, ITradePair tradePair, uint256 margin, uint256 leverage, bool isShort)
        private
        prank(user)
        returns (uint256)
    {
        OpenPositionParams memory openPositionParams =
            OpenPositionParams(address(tradePair), margin, leverage, isShort, address(0), address(0));
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, ASSET_PRICE_0 * 99 / 100, ASSET_PRICE_0 * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), margin);
        return tradeManager.openPosition(openPositionParams, constraints, updateData);
    }

    function _depositLiquidity(ILiquidityPool liquidityPool, address user, uint256 amount)
        private
        prank(user)
        returns (uint256 shares)
    {
        collateral.approve(address(liquidityPool), amount);
        shares = liquidityPool.deposit(amount, 0);
    }

    modifier prank(address executor) {
        vm.startPrank(executor);
        _;
        vm.stopPrank();
    }
}
