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
        uint256 positionId0 =
            _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, false);
        uint256 positionId1 =
            _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, true);

        // ASSERT RETURN VALUES
        assertEq(positionId0, 0, "positionId0");
        assertEq(positionId1, 1, "positionId1");
    }

    function test_ZeroBorrowFee() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        tradePair0.setBorrowFeeRate(0);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE * 2);
        uint256 positionId0 =
            _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, false);
        uint256 positionId1 =
            _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, true);

        vm.warp(100 days);

        // As borrow fee rate is 0 and funding LONG and SHORT are in balance, then totalFeeAmount should be 0

        PositionDetails memory position1 = tradePair0.detailsOfPosition(positionId0);
        PositionDetails memory position2 = tradePair0.detailsOfPosition(positionId1);

        // ASSERT RETURN VALUES
        assertEq(position1.currentBorrowFeeAmount, 0, "positionId0");
        assertEq(position2.currentBorrowFeeAmount, 0, "positionId1");
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
