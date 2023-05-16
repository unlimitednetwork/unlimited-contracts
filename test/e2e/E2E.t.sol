// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithFullFixtures.t.sol";

contract E2ETest is WithFullFixtures {
    event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);

    MockToken collateral;
    ILiquidityPool liquidityPool0;
    ILiquidityPool liquidityPool1;
    ILiquidityPoolAdapter liquidityPoolAdapter;
    MockPriceFeedAdapter priceFeedAdapter;
    ITradePair tradePair0;

    function setUp() public {
        vm.warp(1 hours);
        _deployMainContracts();

        // NOTE: only for test purposes
        collateral = new MockToken();
        collateral.setDecimals(6);

        liquidityPool0 = _deployLiquidityPool(controller, collateral, "LP1");
        liquidityPool1 = _deployLiquidityPool(controller, collateral, "LP2");

        LiquidityPoolConfig[] memory liquidityConfig = new LiquidityPoolConfig[](2);
        liquidityConfig[0] = LiquidityPoolConfig(address(liquidityPool0), uint96(FULL_PERCENT));
        liquidityConfig[1] = LiquidityPoolConfig(address(liquidityPool1), uint96(FULL_PERCENT));

        liquidityPoolAdapter = _deployLiquidityPoolAdapter(controller, feeManager, collateral, liquidityConfig);

        // Deploy price feeds
        priceFeedAdapter = _deployPriceFeed(controller);

        tradePair0 = _deployTradePair(
            controller, userManager, feeManager, tradeManager, collateral, priceFeedAdapter, liquidityPoolAdapter
        );
    }

    function testDepositOpenFee() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // Check if UserManager emits an event to track volume
        vm.expectEmit(true, true, false, true);
        emit UserVolumeAdded(BOB, address(tradePair0), VOLUME_0 / 1e6);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);

        // ASSERT
        assertEq(collateral.balanceOf(address(STAKERS_ADDRESS)), OPEN_POSITION_FEE_0 * 18 / 100, "stakers");
        assertEq(collateral.balanceOf(address(DEV_ADDRESS)), OPEN_POSITION_FEE_0 * 12 / 100, "dev");
        assertEq(collateral.balanceOf(address(INSURANCE_ADDRESS)), OPEN_POSITION_FEE_0 * 10 / 100, "insurance");
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100, "LP0");

        assertEq(collateral.balanceOf(address(tradePair0)), MARGIN_0, "tradePair0");
        assertEq(collateral.balanceOf(BOB), 0, "bob");
    }

    function testTraderProfit() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100;
        uint256 payoutToBob = MARGIN_0 + liquidityAfterOpenFee;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = closePositionFeeAmount * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(2_200 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // CLOSE POSITION
        _closePosition(BOB, tradePair0, positionId, newPrice);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), 0, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee / 2, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), liquidityAfterCloseFee / 2, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testTraderProfitAndFeeLiquidityDrained() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        vm.warp(1 hours);

        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 expectedBorrowFees = uint256((BASIS_BORROW_FEE_0) * 25 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 expectedFundingFees = uint256((FUNDING_FEE_0) * 25 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100 + expectedBorrowFees;
        uint256 payoutToBob = MARGIN_0 + liquidityAfterOpenFee - expectedBorrowFees - expectedFundingFees;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = closePositionFeeAmount * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(2_200 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // SET TIME
        vm.warp(25 hours + 1 hours);

        // CLOSE POSITION
        _closePosition(BOB, tradePair0, positionId, newPrice);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), expectedFundingFees, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee / 2, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), liquidityAfterCloseFee / 2, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testPartiallyCloseWithProfit() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100;
        uint256 payoutToBob = MARGIN_0 / 2 + liquidityAfterOpenFee;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = closePositionFeeAmount * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(4_000 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // PARTIALLY CLOSE POSITION
        uint256 proportion = 50 * PERCENTAGE_MULTIPLIER / 100;
        _partiallyClosePosition(BOB, tradePair0, positionId, newPrice, proportion);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), MARGIN_0 / 2, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee / 2, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), liquidityAfterCloseFee / 2, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testCloseWithFees() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        vm.warp(1 hours);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 expectedBorrowFees = uint256((BASIS_BORROW_FEE_0) * 10 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 expectedFundingFees = uint256((FUNDING_FEE_0) * 10 * int256(VOLUME_0) / FEE_MULTIPLIER);
        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100 + expectedBorrowFees;
        uint256 payoutToBob = MARGIN_0 - expectedBorrowFees - expectedFundingFees;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = liquidityAfterOpenFee + closePositionFeeAmount * 60 / 100;

        // PARTIALLY CLOSE POSITION
        vm.warp(5 hours + 1 hours);
        vm.roll(3);
        vm.warp(10 hours + 1 hours);
        _closePosition(BOB, tradePair0, positionId, ASSET_PRICE_0);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), expectedFundingFees, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), 0, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testPartiallyCloseWithProfitThanClose() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100;
        uint256 payoutToBob = MARGIN_0 / 2 + liquidityAfterOpenFee;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = closePositionFeeAmount * 60 / 100;

        uint256 payoutToBob2 = MARGIN_0 / 2 + liquidityAfterCloseFee;
        uint256 closePositionFeeAmount2 = payoutToBob2 / 1000;
        uint256 balanceBob2 = balanceBob + payoutToBob2 - closePositionFeeAmount2;
        uint256 liquidityAfterCloseFee2 = closePositionFeeAmount2 * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(4_000 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // PARTIALLY CLOSE POSITION
        uint256 proportion = 50 * PERCENTAGE_MULTIPLIER / 100;
        _partiallyClosePosition(BOB, tradePair0, positionId, newPrice, proportion);
        vm.roll(3);
        _closePosition(BOB, tradePair0, positionId, newPrice);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob2, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), 0, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee2 / 2, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), liquidityAfterCloseFee2 / 2, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount + closePositionFeeAmount2) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount + closePositionFeeAmount2) * 12 / 100,
            "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount + closePositionFeeAmount2) * 10 / 100,
            "insurance"
        );
    }

    function testTraderLoss() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 liquidityAfterOpenFee = liquidityAmount + OPEN_POSITION_FEE_0 * 60 / 100;
        uint256 payoutToBob = MARGIN_0 / 2;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidityAfterCloseFee = liquidityAfterOpenFee + MARGIN_0 / 2 + closePositionFeeAmount * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(1_800 * COLLATERAL_MULTIPLIER);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // CLOSE POSITION
        _closePosition(BOB, tradePair0, positionId, newPrice);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), 0, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidityAfterCloseFee, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), 0, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testAddMarginThenClose() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        // ADD MARGIN
        uint256 addedMargin = MARGIN_0 * 1001 / 1000;
        deal(address(collateral), BOB, addedMargin);
        _addMarginToPosition(BOB, tradePair0, addedMargin, positionId, ASSET_PRICE_0);
        vm.roll(3);

        _closePosition(BOB, tradePair0, positionId, ASSET_PRICE_0);

        // ASSERT
        uint256 balanceBob = MARGIN_0 * 2 * 999 / 1000;
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
    }

    function testTraderProfitAndFees() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);

        vm.warp(10 hours);
        uint256 positionId = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);

        uint256 totalBorrowFees = uint256(BASIS_BORROW_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 totalFundingFees = uint256(FUNDING_FEE_0) * 10 * VOLUME_0 / uint256(FEE_MULTIPLIER);
        uint256 totalFees = totalBorrowFees + totalFundingFees;
        uint256 payoutToBob = uint256(EQUITY_0_1) - totalFees;
        uint256 closePositionFeeAmount = payoutToBob / 1000;
        uint256 balanceBob = payoutToBob - closePositionFeeAmount;
        uint256 liquidity = liquidityAmount - uint256(PNL_0_1) + totalBorrowFees
            + (closePositionFeeAmount + OPEN_POSITION_FEE_0) * 60 / 100;

        // CHANGE PRICE
        int256 newPrice = int256(ASSET_PRICE_1);
        priceFeedAdapter.setMarkPrices(newPrice, newPrice);

        // MOVE TIME
        vm.warp(20 hours);

        // CLOSE POSITION
        _closePosition(BOB, tradePair0, positionId, newPrice);

        // ASSERT
        assertEq(collateral.balanceOf(BOB), balanceBob, "bob");
        assertEq(collateral.balanceOf(address(tradePair0)), totalFundingFees, "tradePair");
        // liquidity gets devided by 2 for each LP
        assertEq(collateral.balanceOf(address(liquidityPool0)), liquidity, "liquidityPool0");
        assertEq(collateral.balanceOf(address(liquidityPool1)), 0, "liquidityPool1");
        assertEq(
            collateral.balanceOf(address(STAKERS_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 18 / 100,
            "stakers"
        );
        assertEq(
            collateral.balanceOf(address(DEV_ADDRESS)), (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 12 / 100, "dev"
        );
        assertEq(
            collateral.balanceOf(address(INSURANCE_ADDRESS)),
            (OPEN_POSITION_FEE_0 + closePositionFeeAmount) * 10 / 100,
            "insurance"
        );
    }

    function testFundingFee() public {
        // ADD LIQUIDITY
        uint256 liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity(liquidityPool0, ALICE, liquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        uint256 positionIdBob = _openPosition(BOB, tradePair0, INITIAL_BALANCE, LEVERAGE_0, false);

        // OPEN POSITION
        deal(address(collateral), CAROL, INITIAL_BALANCE / 10);
        uint256 positionIdCarol = _openPosition(CAROL, tradePair0, INITIAL_BALANCE / 10, LEVERAGE_0, true);

        // GET FUNDING FEES
        (int256 fundingFeeLong, int256 fundingFeeShort) = tradeManager.getCurrentFundingFeeRates(address(tradePair0));

        assertEq(fundingFeeLong, 300_000_000_000, "fundingFeeLong");
        assertEq(fundingFeeShort, -3_000_000_000_000, "fundingFeeShort");

        // Increase time and decrease price to 1_800
        vm.warp(1 days + 1 hours);
        vm.roll(2);
        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0_2, ASSET_PRICE_0_2);

        int256 totalFeeCarol = (BASIS_BORROW_FEE_0 - FUNDING_FEE_0 * 10) * 24 * int256(VOLUME_0 / 10) / FEE_MULTIPLIER;
        int256 checkFee = ITradePair(tradePair0).detailsOfPosition(positionIdCarol).totalFeeAmount;
        // CLOSE POSITIONS
        _closePosition(BOB, tradePair0, positionIdBob, ASSET_PRICE_0_2);
        _closePosition(CAROL, tradePair0, positionIdCarol, ASSET_PRICE_0_2);

        // ASSERT FUNDING FEES
        uint256 balanceBob = (
            uint256(EQUITY_0_2) - uint256((FUNDING_FEE_0 + BASIS_BORROW_FEE_0) * 24 * int256(VOLUME_0) / FEE_MULTIPLIER)
        ) * 999 / 1000;
        uint256 balanceCarol = uint256(int256(MARGIN_0) / 10 - PNL_0_2 / 10 - totalFeeCarol) * 999 / 1000;

        assertEq(checkFee, totalFeeCarol, "totalFeeCarol");
        assertEq(collateral.balanceOf(BOB), balanceBob, "balanceBob");
        assertEq(collateral.balanceOf(CAROL), balanceCarol, "balanceCarol");
    }

    /* ========== HELPER FUNCTIONS =========== */

    function _closePosition(address user, ITradePair tradePair, uint256 positionId, int256 constraintPrice)
        private
        prank(user)
    {
        ClosePositionParams memory closePositionParams = ClosePositionParams(address(tradePair), positionId);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.closePosition(closePositionParams, constraints, updateData);
    }

    function _addMarginToPosition(
        address user,
        ITradePair tradePair,
        uint256 addedMargin,
        uint256 positionId,
        int256 constraintPrice
    ) private prank(user) {
        AddMarginToPositionParams memory addMarginPositionParams =
            AddMarginToPositionParams(address(tradePair), positionId, addedMargin);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), addedMargin);

        tradeManager.addMarginToPosition(addMarginPositionParams, constraints, updateData);
    }

    function _removeMarginFromPosition(
        address user,
        ITradePair tradePair,
        uint256 removedMargin,
        uint256 positionId,
        int256 constraintPrice
    ) private prank(user) {
        RemoveMarginFromPositionParams memory addMarginPositionParams =
            RemoveMarginFromPositionParams(address(tradePair), positionId, removedMargin);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.removeMarginFromPosition(addMarginPositionParams, constraints, updateData);
    }

    function _partiallyClosePosition(
        address user,
        ITradePair tradePair,
        uint256 positionId,
        int256 constraintPrice,
        uint256 proportion
    ) private prank(user) {
        PartiallyClosePositionParams memory partiallyClosePositionParams =
            PartiallyClosePositionParams(address(tradePair), positionId, proportion);
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, constraintPrice * 99 / 100, constraintPrice * 101 / 100);
        UpdateData[] memory updateData;

        tradeManager.partiallyClosePosition(partiallyClosePositionParams, constraints, updateData);
    }

    function _openPosition(address user, ITradePair tradePair, uint256 margin, uint256 leverage, bool isShort)
        private
        prank(user)
        returns (uint256)
    {
        OpenPositionParams memory openPositionParams =
            OpenPositionParams(address(tradePair), margin, leverage, isShort, address(0), address(0));
        Constraints memory constraints =
            Constraints(block.timestamp + 1 hours, ASSET_PRICE_0 * 99 / 100, ASSET_PRICE_0 * 101 / 100);
        UpdateData[] memory updateData;

        collateral.approve(address(tradeManager), margin);
        return tradeManager.openPosition(openPositionParams, constraints, updateData);
    }

    function _depositLiquidity(ILiquidityPool liquidityPool, address user, uint256 amount)
        private
        prank(user)
        returns (uint256 shares)
    {
        collateral.approve(address(liquidityPool), amount);
        shares = liquidityPool.deposit(amount, 0);
    }

    modifier prank(address executor) {
        vm.startPrank(executor);
        _;
        vm.stopPrank();
    }
}
