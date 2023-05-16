// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract TradePairChangeMarginTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));

        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
    }

    function testRemoveMarginAndReceivePayout() public {
        assertEq(collateral.balanceOf(ALICE), 0);
        tradePair.removeMarginFromPosition(address(ALICE), positionId, MARGIN_0 / 2);
        assertEq(collateral.balanceOf(ALICE), MARGIN_0 / 2 - MARGIN_0 / 2 * BASE_USER_FEE / BPS_MULTIPLIER, "ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), MARGIN_0 / 2, "tradePair");
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + MARGIN_0 / 2 * BASE_USER_FEE / BPS_MULTIPLIER,
            "mockFeeManager"
        );
    }

    function testAddMargin() public {
        // ARRANGE
        // TradeManager would transfer margin, so we have to do it here 2x margin, from open and from adding margin
        deal(address(collateral), address(tradePair), MARGIN_0 * 2);

        // ACT
        // transfer margin + 20% of open fee (no leverage here)
        tradePair.addMarginToPosition(address(ALICE), positionId, MARGIN_0 + OPEN_POSITION_FEE_0 / 5);
        uint256 ADD_MARGIN_FEE = MARGIN_0 * uint256(BASIS_BORROW_FEE_0) / uint256(FEE_MULTIPLIER);

        // ASSERT
        assertEq(collateral.balanceOf(ALICE), 0, "ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), MARGIN_0 * 2 - ADD_MARGIN_FEE, "tradePair");
        assertEq(collateral.balanceOf(address(mockFeeManager)), OPEN_POSITION_FEE_0 + ADD_MARGIN_FEE, "mockFeeManager");
    }
}
