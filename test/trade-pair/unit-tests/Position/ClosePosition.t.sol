// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract ClosePositionTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.roll(2);
    }

    function testTransfersEquityBack() public {
        tradePair.closePosition(address(ALICE), positionId);
        assertEq(collateral.balanceOf(ALICE), BALANCE_AFTER_CLOSE_0);
    }

    function testResetAllowance() public {
        // ARRANGE
        vm.stopPrank();
        vm.prank(address(tradePair));
        collateral.approve(address(mockFeeManager), 1);

        // ACT
        vm.prank(address(mockTradeManager));
        tradePair.closePosition(address(ALICE), positionId);

        // ASSERT
        assertEq(collateral.allowance(address(tradePair), address(mockFeeManager)), 0);
    }
}
