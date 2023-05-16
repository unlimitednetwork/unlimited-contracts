// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract RemoveMarginE2ETest is WithFullFixtures {
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
        positionId = _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);
    }

    function test_removeMarginSimple() public {
        // Remove Margin
        _removeMarginFromPosition(BOB_PK, tradeManager, tradePair0, positionId, ASSET_PRICE_0, MARGIN_0 / 2);

        assertEq(collateral.balanceOf(address(tradePair0)), MARGIN_0 / 2, "tradePair0");
        assertEq(collateral.balanceOf(BOB), MARGIN_0 / 2, "bob");

        // ASSERT POSITION DETAILS
        assertEq(tradePair0.detailsOfPosition(positionId).margin, MARGIN_0 / 2, "margin");
        assertEq(tradePair0.detailsOfPosition(positionId).leverage, LEVERAGE_0 * 2, "leverage");
        assertEq(tradePair0.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0, "assetAmount");
        assertEq(tradePair0.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0, "entryPrice");
    }

    function testFail_cannotRemoveMarginUnderMinMargin() public {
        // Remove Margin
        _removeMarginFromPosition(
            BOB_PK, tradeManager, tradePair0, positionId, ASSET_PRICE_0, MARGIN_0 - MIN_MARGIN + 1
        );
    }

    function testFail_cannotRemoveMarginUnderMinMargin_AfterFee() public {
        // Remove Margin
        vm.warp(2 hours);
        _removeMarginFromPosition(
            BOB_PK, tradeManager, tradePair0, positionId, ASSET_PRICE_0, MARGIN_0 - MIN_MARGIN - 1
        );
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
