// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract FundingFeeTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
    }

    function testCalculatesDefaultFundingFeeRates() public {
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, 0, "1. long funding fee rate should be 0");
        assertEq(shortFundingFeeRate, 0, "1. short funding fee rate should be 0");
    }

    function testFundingFeeLongSurplusNoShort() public {
        // Open position. Long: 100, Short: 0
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 10, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, FUNDING_FEE_0, "long funding fee rate should be 0.3%");
        assertEq(shortFundingFeeRate, 0, "short funding fee rate should be 0 (no volume)");
    }

    function testFundingFeeShortSurplusNoLong() public {
        // Open position. Long: 0, Short: 100
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 10, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, 0, "long funding fee rate should be 0 (no volume)");
        assertEq(shortFundingFeeRate, FUNDING_FEE_0, "short funding fee rate should be 0.3%");
    }

    function testFundingFeeLongMaxSurplus() public {
        // Open position. Long: 100, Short: 10
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 10, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 100, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, FUNDING_FEE_0, "long funding fee rate should be 0.3%");
        assertEq(shortFundingFeeRate, -10 * FUNDING_FEE_0, "short funding fee rate should be -3%");
    }

    function testFundingFeeShortMaxSurplus() public {
        // Open position. Long: 10, Short: 100
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 100, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE / 10, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0);
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, -10 * FUNDING_FEE_0, "long funding fee rate should be -3%");
        assertEq(shortFundingFeeRate, FUNDING_FEE_0, "short funding fee rate should be 0.3%");
    }

    function testFundingFeeLongSurplus() public {
        // Open position. Long: 60, Short: 40
        positionId = tradePair.openPosition(
            address(ALICE), INITIAL_BALANCE * 6 / 10, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0
        );
        positionId = tradePair.openPosition(
            address(ALICE), INITIAL_BALANCE * 4 / 10, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0
        );
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, FUNDING_FEE_0 / 2, "long funding fee rate should be 0.3%");
        assertEq(shortFundingFeeRate, -3 * FUNDING_FEE_0 / 4, "short funding fee rate should be -2.25%");
    }

    function testFundingFeeShortSurplus() public {
        // Open position. Long: 40, Short: 60
        positionId = tradePair.openPosition(
            address(ALICE), INITIAL_BALANCE * 4 / 10, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0
        );
        positionId = tradePair.openPosition(
            address(ALICE), INITIAL_BALANCE * 6 / 10, LEVERAGE_0, IS_SHORT_1, WHITELABEL_ADDRESS_0
        );
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) = tradePair.getCurrentFundingFeeRates();
        assertEq(longFundingFeeRate, -3 * FUNDING_FEE_0 / 4, "long funding fee rate should be -2.25%");
        assertEq(shortFundingFeeRate, FUNDING_FEE_0 / 2, "short funding fee rate should be 0.3%");
    }
}
