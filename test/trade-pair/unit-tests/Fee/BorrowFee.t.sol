// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract FundingFeeTest is Test, WithTradePair {
    int256 constant TOTAL_FEE_AMOUNT_AFTER_1H = (BASIS_BORROW_FEE_0 + FUNDING_FEE_0) * int256(VOLUME_0) / FEE_MULTIPLIER;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
    }

    function testTotalLongVolume() public {
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        (, uint256 totalLongVolume,,,,) = tradePair.positionStats();
        assertEq(totalLongVolume, VOLUME_0);
    }

    function testUpdatedAt() public {
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        (,,,,,, uint256 lastUpdatedAt) = tradePair.feeIntegral();

        assertEq(lastUpdatedAt, block.timestamp);
    }

    function testPositionFeeSinceLastCollection() public {
        vm.warp(0);
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.warp(1 hours);
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(0);
        assertEq(uint256(positionDetails.equity), MARGIN_0 - uint256(TOTAL_FEE_AMOUNT_AFTER_1H));
    }

    function testPositionFeeWithCollection() public {
        vm.warp(0);
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        vm.warp(1 hours);

        dealTokens(address(ALICE), INITIAL_BALANCE);
        // fees get collected every position alteration
        tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(0);
        assertEq(uint256(positionDetails.equity), MARGIN_0 - uint256(TOTAL_FEE_AMOUNT_AFTER_1H));
    }
}
