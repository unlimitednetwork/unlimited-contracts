// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract PositionDetailsTest is WithFullFixtures {
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

    function testTwoPositions() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE * 2);
        uint256 positionId0 = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        uint256 positionId1 = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, true);

        // ASSERT RETURN VALUES
        assertEq(positionId0, 0, "positionId0");
        assertEq(positionId1, 1, "positionId1");
    }

    /* ========== HELPER FUNCTIONS =========== */

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

    function _addMarginToPosition(
        address user,
        ITradePair tradePair,
        uint256 addedMargin,
        uint256 positionId,
        int256 constraintPrice
    ) private prank(user) {
        AddMarginToPositionParams memory addMarginPositionParams =
            AddMarginToPositionParams(address(tradePair), positionId, addedMargin);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), addedMargin);

        tradeManager.addMarginToPosition(addMarginPositionParams, constraints, updateData);
    }

    function _removeMarginFromPosition(
        address user,
        ITradePair tradePair,
        uint256 removedMargin,
        uint256 positionId,
        int256 constraintPrice
    ) private prank(user) {
        RemoveMarginFromPositionParams memory addMarginPositionParams =
            RemoveMarginFromPositionParams(address(tradePair), positionId, removedMargin);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.removeMarginFromPosition(addMarginPositionParams, constraints, updateData);
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
