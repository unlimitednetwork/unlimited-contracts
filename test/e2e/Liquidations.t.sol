// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract E2ETest is WithFullFixtures {
    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

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
    }

    function testLiquidation() public {
        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionIdBob = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);

        // Increase time and decrease price to 1_800
        vm.warp(1 days + 1 hours);
        vm.roll(2);
        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);

        // ASSERT BOB'S POSITION IS LIQUIDATABLE
        assertTrue(tradeManager.positionIsLiquidatable(address(tradePair0), positionIdBob));

        // LIQUIDATE BOB'S POSITION
        _liquidatePosition(ALICE, tradePair0, positionIdBob);

        // ASSERT BOB'S POSITION IS CLOSED
        vm.expectRevert();
        _liquidatePosition(ALICE, tradePair0, positionIdBob);

        uint256 expectedBorrowFees = uint256((BASIS_BORROW_FEE_0) * 24 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 expectedFundingFees = uint256((FUNDING_FEE_0) * 24 * int256(VOLUME_0) / FEE_MULTIPLIER);

        uint256 expectedLiquidity = (MARGIN_0 - expectedBorrowFees - expectedFundingFees - LIQUIDATOR_REWARD) / 2
            + (expectedBorrowFees) / 2 + uint256(OPEN_POSITION_FEE_0 * 6 / 10) / 2;

        // ASSERT BOB DID NOT GET ANY COLLATERAL
        assertEq(collateral.balanceOf(BOB), 0);
        assertEq(collateral.balanceOf(ALICE), LIQUIDATOR_REWARD, "alice");
        assertEq(collateral.balanceOf(address(tradePair0)), expectedFundingFees, "tradePair");
        assertEq(collateral.balanceOf(address(liquidityPool0)), expectedLiquidity, "lp0");
    }

    // TODO: add more asserts
    function testLiquidationWithProfitCheckFundingFee() public {
        // Case:
        // Pos 1: Liquiditation bc. of fees
        // Pos 2: closed with loss.
        // What happened to the funding fees?
        // ADD LIQUIDITY
        uint256 liquidityAmount = 2_000_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN SHORT POSITION
        vm.warp(1 hours);
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionIdBob = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, true);

        // OPEN LONG POSITION, with 5/2 leverage
        deal(address(collateral), CAROL, INITIAL_BALANCE - OPEN_POSITION_FEE_0 / 2);
        uint256 positionIdCarol = _openPosition(
            CAROL, tradePair0, INITIAL_BALANCE - OPEN_POSITION_FEE_0 / 2, LEVERAGE_MULTIPLIER * 5 / 2, false
        );

        // Increase time by 50 hours and decrease price to 1_600 (pos1 +100% pnl, pos2 -50% pnl)
        vm.warp(50 hours + 1 hours);
        vm.roll(2);
        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);

        // ASSERT BOB'S POSITION IS LIQUIDATABLE
        uint256 expectedBorrowFees = uint256((BASIS_BORROW_FEE_0) * 50 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 expectedFundingFees = uint256((FUNDING_FEE_0) * 50 * int256(VOLUME_0) / FEE_MULTIPLIER);

        // LIQUIDATE BOB'S POSITION
        _liquidatePosition(ALICE, tradePair0, positionIdBob);

        // Now close Carol's position
        _closePosition(CAROL, tradePair0, positionIdCarol, ASSET_PRICE_0_3);

        // ASSERT
        // Carol should have received all the positions equity (minus close fee)
        uint256 expectedBalanceCarol = (MARGIN_0 / 2 - expectedBorrowFees / 2 + expectedFundingFees) * 999 / 1000;
        assertEq(collateral.balanceOf(CAROL), expectedBalanceCarol, "carol");

        assertEq(collateral.balanceOf(address(tradePair0)), 0, "tradePair0");
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
