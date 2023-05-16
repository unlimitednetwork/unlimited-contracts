// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract WithdrawE2ETest is WithFullFixtures {
    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

    uint256 positionId;
    uint256 liquidityAmount;

    function setUp() public {
        vm.warp(0);
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

    function testCannotExceedMaxLeverage() public {
        // Should revert because the final leverage would be above the max leverage
        uint256 removedMargin_ = MARGIN_0 * 99 / 100;
        int256 constraintPrice_ = ASSET_PRICE_0;
        uint256 userPrivateKey_ = BOB_PK;

        RemoveMarginFromPositionOrder memory removeMarginFromPositionOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(tradePair0), positionId, removedMargin_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashRemoveMarginFromPositionOrder(removeMarginFromPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.expectRevert("TradePair::_verifyLeverage: leverage must be under or equal max leverage");
        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager).removeMarginFromPositionViaSignature(
            removeMarginFromPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function testCannotExceedMaxLeverageDueToFee() public {
        // Should revert because the final leverage would be above the max leverage
        // This time because of the price change, not because of the margin change
        uint256 removedMargin_ = MARGIN_0 * 16 / 100;
        int256 constraintPrice_ = ASSET_PRICE_0;
        uint256 userPrivateKey_ = BOB_PK;

        vm.warp(40 hours); // removes 80% of margin, bring leverage to 25

        // removing another 16% of margin should bring leverage to above 100x

        RemoveMarginFromPositionOrder memory removeMarginFromPositionOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(tradePair0), positionId, removedMargin_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashRemoveMarginFromPositionOrder(removeMarginFromPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.expectRevert("TradePair::_verifyLeverage: leverage must be under or equal max leverage");
        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager).removeMarginFromPositionViaSignature(
            removeMarginFromPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
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
