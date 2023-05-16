// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract TradePairLiquidatePositionTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        dealTokens(address(mockLiquidityPoolAdapter), LIQUIDITY_0);
        vm.startPrank(address(mockTradeManager));
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
    }

    function testPositionIsLiquidatable() public {
        assertEq(tradePair.positionIsLiquidatable(positionId), false);
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        assertEq(tradePair.positionIsLiquidatable(positionId), true);
    }

    function testRevertsWhenPositionIsNotLiquidatable() public {
        vm.expectRevert("TradePair::onlyLiquidatable: position is not liquidatable");
        tradePair.liquidatePosition(address(BOB), positionId);
    }

    function testLiquidatesPosition() public {
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        tradePair.liquidatePosition(address(BOB), positionId);
        vm.expectRevert("TradePair::_positionIsLiquidatable: position does not exist");
        tradePair.liquidatePosition(address(BOB), positionId);
        vm.expectRevert("TradePair::_positionIsLiquidatable: position does not exist");
        tradePair.positionIsLiquidatable(positionId);
    }

    function testReveivesLiquidatorReward() public {
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        tradePair.liquidatePosition(address(BOB), positionId);
        assertEq(collateral.balanceOf(BOB), LIQUIDATOR_REWARD);
    }

    function testProfitIsDecreasedWhenLiquidatingPosition() public {
        // Price 1_600, so position is 100% in loss
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);

        tradePair.liquidatePosition(address(BOB), positionId);

        assertEq(collateral.balanceOf(address(tradePair)), 0, "tradePair");
        assertEq(collateral.balanceOf(address(ALICE)), 0, "ALICE");
        assertEq(collateral.balanceOf(BOB), LIQUIDATOR_REWARD, "BOB");
        assertEq(collateral.balanceOf(address(mockFeeManager)), OPEN_POSITION_FEE_0, "mockFeeManager");
        assertEq(
            collateral.balanceOf(address(mockLiquidityPoolAdapter)), LIQUIDITY_0 + MARGIN_0 - LIQUIDATOR_REWARD, "LP"
        );
    }

    function testFeeShouldGetCollectedCorrectly() public {
        // Margin is used up 100% by the total fee.
        // Liquidator reward is taken from the LP and transfered to the liquidator.
        // Borrow Fee is collected by the FeeManager.
        // Funding fee stays at the TradePair.

        // 50 * (0.1% + 0.3%) = 20%; 20% of volume (100% of margin)
        vm.warp(50 hours);
        // Make sure that margin is equal to the total fee amounts.
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(
            positionDetails.currentBorrowFeeAmount + positionDetails.currentFundingFeeAmount,
            int256(MARGIN_0),
            "totalFeeAmount"
        );

        // Liquidate
        tradePair.liquidatePosition(address(BOB), positionId);

        // Check balances
        assertEq(collateral.balanceOf(address(tradePair)), MARGIN_0 * 3 / 4, "tradePair");
        assertEq(collateral.balanceOf(address(ALICE)), 0, "ALICE");
        assertEq(collateral.balanceOf(BOB), LIQUIDATOR_REWARD, "BOB");
        // FeeManager received the openPositionFee, and 25% of the margin (the other 75% is funding fee
        // and stays at the TradePair) but lost the liquidator award
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + MARGIN_0 / 4 - LIQUIDATOR_REWARD,
            "mockFeeManager"
        );
        assertEq(collateral.balanceOf(address(mockLiquidityPoolAdapter)), LIQUIDITY_0, "LP");
    }

    function testOnlyTradeManagerCanLiquidatePosition() public {
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);
        vm.stopPrank();
        vm.expectRevert("TradePair::_onlyTradeManager: only TradeManager");
        tradePair.liquidatePosition(address(BOB), positionId);
    }

    function testPositionWitFeeOverCollection() public {
        // column N
        // Price is 1_800, so position is 50% in loss
        // Time is passed by 100 hours, so the total fee is: 100 * (0.1% + 0.3%) = 40%
        // 40% of volume is 200% of margin, so massively over collected
        // This overcollected fee should be registered in the TradePair and requested as loss by LP.
        uint256 OVERCOLLECTED_FEE = VOLUME_0 * 4 / 10 - MARGIN_0;
        // Fee Buffer is 25% of the borrow fee
        uint256 BUFFER = uint256(VOLUME_0 * 1 / 10) * 25 / 100;

        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);
        vm.warp(ELAPSED_TIME_0_2_3); // 100 hours
        tradePair.liquidatePosition(address(BOB), positionId);
        assertEq(collateral.balanceOf(address(ALICE)), 0, "ALICE should have lost all margin");
        assertEq(
            collateral.balanceOf(address(tradePair)),
            VOLUME_0 * 3 / 10,
            "tradePair should have 30% of VOLUME_0 from funding fee"
        );
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + uint256(VOLUME_0 * 1 / 10) - BUFFER,
            "mockFeeManager should have the openPositionFee and the borrow fee amount minus buffer and liquidator reward"
        );
        assertEq(
            collateral.balanceOf(address(mockLiquidityPoolAdapter)),
            LIQUIDITY_0 - (OVERCOLLECTED_FEE - BUFFER) - LIQUIDATOR_REWARD,
            "LP should have payed the (overcollected fee minus buffer) and the liquidator reward"
        );
    }
}
