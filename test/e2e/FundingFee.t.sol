// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract FundingFeeE2ETest is WithFullFixtures {
    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

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
    }

    function testTwoPositionsEqualEachOtherOut() public {
        vm.warp(1 hours);

        // ARRANGE
        // OPEN POSITIONS, LONG and SHORT
        uint256 positionIdAlice =
            _openPosition2(ALICE_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, false);
        uint256 positionIdBob =
            _openPosition2(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, true);

        // ACT
        vm.warp(101 hours);

        _closePosition(ALICE_PK, tradeManager, tradePair0, positionIdAlice, ASSET_PRICE_0);
        _closePosition(BOB_PK, tradeManager, tradePair0, positionIdBob, ASSET_PRICE_0);

        // ASSERT
        // Only borrow fee should have been applied
        uint256 borrowFeeAmount = uint256(BASIS_BORROW_FEE_0) * 100 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 finalBalance = (MARGIN_0 - borrowFeeAmount) - CLOSE_POSITION_FEE_0; // deduce closeFee
        assertEq(collateral.balanceOf(ALICE), finalBalance);
        assertEq(collateral.balanceOf(BOB), finalBalance);
    }

    function testInbalancePositionsPayEachOther() public {
        vm.warp(1 hours);

        // ARRANGE
        // OPEN POSITIONS, LONG pays SHORT
        uint256 positionIdAlice =
            _openPosition2(ALICE_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE, LEVERAGE_0, false);
        uint256 positionIdBob =
            _openPosition2(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE / 10, LEVERAGE_0, true);

        // ACT
        vm.warp(11 hours);

        _closePosition(ALICE_PK, tradeManager, tradePair0, positionIdAlice, ASSET_PRICE_0);
        _closePosition(BOB_PK, tradeManager, tradePair0, positionIdBob, ASSET_PRICE_0);

        // ASSERT
        // Only borrow fee should have been applied
        uint256 borrowFeeAmount = uint256(BASIS_BORROW_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 fundingFeeAmount = uint256(FUNDING_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 finalBalanceAlice = (MARGIN_0 - borrowFeeAmount - fundingFeeAmount) - CLOSE_POSITION_FEE_0; // deduce closeFee
        uint256 finalBalanceBob = (MARGIN_0 / 10 - borrowFeeAmount / 10 + fundingFeeAmount) - CLOSE_POSITION_FEE_0 / 10; // deduce closeFee
        assertEq(collateral.balanceOf(ALICE), finalBalanceAlice, "alice");
        assertEq(collateral.balanceOf(BOB), finalBalanceBob, "bob");
    }

    function testInbalancePositionsPayEachOtherMultiple() public {
        vm.warp(1 hours);

        // ARRANGE
        // OPEN POSITIONS, LONG pays SHORT
        uint256 positionIdAlice1 =
            _openPosition2(ALICE_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE / 2, LEVERAGE_0, false);
        uint256 positionIdAlice2 =
            _openPosition2(ALICE_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE / 2, LEVERAGE_0, false);
        uint256 positionIdBob =
            _openPosition2(BOB_PK, tradeManager, tradePair0, ASSET_PRICE_0, INITIAL_BALANCE / 10, LEVERAGE_0, true);

        // ACT
        vm.warp(11 hours);

        _closePosition(ALICE_PK, tradeManager, tradePair0, positionIdAlice1, ASSET_PRICE_0);
        _closePosition(ALICE_PK, tradeManager, tradePair0, positionIdAlice2, ASSET_PRICE_0);
        _closePosition(BOB_PK, tradeManager, tradePair0, positionIdBob, ASSET_PRICE_0);

        // ASSERT
        // Only borrow fee should have been applied
        uint256 borrowFeeAmount = uint256(BASIS_BORROW_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 fundingFeeAmount = uint256(FUNDING_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 finalBalanceAlice = (MARGIN_0 - borrowFeeAmount - fundingFeeAmount) - CLOSE_POSITION_FEE_0; // deduce closeFee
        uint256 finalBalanceBob = (MARGIN_0 / 10 - borrowFeeAmount / 10 + fundingFeeAmount) - CLOSE_POSITION_FEE_0 / 10; // deduce closeFee
        assertEq(collateral.balanceOf(ALICE), finalBalanceAlice, "alice");
        assertEq(collateral.balanceOf(BOB), finalBalanceBob, "bob");
    }

    /* ========== HELPER FUNCTIONS =========== */

    function _changePrice(int256 price) internal {
        priceFeedAdapter.setMarkPrices(price, price);
    }

    function _depositLiquidity(ILiquidityPool liquidityPool, address user, uint256 amount)
        private
        prank(user)
        returns (uint256 shares)
    {
        collateral.approve(address(liquidityPool), amount);
        shares = liquidityPool.deposit(amount, 0);
    }
}
