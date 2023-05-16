// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract FeeBufferAtLiquidationTest is WithFullFixtures {
    // This test cpmrises multiple test cases, to make sure that fee calculation works in a consistent manner.
    // All test cases expose a position to a total of 10 hours of fee payment, and then a liquidation.
    // The amounts send to the maker, liquidator, tradepair, feemanager, and liquiditypool should be equal after each test.
    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

    uint256 liquidityAmount = 10_000_000 * COLLATERAL_MULTIPLIER;
    uint256 positionIdBob;

    uint256 expectedBorrowFees = uint256((BASIS_BORROW_FEE_0) * 50 * int256(VOLUME_0) / FEE_MULTIPLIER);
    uint256 expectedFundingFees = uint256((FUNDING_FEE_0) * 50 * int256(VOLUME_0) / FEE_MULTIPLIER);
    // LP gets 100% of (borrow fees - liquidatorReward), 60% open and close fees,
    uint256 expectedLiquidity = liquidityAmount - MARGIN_0 + expectedBorrowFees - LIQUIDATOR_REWARD
        + uint256(OPEN_POSITION_FEE_0 + (MARGIN_0) / 1000) * 6 / 10;

    // bob receives the equity minues the liquidator reward and pays the close fee
    uint256 expectedPayoutBob = (MARGIN_0) * 999 / 1000;

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
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN SHORT POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        positionIdBob = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, true);
    }

    function testNormalLiquidation() public {
        // Case: Liquiditation bc. of fees
        // A Profit should be payed out to the maker
        // Profit and fees are both 1_000_000
        // Position is SHORT; so price effect has to be negated

        // Increase time by 50 hours (=100% of margin) and decrease price to 1_600 (+100% pnl)
        vm.warp(50 hours + 1 hours);
        vm.roll(2);
        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);

        // LIQUIDATE BOB'S POSITION
        _liquidatePosition(ALICE, tradePair0, positionIdBob);

        // ASSERT BOB DID NOT GET ANY COLLATERAL
        assertEq(collateral.balanceOf(BOB), expectedPayoutBob, "bob");
        assertEq(collateral.balanceOf(ALICE), LIQUIDATOR_REWARD, "alice");
        assertEq(collateral.balanceOf(address(tradePair0)), expectedFundingFees, "tradePair");
        assertEq(collateral.balanceOf(address(liquidityPool0)), expectedLiquidity, "lp0");
    }

    function testWithPartiallyClose() public {
        // In this test, the position gets closed by 50% half the way through the fee period.
        // As the volume is 50%, the second period will be doubled

        // Increase time by 25 hours (=50% of margin)
        vm.warp(25 hours + 1 hours);
        vm.roll(2);

        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        _partiallyClosePosition(BOB, tradePair0, positionIdBob, ASSET_PRICE_0_3, 500_000);

        assertEq(collateral.balanceOf(BOB), expectedPayoutBob * 3 / 4, "bob after partially close");

        // Increase time by another 50 hours (=50% of margin) and decrease price to 1_600 (+100% pnl)
        // Even though fee is massively overcollected.
        vm.warp(75 hours + 1 hours);
        vm.roll(3);

        // LIQUIDATE BOB'S POSITION
        _liquidatePosition(ALICE, tradePair0, positionIdBob);

        // ASSERT BOB DID NOT GET ANY COLLATERAL
        assertEq(collateral.balanceOf(BOB), expectedPayoutBob, "bob");
        assertEq(collateral.balanceOf(ALICE), LIQUIDATOR_REWARD, "alice");
        assertEq(collateral.balanceOf(address(tradePair0)), expectedFundingFees, "tradePair");
        assertEq(collateral.balanceOf(address(liquidityPool0)), expectedLiquidity, "lp0");
    }

    /* ========== HELPER FUNCTIONS =========== */

    function _liquidatePosition(address user, ITradePair tradePair, uint256 positionId) private prank(user) {
        UpdateData[] memory updateData;

        tradeManager.liquidatePosition(address(tradePair), positionId, updateData);
    }

    function _closePosition(address user, ITradePair tradePair, uint256 positionId, int256 constraintPrice)
        private
        prank(user)
    {
        ClosePositionParams memory closePositionParams = ClosePositionParams(address(tradePair), positionId);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.closePosition(closePositionParams, constraints, updateData);
    }

    function _partiallyClosePosition(
        address user,
        ITradePair tradePair,
        uint256 positionId,
        int256 constraintPrice,
        uint256 proportion
    ) private prank(user) {
        PartiallyClosePositionParams memory partiallyClosePositionParams =
            PartiallyClosePositionParams(address(tradePair), positionId, proportion);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.partiallyClosePosition(partiallyClosePositionParams, constraints, updateData);
    }

    function _extendPosition(
        address user,
        ITradePair tradePair,
        uint256 positionId,
        uint256 addedMargin,
        uint256 addedLeverage,
        int256 constraintPrice
    ) private prank(user) {
        ExtendPositionParams memory extendPositionParams =
            ExtendPositionParams(address(tradePair), positionId, addedMargin, addedLeverage);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), addedMargin);
        tradeManager.extendPosition(extendPositionParams, constraints, updateData);
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
