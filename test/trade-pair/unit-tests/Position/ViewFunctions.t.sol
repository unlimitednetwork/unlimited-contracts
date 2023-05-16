// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract TradePairViewFunctionsTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();

        vm.startPrank(address(mockTradeManager));
        vm.warp(0);
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testDetailsOfPosition() public {
        // ACT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);

        // ASSERT
        assertEq(positionDetails.margin, MARGIN_0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, LEVERAGE_0, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, LIQUIDATION_PRICE_0, "liquidationPrice");
    }

    function testChangesWhenPriceChanges2() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);

        // ACT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);

        // ARRANGE
        assertEq(positionDetails.margin, MARGIN_0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, LEVERAGE_0, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, LIQUIDATION_PRICE_0, "liquidationPrice");
    }

    function testChangesWhenPriceChanges1() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_1, ASSET_PRICE_1);

        // ACT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);

        // ASSERT
        assertEq(positionDetails.margin, MARGIN_0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, LEVERAGE_0, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, LIQUIDATION_PRICE_0, "liquidationPrice");
    }

    function testChangesWhenPriceChangedAndTimeElapsed() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);

        // ACT
        vm.warp(ELAPSED_TIME_0_2_2);

        // ASSERT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(positionDetails.margin, NET_MARGIN_0_2_2, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, NET_LEVERAGE_0_2_2, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(
            positionDetails.currentBorrowFeeAmount + positionDetails.currentFundingFeeAmount,
            int256(TOTAL_FEE_AMOUNT_0_2_2),
            "totalFeeAmount"
        );
    }

    function testChangedPriceAndOverFee() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);

        // ACT
        vm.warp(ELAPSED_TIME_0_2_3);

        // ASSERT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(positionDetails.margin, 0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, type(uint256).max, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, ASSET_PRICE_0, "liquidationPrice");
        assertEq(
            positionDetails.currentBorrowFeeAmount + positionDetails.currentFundingFeeAmount,
            int256(TOTAL_FEE_AMOUNT_0_2_3),
            "totalFeeAmount"
        );
    }

    function testChangedPriceAndNonCoveredFee() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);

        // ACT
        vm.warp(ELAPSED_TIME_0_2_4);

        // ASSERT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(positionDetails.margin, 0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, type(uint256).max, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, ASSET_PRICE_0, "liquidationPrice");
        assertEq(
            positionDetails.currentBorrowFeeAmount + positionDetails.currentFundingFeeAmount,
            int256(TOTAL_FEE_AMOUNT_0_2_4),
            "totalFeeAmount"
        );
        assertEq(positionDetails.currentBorrowFeeAmount, int256(TOTAL_FEE_AMOUNT_0_2_4 / 4), "borrowFeeAmount");
        assertEq(positionDetails.currentFundingFeeAmount, int256(TOTAL_FEE_AMOUNT_0_2_4 * 3 / 4), "fundingFeeAmount");
    }

    function testProfitAndNonCoveredFee() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_1, ASSET_PRICE_1);

        // ACT
        vm.warp(ELAPSED_TIME_0_2_4);

        // ASSERT
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(positionDetails.margin, 0, "margin");
        assertEq(positionDetails.volume, VOLUME_0, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, type(uint256).max, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, ASSET_PRICE_0, "liquidationPrice");
        assertEq(
            positionDetails.currentBorrowFeeAmount + positionDetails.currentFundingFeeAmount,
            int256(TOTAL_FEE_AMOUNT_0_2_4),
            "totalFeeAmount"
        );
    }
}
