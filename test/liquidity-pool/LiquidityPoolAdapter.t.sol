// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "test/mocks/MockV3Aggregator.sol";
import "../setup/WithMocks.t.sol";
import "../mocks/MockController.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";

contract LiquidityPoolAdapterTest is WithMocks {
    using SafeERC20 for IERC20;

    LiquidityPoolAdapter private liquidityPoolAdapter;

    MockLiquidityPool private mockLiquidityPool2;
    MockLiquidityPool private mockLiquidityPool3;

    function setUp() public {
        liquidityPoolAdapter = new LiquidityPoolAdapter(
            mockUnlimitedOwner,
            mockController,
            address(mockFeeManager),
            collateral
        );

        mockLiquidityPool2 = new MockLiquidityPool(collateral);
        mockLiquidityPool3 = new MockLiquidityPool(collateral);

        mockLiquidityPool.setAvailableLiquidity(15 ether);
        mockLiquidityPool2.setAvailableLiquidity(5 ether);
        mockLiquidityPool3.setAvailableLiquidity(10 ether);

        deal(address(collateral), address(mockFeeManager), 100_000 ether, true);

        vm.startPrank(address(mockFeeManager));
    }

    // TEST: LiquidityPoolAdapter.depositProfit

    function testDepositProfit_oneLiquidityPool() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(1);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 profit = 1 ether;

        // ACT
        collateral.transfer(address(liquidityPoolAdapter), profit);
        liquidityPoolAdapter.depositProfit(profit);

        // ASSERT
        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, profit);
    }

    function testDepositProfit_twoLiquidityPools() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 profit = 1 ether;

        // ACT
        collateral.transfer(address(liquidityPoolAdapter), profit);
        liquidityPoolAdapter.depositProfit(profit);

        // ASSERT
        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, profit * 3 / 4);

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, profit / 4);
    }

    function testDepositProfit_moreLiquidityPools() public {
        // ARRANGE

        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 profit = 1 ether;

        // ACT
        collateral.transfer(address(liquidityPoolAdapter), profit);
        liquidityPoolAdapter.depositProfit(profit);

        // ASSERT
        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, profit * 3 / 5);

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, profit / 5);

        uint256 liquidityPoolBalance3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalance3, profit / 5);
    }

    // TEST: LiquidityPoolAdapter.requestLossPayout

    function testRequestLossPayout_oneLiquidityPool() public {
        // ARRANGE
        _dealTokensToLiquidityPools();
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(1);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 requestedPayout = 1 ether;

        uint256 feeManagerBalanceBefore = collateral.balanceOf(address(mockFeeManager));
        uint256 liquidityPoolBalanceBefore = collateral.balanceOf(address(mockLiquidityPool));

        // ACT
        liquidityPoolAdapter.requestLossPayout(requestedPayout);

        // ASSERT
        uint256 feeManagerBalanceAfter = collateral.balanceOf(address(mockFeeManager));
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, requestedPayout);

        // assert the collateral is taken out of the liquidity pool
        uint256 liquidityPoolBalanceAfter = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalanceBefore - liquidityPoolBalanceAfter, requestedPayout);
    }

    function testRequestLossPayout_twoLiquidityPools() public {
        // ARRANGE
        _dealTokensToLiquidityPools();
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 requestedPayout = 1 ether;

        uint256 feeManagerBalanceBefore = collateral.balanceOf(address(mockFeeManager));
        uint256 liquidityPoolBalanceBefore = collateral.balanceOf(address(mockLiquidityPool));
        uint256 liquidityPoolBalanceBefore2 = collateral.balanceOf(address(mockLiquidityPool2));

        // ACT
        liquidityPoolAdapter.requestLossPayout(requestedPayout);

        // ASSERT
        uint256 feeManagerBalanceAfter = collateral.balanceOf(address(mockFeeManager));
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, requestedPayout);

        // assert the collateral is taken out of the liquidity pool
        uint256 liquidityPoolBalanceAfter = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalanceBefore - liquidityPoolBalanceAfter, requestedPayout * 3 / 4);

        uint256 liquidityPoolBalanceAfter2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalanceBefore2 - liquidityPoolBalanceAfter2, requestedPayout / 4);
    }

    function testRequestLossPayout_threeLiquidityPools() public {
        // ARRANGE
        _dealTokensToLiquidityPools();
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);

        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 requestedPayout = 1 ether;

        uint256 feeManagerBalanceBefore = collateral.balanceOf(address(mockFeeManager));
        uint256 liquidityPoolBalanceBefore = collateral.balanceOf(address(mockLiquidityPool));
        uint256 liquidityPoolBalanceBefore2 = collateral.balanceOf(address(mockLiquidityPool2));
        uint256 liquidityPoolBalanceBefore3 = collateral.balanceOf(address(mockLiquidityPool3));

        // ACT
        liquidityPoolAdapter.requestLossPayout(requestedPayout);

        // ASSERT
        uint256 feeManagerBalanceAfter = collateral.balanceOf(address(mockFeeManager));
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, requestedPayout);

        // assert the collateral is taken out of the liquidity pool
        uint256 liquidityPoolBalanceAfter = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalanceBefore - liquidityPoolBalanceAfter, requestedPayout * 3 / 5);

        uint256 liquidityPoolBalanceAfter2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalanceBefore2 - liquidityPoolBalanceAfter2, requestedPayout / 5);

        uint256 liquidityPoolBalanceAfter3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalanceBefore3 - liquidityPoolBalanceAfter3, requestedPayout / 5);
    }

    function testRequestLossPayout_maxPayout() public {
        // ARRANGE
        _dealTokensToLiquidityPools();
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);

        uint256 _totalAvailableLiquidity;
        for (uint256 i = 0; i < liquidityConfig.length; i++) {
            uint256 poolLiquidity = ILiquidityPool(liquidityConfig[i].poolAddress).availableLiquidity();
            _totalAvailableLiquidity += poolLiquidity * liquidityConfig[i].percentage / FULL_PERCENT;
        }

        // set maximum liquidity as 10% of total available liquidity
        uint256 maxLiquidityProportion = 10_00;

        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(maxLiquidityProportion, liquidityConfig);
        vm.startPrank(address(mockFeeManager));

        uint256 maxPayout = _totalAvailableLiquidity * maxLiquidityProportion / FULL_PERCENT;

        // request more than there is available liquidity
        uint256 requestedPayout = _totalAvailableLiquidity * 100;

        uint256 feeManagerBalanceBefore = collateral.balanceOf(address(mockFeeManager));
        uint256 liquidityPoolBalanceBefore = collateral.balanceOf(address(mockLiquidityPool));
        uint256 liquidityPoolBalanceBefore2 = collateral.balanceOf(address(mockLiquidityPool2));
        uint256 liquidityPoolBalanceBefore3 = collateral.balanceOf(address(mockLiquidityPool3));

        // ACT
        liquidityPoolAdapter.requestLossPayout(requestedPayout);

        // ASSERT
        uint256 feeManagerBalanceAfter = collateral.balanceOf(address(mockFeeManager));
        assertEq(feeManagerBalanceAfter - feeManagerBalanceBefore, maxPayout);

        // assert the collateral is taken out of the liquidity pool
        uint256 liquidityPoolBalanceAfter = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalanceBefore - liquidityPoolBalanceAfter, maxPayout * 3 / 5);

        uint256 liquidityPoolBalanceAfter2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalanceBefore2 - liquidityPoolBalanceAfter2, maxPayout / 5);

        uint256 liquidityPoolBalanceAfter3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalanceBefore3 - liquidityPoolBalanceAfter3, maxPayout / 5);
    }

    // TEST: LiquidityPoolAdapter.depositProfit

    function testUpdateLiquidityPools() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);
        vm.startPrank(address(mockFeeManager));

        uint256 profit = 1 ether;
        collateral.transfer(address(liquidityPoolAdapter), profit);
        liquidityPoolAdapter.depositProfit(profit);

        // ACT
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        LiquidityPoolConfig[] memory liquidityConfig2 = _getLiquidityPoolsConfig(1);
        liquidityPoolAdapter.updateLiquidityPools(liquidityConfig2);

        vm.startPrank(address(mockFeeManager));
        collateral.transfer(address(liquidityPoolAdapter), profit);
        liquidityPoolAdapter.depositProfit(profit);

        // ASSERT
        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, profit + (profit * 3 / 5));

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, profit / 5);

        uint256 liquidityPoolBalance3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalance3, profit / 5);
    }

    function testUpdateLiquidityPoolsNoLength() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig;

        // ACT
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("LiquidityPoolAdapter::_updateLiquidityPools: Cannot set zero liquidity pools");
        liquidityPoolAdapter.updateLiquidityPools(liquidityConfig);
    }

    function testInvalidLiquidityPool() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        vm.mockCall(
            address(mockController), abi.encodeWithSelector(MockController.isLiquidityPool.selector), abi.encode(false)
        );

        // ACT & ASSERT
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("LiquidityPoolAdapter::_updateLiquidityPools: Invalid pool");
        liquidityPoolAdapter.updateLiquidityPools(liquidityConfig);
    }

    function testBadPoolPercentageTooHigh() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        liquidityConfig[0].percentage = uint96(FULL_PERCENT + 1);

        // ACT & ASSERT
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("LiquidityPoolAdapter::_updateLiquidityPools: Bad pool percentage");
        liquidityPoolAdapter.updateLiquidityPools(liquidityConfig);
    }

    function testBadPoolPercentageTooLow() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        liquidityConfig[0].percentage = uint96(0);

        // ACT & ASSERT
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("LiquidityPoolAdapter::_updateLiquidityPools: Bad pool percentage");
        liquidityPoolAdapter.updateLiquidityPools(liquidityConfig);
    }

    function testUpdateMaxPayoutProportion() public {
        // ARRANGE
        vm.stopPrank();
        vm.startPrank(UNLIMITED_OWNER);

        // ACT & ASSERT 1
        vm.expectRevert("LiquidityPoolAdapter::_updateMaxPayoutProportion: Bad max payout proportion");
        liquidityPoolAdapter.updateMaxPayoutProportion(0);

        // ACT & ASSERT 2
        vm.expectRevert("LiquidityPoolAdapter::_updateMaxPayoutProportion: Bad max payout proportion");
        liquidityPoolAdapter.updateMaxPayoutProportion(FULL_PERCENT + 1);

        // ACT & ASSERT 3
        liquidityPoolAdapter.updateMaxPayoutProportion(FULL_PERCENT);
        assertEq(liquidityPoolAdapter.maxPayoutProportion(), FULL_PERCENT);
    }

    function testAvailableLiquidity() public {
        // ARRANGE
        mockLiquidityPool.setAvailableLiquidity(15 ether);
        mockLiquidityPool2.setAvailableLiquidity(5 ether);

        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT * 9 / 10, liquidityConfig);

        // ASSERT
        assertEq(liquidityPoolAdapter.availableLiquidity(), 20 ether);
    }

    function testMaximumPayout() public {
        // ARRANGE
        mockLiquidityPool.setAvailableLiquidity(15 ether);
        mockLiquidityPool2.setAvailableLiquidity(5 ether);

        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(2);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT * 9 / 10, liquidityConfig);

        // ASSERT
        assertEq(liquidityPoolAdapter.getMaximumPayout(), 20 ether * 9 / 10);
    }

    function testRequestLossPayoutZero() public {
        // ARRANGE
        uint256 requestedPayout = 0;

        // ACT & ASSERT
        assertEq(liquidityPoolAdapter.requestLossPayout(requestedPayout), 0);
    }

    function testDepositFees() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));

        uint256 fees = 1 ether;
        collateral.transfer(address(liquidityPoolAdapter), fees);

        // ACT
        liquidityPoolAdapter.depositFees(fees);

        // ASSERT
        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, fees * 3 / 5);

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, fees / 5);

        uint256 liquidityPoolBalance3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalance3, fees / 5);
    }

    function testDepositWithZeroAvailableLiquidity() public {
        // ARRANGE
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);

        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));

        uint256 fees = 1 ether;
        collateral.transfer(address(liquidityPoolAdapter), fees);

        mockLiquidityPool.setAvailableLiquidity(0);
        mockLiquidityPool2.setAvailableLiquidity(0);
        mockLiquidityPool3.setAvailableLiquidity(0);

        // ACT
        liquidityPoolAdapter.depositFees(fees);

        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, fees / 3);

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, fees / 3);

        // Last LP receives the rounding error dust
        uint256 liquidityPoolBalance3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalance3, fees / 3 + 1);
    }

    function testDepositWithOnlyOneAvailableLiquidity() public {
        // ARRANGE
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(3);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        vm.startPrank(address(mockFeeManager));
        uint256 fees = 1 ether;
        collateral.transfer(address(liquidityPoolAdapter), fees);

        mockLiquidityPool.setAvailableLiquidity(0);
        mockLiquidityPool2.setAvailableLiquidity(0);

        // ACT
        liquidityPoolAdapter.depositFees(fees);

        uint256 liquidityPoolBalance = collateral.balanceOf(address(mockLiquidityPool));
        assertEq(liquidityPoolBalance, 0);

        uint256 liquidityPoolBalance2 = collateral.balanceOf(address(mockLiquidityPool2));
        assertEq(liquidityPoolBalance2, 0);

        // Last LP was the only one with availableLiquidity, so it should have received all the fees
        uint256 liquidityPoolBalance3 = collateral.balanceOf(address(mockLiquidityPool3));
        assertEq(liquidityPoolBalance3, fees);
    }

    function testResetAllowances() public {
        // ASSERT

        LiquidityPoolConfig[] memory liquidityConfig = _getLiquidityPoolsConfig(1);
        vm.stopPrank();
        vm.prank(UNLIMITED_OWNER);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);
        vm.stopPrank();
        vm.prank(address(liquidityPoolAdapter));
        collateral.approve(address(mockLiquidityPool), 1);

        // ACT
        uint256 fees = 1 ether;
        vm.startPrank(address(mockFeeManager));
        collateral.transfer(address(liquidityPoolAdapter), fees);
        liquidityPoolAdapter.depositFees(fees);

        // ASSERT
        // Without reseting the allowance, the call would fail
    }

    function testOnlyValidTradePair() public {
        // ARRANGE
        vm.stopPrank();
        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(MockController.isTradePair.selector, address(this)),
            abi.encode(false)
        );

        // ACT & ASSERT
        vm.expectRevert("LiquidityPoolAdapter::_onlyValidTradePair: Caller is not a trade pair");
        liquidityPoolAdapter.requestLossPayout(1 ether);
    }

    function testOnlyFeeManager() public {
        // ARRANGE
        vm.stopPrank();

        // ACT & ASSERT
        vm.expectRevert("LiquidityPoolAdapter::_onlyFeeManager: Caller is not a fee manager");
        liquidityPoolAdapter.depositFees(1 ether);
    }

    // TEST HELPERS

    function _getLiquidityPoolsConfig(uint256 poolsCount) private view returns (LiquidityPoolConfig[] memory) {
        LiquidityPoolConfig[] memory liquidityConfig = new LiquidityPoolConfig[](poolsCount);

        liquidityConfig[0] = LiquidityPoolConfig(address(mockLiquidityPool), uint96(FULL_PERCENT));

        if (poolsCount > 1) {
            liquidityConfig[1] = LiquidityPoolConfig(address(mockLiquidityPool2), uint96(FULL_PERCENT));

            if (poolsCount > 2) {
                liquidityConfig[2] = LiquidityPoolConfig(address(mockLiquidityPool3), uint96(FULL_PERCENT / 2));
            }
        }

        return liquidityConfig;
    }

    function _dealTokensToLiquidityPools() private {
        deal(address(collateral), address(mockLiquidityPool), mockLiquidityPool.availableLiquidity(), true);
        deal(address(collateral), address(mockLiquidityPool2), mockLiquidityPool2.availableLiquidity(), true);
        deal(address(collateral), address(mockLiquidityPool3), mockLiquidityPool3.availableLiquidity(), true);
    }
}
