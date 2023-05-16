// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FeeBuffer.sol";

using FeeBufferLib for FeeBuffer;

contract TakeBufferTest is Test {
    int256 constant BUFFER_FACTOR = 250_000; // 25%
    FeeBuffer feeBuffer;

    function setUp() public {
        // set buffer factor to 25%
        feeBuffer.bufferFactor = BUFFER_FACTOR;
    }

    function testTakeBuffer() public {
        feeBuffer.takeBufferFrom(1000);
        assertEq(feeBuffer.currentBufferAmount, 250, "currentBufferAmount");
    }

    function testTakeBufferTwice() public {
        feeBuffer.takeBufferFrom(1000);
        feeBuffer.takeBufferFrom(2000);
        assertEq(feeBuffer.currentBufferAmount, 750, "currentBufferAmount");
    }
}
