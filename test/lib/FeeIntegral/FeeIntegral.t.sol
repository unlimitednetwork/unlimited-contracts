// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FeeIntegral.sol";

using FeeIntegralLib for FeeIntegral;

contract FeeIntegralTest is Test {
    int256 constant BORROW_FEE = 10 * FEE_BPS_MULTIPLIER;
    int256 constant FUNDING_FEE = 30 * FEE_BPS_MULTIPLIER;
    int256 constant MAX_EXCESS_RATIO = 2 * FEE_MULTIPLIER;
    FeeIntegral feeIntegral;

    function setUp() public {
        // set borrow fee rate to 0.1%
        feeIntegral.borrowFeeRate = BORROW_FEE;
        // set funding fee rate to 0.3%
        feeIntegral.fundingFeeRate = FUNDING_FEE;
        // set max excess ratio to 2
        feeIntegral.maxExcessRatio = MAX_EXCESS_RATIO;
    }

    function testAddsBorrowFeeIntegral() public {
        vm.warp(0);
        assertEq(feeIntegral.borrowFeeIntegral, 0);
        vm.warp(7 hours);
        feeIntegral.update(0, 0);
        assertEq(feeIntegral.borrowFeeIntegral, BORROW_FEE * 7);
    }

    function testAddsFundingFeeIntegrals() public {
        vm.warp(0);
        assertEq(feeIntegral.longFundingFeeIntegral, 0);
        feeIntegral.update(1_000, 2_000);
        assertEq(feeIntegral.longFundingFeeIntegral, 0);
        vm.warp(7 hours);
        feeIntegral.update(1_000, 2_000);
        assertEq(feeIntegral.longFundingFeeIntegral, -2 * FUNDING_FEE * 7, "long funding fee integral");
        assertEq(feeIntegral.shortFundingFeeIntegral, FUNDING_FEE * 7, "short funding fee integral");
    }

    function testGetCurrentFundingFeeIntegrals() public {
        vm.warp(0);
        vm.warp(7 hours);
        feeIntegral.update(1_000, 2_000);
        vm.warp(14 hours);
        (int256 _longFeeIntegral, int256 _shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(1_000, 2_000);

        assertEq(_longFeeIntegral, -2 * FUNDING_FEE * 14);
        assertEq(_shortFeeIntegral, FUNDING_FEE * 14);
    }

    function testGetCurrentFundingFeeIntegralsWhenShortIsZero() public {
        vm.warp(0);
        vm.warp(7 hours);
        (int256 _longFeeIntegral, int256 _shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(1_000, 0);

        assertEq(_longFeeIntegral, FUNDING_FEE * 7, "long funding fee integral");
        assertEq(_shortFeeIntegral, 0, "short funding fee integral");
    }

    function testGetCurrentFundingFeeIntegralsWhenLongIsZero() public {
        vm.warp(7 hours);
        (int256 _longFeeIntegral, int256 _shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(0, 1_000);

        assertEq(_longFeeIntegral, 0);
        assertEq(_shortFeeIntegral, FUNDING_FEE * 7);
    }

    function testGetCurrentFundingFeeIntegralsHistorical() public {
        // Two periods with 7 hours each, in wich one of the positions is zero
        vm.warp(7 hours);
        feeIntegral.update(0, 2_000);
        vm.warp(14 hours);
        (int256 _longFeeIntegral, int256 _shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(1_000, 0);

        assertEq(_longFeeIntegral, FUNDING_FEE * 7);
        assertEq(_shortFeeIntegral, FUNDING_FEE * 7);
    }

    function testGetCurrentFundingFeeRates() public {
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = feeIntegral.getCurrentFundingFeeRates(1_000, 1_000);
        assertEq(longFundingFeeRate, 0, "1. long should be zero");
        assertEq(shortFundingFeeRate, 0, "2. short should be zero");
        (int256 longFundingFeeRate_2, int256 shortFundingFeeRate_2) = feeIntegral.getCurrentFundingFeeRates(1_000, 100);
        assertEq(longFundingFeeRate_2, FUNDING_FEE, "2. long should be 0.3%");
        assertEq(shortFundingFeeRate_2, -10 * FUNDING_FEE, "2. short should be -3%");
    }
}
