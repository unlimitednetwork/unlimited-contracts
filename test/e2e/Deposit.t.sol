// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract DepositE2ETest is WithFullFixtures {
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
        positionId =
            _openPosition(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, MIN_LEVERAGE, false);
        vm.roll(2);
    }

    function testCannotDecreaseLeverageByDeposit() public {
        // Should revert because the final leverage would under the min leverage
        uint256 addedMargin_ = 1;
        int256 constraintPrice_ = ASSET_PRICE_0;
        uint256 userPrivateKey_ = BOB_PK;

        AddMarginToPositionOrder memory addMarginToPositionOrder = AddMarginToPositionOrder(
            AddMarginToPositionParams(address(tradePair0), positionId, addedMargin_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashAddMarginToPositionOrder(addMarginToPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.startPrank(vm.addr(userPrivateKey_));
        deal(address(collateral), BOB, addedMargin_);
        tradePair0.collateral().approve(address(tradeManager), addedMargin_);
        vm.stopPrank();

        vm.expectRevert("TradePair::_addMarginToPosition: Leverage must be above minLeverage");
        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager).addMarginToPositionViaSignature(
            addMarginToPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
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
