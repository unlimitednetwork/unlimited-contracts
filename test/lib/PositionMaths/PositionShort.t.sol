// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";
import "test/setup/WithPositionMaths.t.sol";

contract ShortPositionTest is Test, WithPositionMaths {
    using PositionMaths for Position;

    function setUp() public {
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
            isShort: true,
            owner: msg.sender,
            lastAlterationBlock: uint40(block.number)
        });
    }

    function testEntryVolume() public {
        assertEq(position.volume, VOLUME_0);
    }

    function testEntryPrice() public {
        assertEq(position.entryPrice(), ASSET_PRICE_0);
    }

    function testEntryLeverage() public {
        assertEq(position.entryLeverage(), LEVERAGE_0);
    }

    function testCurrentVolume() public {
        assertEq(position.currentVolume(2_000 * int256(PRICE_MULTIPLIER)), 5_000_000 * COLLATERAL_MULTIPLIER);

        // Profit
        assertEq(position.currentVolume(1_000 * int256(PRICE_MULTIPLIER)), 2_500_000 * COLLATERAL_MULTIPLIER);

        // Loss
        assertEq(position.currentVolume(3_000 * int256(PRICE_MULTIPLIER)), 7_500_000 * COLLATERAL_MULTIPLIER);
    }

    function testCurrentPnL() public {
        // Profit
        // Price Change of 10%, so 50% of Margin Profit
        assertEq(position.currentPnL(1_600 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0), "1_600");
        assertEq(position.currentPnL(1_800 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0) / 2, "1_800");

        // Loss
        assertEq(position.currentPnL(2_200 * int256(PRICE_MULTIPLIER)), -int256(MARGIN_0 / 2), "2_200");
        assertEq(position.currentPnL(2_400 * int256(PRICE_MULTIPLIER)), -int256(MARGIN_0), "2_400");
    }

    function testCurrentValue() public {
        // Current value at SHORT is entry value + PnL

        // Profit
        assertEq(position.currentValue(0), int256(VOLUME_0) * 2, "0");
        assertEq(position.currentValue(1_000 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 3 / 2, "1_000");
        assertEq(position.currentValue(1_600 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 12 / 10, "1_600");
        assertEq(position.currentValue(1_800 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 11 / 10, "1_800");

        // Loss
        assertEq(position.currentValue(2_200 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 9 / 10, "2_200");
        assertEq(position.currentValue(2_400 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 8 / 10, "2_400");
        assertEq(position.currentValue(3_000 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * 5 / 10, "3_000");

        // Total Loss
        assertEq(position.currentValue(4_000 * int256(PRICE_MULTIPLIER)), 0, "4_000");
        assertEq(position.currentValue(5_000 * int256(PRICE_MULTIPLIER)), int256(VOLUME_0) * -5 / 10, "5_000");
    }

    function testCurrentEquity() public {
        // Profit
        // Price of 1000, so 50% * 5 = 250% profit
        assertEq(position.currentEquity(1_000 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0 * 7 / 2), "1_000");
        assertEq(position.currentEquity(1_600 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0 * 2), "1_600");
        assertEq(position.currentEquity(1_800 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0 * 3 / 2), "1_800");

        // Loss
        assertEq(position.currentEquity(2_200 * int256(PRICE_MULTIPLIER)), int256(MARGIN_0 / 2), "2_200");
        assertEq(position.currentEquity(2_400 * int256(PRICE_MULTIPLIER)), 0, "2_400");

        // Price of 3_000, so 50% * 5 = 250% loss
        assertEq(position.currentEquity(3_000 * int256(PRICE_MULTIPLIER)), -int256(MARGIN_0 * 3 / 2), "3_000");
    }

    function testCurrentBorrowFeeAmount() public {
        assertEq(position.currentBorrowFeeAmount(BORROW_FEE_INTEGRAL_0), BORROW_FEE_AMOUNT_0);
    }

    function testCurrentFundingFeeAmount() public {
        assertEq(position.currentFundingFeeAmount(FUNDING_FEE_INTEGRAL_0), FUNDING_FEE_AMOUNT_0);
    }

    function testWithPastFeeIntegralAndAmount() public {
        // Set pastFeeIntegrals to 0.5 of the current integrals
        // Set lastFeeAmounts to 1.0 of the current amounts
        // Should give 1.5 of the current fee amounts
        position.pastBorrowFeeIntegral = BORROW_FEE_INTEGRAL_0 / 2;
        position.lastBorrowFeeAmount = BORROW_FEE_AMOUNT_0;
        position.pastFundingFeeIntegral = FUNDING_FEE_INTEGRAL_0 / 2;
        position.lastFundingFeeAmount = FUNDING_FEE_AMOUNT_0;
        assertEq(position.currentBorrowFeeAmount(BORROW_FEE_INTEGRAL_0), BORROW_FEE_AMOUNT_0 * 3 / 2);
        assertEq(position.currentFundingFeeAmount(FUNDING_FEE_INTEGRAL_0), FUNDING_FEE_AMOUNT_0 * 3 / 2);
    }

    // ARRANGE
    function testNetPnl() public {
        // These values are the same as the currentPnL test, but with fees deducted
        int256 totalFeeAmount = int256(BORROW_FEE_AMOUNT_0 + FUNDING_FEE_AMOUNT_0);

        //ASSERT

        // PROFIT
        assertEq(
            position.currentNetPnL(1_800 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0) / 2 - totalFeeAmount,
            "1_800"
        );
        assertEq(
            position.currentNetPnL(1_600 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0) - totalFeeAmount,
            "1_600"
        );

        // Loss
        assertEq(
            position.currentNetPnL(2_200 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            -int256(MARGIN_0 / 2) - totalFeeAmount,
            "2_200"
        );
        assertEq(
            position.currentNetPnL(2_400 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            -int256(MARGIN_0) - totalFeeAmount,
            "2_400"
        );
    }

    function testCurrentNetEquity() public {
        // ARRANGE
        // These values are the same as the currentEquity test, but with fees deducted
        int256 totalFeeAmount = int256(BORROW_FEE_AMOUNT_0 + FUNDING_FEE_AMOUNT_0);

        // ASSERT

        // Profit
        // Price of 1000, so 50% * 5 = 250% profit
        assertEq(
            position.currentNetEquity(1_000 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0 * 7 / 2) - totalFeeAmount,
            "1_000"
        );
        assertEq(
            position.currentNetEquity(1_600 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0 * 2) - totalFeeAmount,
            "1_600"
        );
        assertEq(
            position.currentNetEquity(1_800 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0 * 3 / 2) - totalFeeAmount,
            "1_800"
        );

        // Loss
        assertEq(
            position.currentNetEquity(2_200 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0 / 2) - totalFeeAmount,
            "2_200"
        );
        assertEq(
            position.currentNetEquity(2_400 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            0 - totalFeeAmount,
            "2_400"
        );

        // Price of 3_000, so 50% * 5 = 250% loss
        assertEq(
            position.currentNetEquity(3_000 * int256(PRICE_MULTIPLIER), BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            -int256(MARGIN_0 * 3 / 2) - totalFeeAmount,
            "3_000"
        );
    }

    function testNegativeFundingFee() public {
        position = Position(
            MARGIN_0,
            VOLUME_0,
            ASSET_AMOUNT_0,
            0,
            0,
            0,
            0,
            0,
            0,
            uint48(block.timestamp),
            uint48(block.timestamp),
            IS_SHORT_0,
            msg.sender,
            uint40(block.number)
        );

        assertEq(
            position.currentFundingFeeAmount(-1 * FUNDING_FEE_INTEGRAL_0),
            -1 * FUNDING_FEE_AMOUNT_0,
            "current funding fee amount"
        );
        assertEq(
            position.currentNetPnL(ASSET_PRICE_0, BORROW_FEE_INTEGRAL_0, -1 * FUNDING_FEE_INTEGRAL_0),
            FUNDING_FEE_AMOUNT_0 - BORROW_FEE_AMOUNT_0,
            "current net PnL"
        );
        assertEq(
            position.currentNetEquity(ASSET_PRICE_0, BORROW_FEE_INTEGRAL_0, -1 * FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0) + FUNDING_FEE_AMOUNT_0 - BORROW_FEE_AMOUNT_0,
            "current net equity"
        );
    }

    function testExists() public {
        assertEq(position.exists(), true);
        delete position;
        assertEq(position.exists(), false);
    }

    function testCurrentNetMargin() public {
        // ACT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverage() public {
        // ARRANGE
        int256 totalFeeAmount = BORROW_FEE_AMOUNT_0 + FUNDING_FEE_AMOUNT_0; // 600_000

        uint256 netMargin = MARGIN_0 - uint256(totalFeeAmount); // 400_000
        uint256 expectedNetLeverage = VOLUME_0 * LEVERAGE_MULTIPLIER / netMargin; // 5_000_000 / 400_000 = 12.5

        // ACT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(currentNetLeverage, expectedNetLeverage);
    }

    function testRemovesFeesFromLastNetMargin() public {
        // ARRANGE
        uint256 expectedMargin = MARGIN_0 - uint256(BORROW_FEE_AMOUNT_0) - uint256(FUNDING_FEE_AMOUNT_0);

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.margin, MARGIN_0);
        assertEq(position.lastNetMargin(), expectedMargin);
    }

    function testRemovesFeesFromMarginDoesNotChangeEntryLeverage() public {
        // ARRANGE
        uint256 expectedMargin = MARGIN_0 - uint256(BORROW_FEE_AMOUNT_0) - uint256(FUNDING_FEE_AMOUNT_0);
        uint256 expectedNetLeverage = VOLUME_0 * LEVERAGE_MULTIPLIER / expectedMargin; // 5_000_000 / 400_000 = 12.5

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.entryLeverage(), LEVERAGE_0, "entry leverage");
        assertEq(
            position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            expectedNetLeverage,
            "net leverage"
        );
    }

    function testUpdateFeesStoresFeeAmount() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.lastBorrowFeeAmount, BORROW_FEE_AMOUNT_0);
        assertEq(position.lastFundingFeeAmount, FUNDING_FEE_AMOUNT_0);
    }

    function testUpdateFeesDoesNotChangeVolume() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.volume, VOLUME_0);
    }

    function testCurrentNetMarginAfterFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverageAfterFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetLeverage, NET_LEVERAGE_0);
    }

    function testCurrentNetMarginAfterHalfFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0 / 2, FUNDING_FEE_INTEGRAL_0 / 2);

        // ASSERT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverageAfterHalfFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0 / 2, FUNDING_FEE_INTEGRAL_0 / 2);

        // ASSERT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetLeverage, NET_LEVERAGE_0);
    }
}
