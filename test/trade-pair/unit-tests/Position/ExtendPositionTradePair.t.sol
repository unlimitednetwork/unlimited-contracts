// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract ExtendPositionTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0, ASSET_PRICE_0);

        vm.startPrank(address(mockTradeManager));
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
    }

    function testExtendPosition() public {
        // ACT
        tradePair.extendPosition(ALICE, positionId, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).margin, MARGIN_0 * 2, "margin");
        assertEq(tradePair.detailsOfPosition(positionId).leverage, LEVERAGE_0, "leverage");
        assertEq(tradePair.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0, "entryPrice");
    }

    function testExtendPositionShort() public {
        // ARRANGE
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);
        vm.roll(3);

        // ACT
        tradePair.extendPosition(ALICE, positionId, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).margin, MARGIN_0 * 2, "margin");
        assertEq(tradePair.detailsOfPosition(positionId).leverage, LEVERAGE_0, "leverage");
        assertEq(tradePair.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0, "entryPrice");
    }

    function testTransfersFee() public {
        // ACT
        tradePair.extendPosition(ALICE, positionId, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0 * 2, "size");
        assertEq(collateral.balanceOf(address(mockFeeManager)), OPEN_POSITION_FEE_0 * 2);
    }

    function testWithPriceChange() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0 * 2, ASSET_PRICE_0 * 2);

        // ACT
        tradePair.extendPosition(ALICE, positionId, INITIAL_BALANCE, LEVERAGE_0);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).margin, MARGIN_0 * 2);
        assertEq(tradePair.detailsOfPosition(positionId).leverage, LEVERAGE_0);

        assertEq(tradePair.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0 * 3 / 2, "size");
        assertEq(tradePair.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0 * 4 / 3);
    }

    function testWithLeverageChange() public {
        // ARRANGE
        uint256 margin = INITIAL_BALANCE + OPEN_POSITION_FEE_0;
        dealTokens(address(tradePair), margin);

        // ACT
        tradePair.extendPosition(ALICE, positionId, margin, LEVERAGE_0 * 2);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).margin, MARGIN_0 * 2, "margin");
        assertEq(tradePair.detailsOfPosition(positionId).leverage, LEVERAGE_0 * 3 / 2, "leverage");

        assertEq(tradePair.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0 * 3, "size");
        assertEq(tradePair.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0, "entryPrice");
    }

    function testWithPriceChangeAndLeverageChange() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0 * 2, ASSET_PRICE_0 * 2);
        uint256 margin = INITIAL_BALANCE + OPEN_POSITION_FEE_0;
        dealTokens(address(tradePair), margin);

        // ACT
        tradePair.extendPosition(ALICE, positionId, margin, LEVERAGE_0 * 2);

        // ASSERT
        assertEq(tradePair.detailsOfPosition(positionId).margin, MARGIN_0 * 2, "margin");
        assertEq(tradePair.detailsOfPosition(positionId).leverage, LEVERAGE_0 * 3 / 2, "leverage");

        assertEq(tradePair.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0 * 2, "size");
        assertEq(tradePair.detailsOfPosition(positionId).entryPrice, ASSET_PRICE_0 * 3 / 2, "entryPrice");
    }

    function testExtendPositionToLeverage() public {
        // ARRANGE
        uint256 doubleLeverage = LEVERAGE_0 * 2;
        uint256 referencePositionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, doubleLeverage, IS_SHORT_0, WHITELABEL_ADDRESS_0);

        // ACT
        tradePair.extendPositionToLeverage(ALICE, positionId, doubleLeverage);

        // ASSERT
        assertEq(
            tradePair.detailsOfPosition(positionId).margin,
            tradePair.detailsOfPosition(referencePositionId).margin,
            "margin"
        );
        assertEq(
            tradePair.detailsOfPosition(positionId).volume,
            tradePair.detailsOfPosition(referencePositionId).volume,
            "volume"
        );
        assertEq(tradePair.detailsOfPosition(positionId).leverage, doubleLeverage, "leverage");
    }

    function testFeePayment() public {
        // ARRANGE
        uint256 doubleLeverage = LEVERAGE_0 * 2;
        tradePair.extendPositionToLeverage(ALICE, positionId, doubleLeverage);
        uint256 feeAmount1 = collateral.balanceOf(address(mockFeeManager));

        // ACT
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, doubleLeverage, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        uint256 feeAmount2 = collateral.balanceOf(address(mockFeeManager));

        // ASSERT
        assertEq(feeAmount1 * 2, feeAmount2, "fee");
    }
}
