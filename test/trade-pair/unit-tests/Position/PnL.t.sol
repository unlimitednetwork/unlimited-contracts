// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract TradePairPnLTest is Test, WithTradePair {
    function setUp() public {
        deployTradePair();
        dealTokens(address(mockLiquidityPoolAdapter), LIQUIDITY_0);
        vm.startPrank(address(mockTradeManager));
    }

    function testRegisterLossOnClosePosition() public {
        // ARRANGE
        uint256 positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
        assertEq(collateral.balanceOf(address(tradePair)), MARGIN_0, "balance of tradePair == MARGIN_0");

        // ACT

        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_1, ASSET_PRICE_1);
        tradePair.closePosition(address(ALICE), positionId);

        // ASSERT

        assertEq(collateral.balanceOf(ALICE), uint256(EQUITY_0_1) - CLOSE_POSITION_FEE_0_1, "balance of ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), 0, "balance of tradePair == 0");
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + CLOSE_POSITION_FEE_0_1,
            "balance of fee manager"
        );
        assertEq(
            collateral.balanceOf(address(mockLiquidityPoolAdapter)),
            LIQUIDITY_0 - uint256(PNL_0_1),
            "remaining liquidity"
        );
    }

    function testDepositsProfit() public {
        // ARRANGE

        uint256 positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);

        // ACT

        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);
        tradePair.closePosition(address(ALICE), positionId);

        // ASSERT

        assertEq(collateral.balanceOf(ALICE), uint256(EQUITY_0_2) - CLOSE_POSITION_FEE_0_2, "balance of ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), 0, "balance of tradePair == 0");
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + CLOSE_POSITION_FEE_0_2,
            "balance of fee manager"
        );
        assertEq(
            collateral.balanceOf(address(mockLiquidityPoolAdapter)),
            uint256(int256(LIQUIDITY_0) - PNL_0_2),
            "remaining liquidity"
        );
    }

    function testDepositsProfitAfterFullLoss() public {
        // This scenario is an edge case, because the equity of the position
        // is not enough to pay the closing fee.

        // ARRANGE
        uint256 positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);

        // ACT
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        tradePair.closePosition(address(ALICE), positionId);

        // ASSERT
        assertEq(collateral.balanceOf(ALICE), 0, "balance of ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), 0, "balance of tradePair == 0");
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + CLOSE_POSITION_FEE_0_3,
            "balance of fee manager"
        );
        assertEq(
            collateral.balanceOf(address(mockLiquidityPoolAdapter)),
            uint256(int256(LIQUIDITY_0) - PNL_0_3 - int256(CLOSE_POSITION_FEE_0_3)),
            "remaining liquidity"
        );
    }
}
