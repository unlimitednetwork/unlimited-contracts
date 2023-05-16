// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";
import "test/setup/WithPositionMaths.t.sol";

contract PartiallyCloseShortPositionTest is Test, WithPositionMaths {
    using PositionMaths for Position;

    function setUp() public {
        vm.warp(0);
        position = Position({
            margin: MARGIN_0,
            volume: VOLUME_0,
            assetAmount: ASSET_AMOUNT_0,
            pastBorrowFeeIntegral: 0,
            lastBorrowFeeAmount: 0,
            pastFundingFeeIntegral: 0,
            lastFundingFeeAmount: 0,
            collectedFundingFeeAmount: 0,
            collectedBorrowFeeAmount: 0,
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: IS_SHORT_1,
            owner: msg.sender,
            lastAlterationBlock: uint40(block.number)
        });
        position.updateFees(0, 0);
    }

    function testPartiallyCloseSimple() public {
        int256 payout = position.partiallyClose(ASSET_PRICE_0, CLOSE_PROPORTION_1);
        assertEq(position.margin, MARGIN_0 / 2, "margin");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 / 2, "size");
        assertEq(payout, int256(MARGIN_0 / 2), "payout");
        assertEq(position.volume, VOLUME_0 / 2, "volume");
    }

    function testCannotPartiallyCloseFullPosition() public {
        vm.expectRevert("PositionMaths::_partiallyClose: cannot partially close full position");
        position.partiallyClose(
            ASSET_PRICE_0,
            PERCENTAGE_MULTIPLIER // trying to close 100%
        );
    }

    function testChangeFeeOnPartiallyClose() public {
        int256 oldFee = position.currentTotalFeeAmount(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        int256 expectedFee = oldFee * int256(CLOSE_PROPORTION_1) / int256(PERCENTAGE_MULTIPLIER);

        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        position.partiallyClose(ASSET_PRICE_0, CLOSE_PROPORTION_1);
        assertEq(position.currentTotalFeeAmount(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0), expectedFee);
    }

    function testNewLeverageStaysTheSame() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        position.partiallyClose(ASSET_PRICE_0, CLOSE_PROPORTION_1);

        // ASSERT
        assertEq(position.lastNetMargin(), NET_MARGIN_0 / 2);
        assertEq(position.volume, VOLUME_0 / 2);
        assertEq(position.lastNetLeverage(), NET_LEVERAGE_0);
    }

    function testPayoutChangesAfterFees() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        int256 payout = position.partiallyClose(ASSET_PRICE_0, CLOSE_PROPORTION_1);

        // ASSERT
        assertEq(payout, int256(NET_MARGIN_0 / 2));
    }

    function testShortAndProfit() public {
        // ARRANGE
        position.isShort = true;

        // ACT
        int256 payout = position.partiallyClose(1_600 * int256(PRICE_MULTIPLIER), 500_000);

        // ASSERT
        assertEq(position.volume, VOLUME_0 / 2, "volume");
        assertEq(position.margin, MARGIN_0 / 2, "margin");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 / 2, "size");
        assertEq(payout, int256(MARGIN_0), "payout");
    }

    function testShortAndProfitAndFee() public {
        // ARRANGE
        position.isShort = true;

        // ACT
        // 25h of fees, eat 1/2 of the margin
        position.updateFees(25 * BASIS_BORROW_FEE_0, 25 * FUNDING_FEE_0);

        // Set price to 100% profit
        assertEq(position.lastNetMargin(), MARGIN_0 / 2, "last net margin");
        assertEq(position.currentPnL(ASSET_PRICE_0_3), int256(MARGIN_0), "PnL");

        // Close by 50%
        int256 payout = position.partiallyClose(ASSET_PRICE_0_3, 500_000);

        // ASSERT
        assertEq(position.volume, VOLUME_0 / 2, "volume");
        assertEq(position.margin, MARGIN_0 / 2, "margin");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 / 2, "size");
        assertEq(position.lastNetMargin(), MARGIN_0 / 4, "last net margin");
        assertEq(position.currentPnL(ASSET_PRICE_0_3), int256(MARGIN_0 / 2), "PnL");
        assertEq(payout, int256(MARGIN_0 * 3 / 4), "payout");
    }

    function testShortAndProfitAndFeeTwice() public {
        // ARRANGE
        position.isShort = true;

        // ACT
        // 25h of fees, eat 1/2 of the margin
        position.updateFees(25 * BASIS_BORROW_FEE_0, 25 * FUNDING_FEE_0);
        assertEq(
            position.currentTotalFeeAmount(25 * BASIS_BORROW_FEE_0, 25 * FUNDING_FEE_0),
            int256(MARGIN_0 / 2),
            "total fee amount"
        );

        // Set price to 100% profit
        // Close by 50%
        position.partiallyClose(ASSET_PRICE_0_3, 500_000);

        // ASSERT
        assertEq(
            position.currentTotalFeeAmount(25 * BASIS_BORROW_FEE_0, 25 * FUNDING_FEE_0),
            int256(MARGIN_0 / 4),
            "total fee amount"
        );
        assertEq(
            position.currentNetEquity(ASSET_PRICE_0_3, 25 * BASIS_BORROW_FEE_0, 25 * FUNDING_FEE_0),
            int256(MARGIN_0 * 3 / 4),
            "net equity"
        );

        // ASSERT FEE EATS UP MARGIN AFTER ANOTHER 25h
        position.updateFees(50 * BASIS_BORROW_FEE_0, 50 * FUNDING_FEE_0);
        // 25h of fees, eat 1/2 of the 1/2 margin, so another 1/5 gets added to fees, totalling at 1/2
        assertEq(
            position.currentTotalFeeAmount(50 * BASIS_BORROW_FEE_0, 50 * FUNDING_FEE_0),
            int256(MARGIN_0 / 2),
            "total fee amount 2"
        );
        assertEq(position.lastNetMargin(), 0, "last net margin");

        assertTrue(
            position.isLiquidatable(ASSET_PRICE_0_3, 50 * BASIS_BORROW_FEE_0, 50 * FUNDING_FEE_0, 0), "is liquidatable"
        );
    }

    function testPayoutAfterFeeAndProfit() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        int256 payout = position.partiallyClose(ASSET_PRICE_1_SHORT, CLOSE_PROPORTION_1);

        // ASSERT
        assertEq(payout, int256(NET_MARGIN_0) / 2 + PNL_0_1 / 2);
    }
}
