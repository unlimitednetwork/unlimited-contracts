// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract BufferTest is Test, WithTradePair {
    int256 constant BORROW_FEE_AMOUNT_AFTER_1H = BASIS_BORROW_FEE_0 * int256(VOLUME_0) / FEE_MULTIPLIER;
    int256 constant BUFFER_AFTER_1H = BORROW_FEE_AMOUNT_AFTER_1H * BUFFER_FACTOR / BUFFER_MULTIPLIER;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
    }

    function testFillsBuffer() public {
        // ARRANGE
        vm.warp(0);
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, address(0));

        // ACT
        vm.warp(1 hours);
        tradePair.syncPositionFees();

        // ASSERT
        (int256 bufferAmount,) = tradePair.feeBuffer();
        // Buffer should be filled with 25% of the borrow fee
        assertEq(bufferAmount, BUFFER_AFTER_1H);
    }

    function testShouldEmptyBuffer() public {
        // ARRANGE
        vm.warp(0);
        uint256 positionId = tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, address(0));

        // ACT
        vm.warp(1 hours);
        vm.roll(2);
        tradePair.syncPositionFees();
        tradePair.closePosition(address(ALICE), positionId);

        // ASSERT
        (int256 bufferAmount,) = tradePair.feeBuffer();
        assertEq(bufferAmount, 0);
    }
}
