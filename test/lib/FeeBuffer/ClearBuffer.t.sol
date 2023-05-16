// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FeeBuffer.sol";

using FeeBufferLib for FeeBuffer;

contract ClearBufferTest is Test {
    int256 constant BUFFER_FACTOR = 250_000; // 25%
    FeeBuffer feeBuffer;

    function setUp() public {
        // set buffer factor to 25%
        feeBuffer.bufferFactor = BUFFER_FACTOR;
    }

    function testClearBufferOvercollection() public {
        // column B
        feeBuffer.currentBufferAmount = 75;

        (uint256 remainingMargin, uint256 transferToFeeManager, uint256 requestLoss) =
            feeBuffer.clearBuffer(1000, 300, 900);

        assertEq(remainingMargin, 0, "remainingMargin");
        assertEq(transferToFeeManager, 0, "transferToFeeManager");
        assertEq(requestLoss, 125, "requestLoss");
        assertEq(feeBuffer.currentBufferAmount, 0, "currentBufferAmount");
    }

    function testClearBufferOvercollected2() public {
        // column D
        feeBuffer.currentBufferAmount = 75;

        (uint256 remainingMargin, uint256 transferToFeeManager, uint256 requestLoss) =
            feeBuffer.clearBuffer(1000, 300, 750);

        assertEq(remainingMargin, 0, "remainingMargin");
        assertEq(transferToFeeManager, 25, "transferToFeeManager");
        assertEq(requestLoss, 0, "requestLoss");
        assertEq(feeBuffer.currentBufferAmount, 0, "currentBufferAmount");
    }

    function testClearBufferOvercollected3() public {
        // column E
        feeBuffer.currentBufferAmount = 200;

        (uint256 remainingMargin, uint256 transferToFeeManager, uint256 requestLoss) =
            feeBuffer.clearBuffer(1000, 800, 400);

        assertEq(remainingMargin, 0, "remainingMargin");
        assertEq(transferToFeeManager, 0, "transferToFeeManager");
        assertEq(requestLoss, 0, "requestLoss");
        assertEq(feeBuffer.currentBufferAmount, 0, "currentBufferAmount");
    }

    function testClearBuffer() public {
        // column i
        feeBuffer.currentBufferAmount = 25;

        (uint256 remainingMargin, uint256 transferToFeeManager, uint256 requestLoss) =
            feeBuffer.clearBuffer(1000, 100, 200);

        assertEq(remainingMargin, 700, "remainingMargin");
        assertEq(transferToFeeManager, 25, "transferToFeeManager");
        assertEq(requestLoss, 0, "requestLoss");
        assertEq(feeBuffer.currentBufferAmount, 0, "currentBufferAmount");
    }
}
