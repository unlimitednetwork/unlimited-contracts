// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract PartiallyClosePositionTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
    }

    function testPartiallyClosesPositionTakeProfit() public {
        tradePair.partiallyClosePosition(address(ALICE), positionId, CLOSE_PROPORTION_1);
    }

    function testPartiallyCloseRevertsWhenNotTheOwner() public {
        vm.expectRevert("TradePair::_verifyOwner: not the owner");
        tradePair.partiallyClosePosition(address(BOB), positionId, CLOSE_PROPORTION_1);
    }

    function testPartiallyCloseAndReceivePayout() public {
        assertEq(collateral.balanceOf(ALICE), 0);
        tradePair.partiallyClosePosition(address(ALICE), positionId, CLOSE_PROPORTION_1);
        assertEq(collateral.balanceOf(ALICE), MARGIN_0 / 2 - CLOSE_POSITION_FEE_0 / 2, "ALICE");
        assertEq(collateral.balanceOf(address(tradePair)), MARGIN_0 / 2, "tradePair");
        assertEq(
            collateral.balanceOf(address(mockFeeManager)),
            OPEN_POSITION_FEE_0 + CLOSE_POSITION_FEE_0 / 2,
            "mockFeeManager"
        );
    }
}
