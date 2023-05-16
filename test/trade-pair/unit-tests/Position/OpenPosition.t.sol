// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract OpenPositionTest is Test, WithTradePair {
    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
    }

    function testOpenPosition() public {
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testDetailsOfPosition() public {
        uint256 positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(positionId);
        assertEq(positionDetails.margin, MARGIN_0, "margin");
        assertEq(positionDetails.volume, (MARGIN_0 * LEVERAGE_0) / LEVERAGE_MULTIPLIER, "volume");
        assertEq(positionDetails.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(positionDetails.leverage, LEVERAGE_0, "leverage");
        assertEq(positionDetails.isShort, IS_SHORT_0, "isShort");
        assertEq(positionDetails.entryPrice, ASSET_PRICE_0, "entryPrice");
        assertEq(positionDetails.liquidationPrice, LIQUIDATION_PRICE_0, "liquidationPrice");
        assertEq(positionDetails.currentBorrowFeeAmount, 0, "currentBorrowFeeAmount");
    }

    function testMinLeverage() public {
        vm.expectRevert("TradePair::_verifyLeverage: leverage must be above or equal min leverage");
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, MIN_LEVERAGE - 1, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        // should succeed:
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, MIN_LEVERAGE, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testMaxLeverage() public {
        // Alice needs more collateral, because higher volume means higher open position fee
        deal(address(collateral), address(ALICE), MARGIN_0 * 100);
        collateral.increaseAllowance(address(tradePair), MARGIN_0 * 100);
        vm.expectRevert("TradePair::_verifyLeverage: leverage must be under or equal max leverage");
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, MAX_LEVERAGE + 2, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        // should succeed:
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, MAX_LEVERAGE, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testMinMargin() public {
        vm.expectRevert("TradePair::_openPosition: margin must be above or equal min margin");
        tradePair.openPosition(address(ALICE), MIN_MARGIN - 1, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        // should succeed:
        tradePair.openPosition(address(ALICE), MIN_MARGIN, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testTotalVolumeLimit() public {
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        tradePair.setTotalVolumeLimit(VOLUME_0);
        vm.startPrank(address(mockTradeManager));

        // LONG

        // One position should be fine
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);

        // Opening another position should revert even though it is a short position
        vm.expectRevert("TradePair::_checkTotalVolumeLimitAfter: total volume limit reached by long positions");
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);

        // SHORT

        // One position should be fine
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);

        // Opening another position should revert even though it is a short position
        vm.expectRevert("TradePair::_checkTotalVolumeLimitAfter: total volume limit reached by short positions");
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);
    }

    function testWhiteLabelAddress() public {
        // ARRANGE
        address whitelabel = address(0x123);

        // ACT
        uint256 positionId = tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_1, whitelabel);

        // ASSERT
        assertEq(tradePair.positionIdToWhiteLabel(positionId), whitelabel);
    }
}
