// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";

contract StressTest_Price_WithDeployment_Test is WithDeployment {
    uint256 highLiquidityAmount = 1e15 * 1e6;
    uint256 highInitialBalance = INITIAL_BALANCE * 1e14;
    int256 highPrice = BTC_PRICE * 1e12;

    function setUp() public {
        _network = "StressTest_Price_WithDeployment_Test";

        _deploy();

        // increase volume limit
        vm.startPrank(vm.addr(vm.envUint("DEPLOYER")));
        tradePairBtc.setVolumeLimit(1e70);
        tradePairBtc.setTotalVolumeLimit(1e70);
        vm.stopPrank();

        deal(address(collateral), ALICE, highLiquidityAmount);
        _depositLiquidity("liquidityPoolBluechip", ALICE, highLiquidityAmount);
    }

    function test_worksWithLowPrices() public {
        // $0.0000109
        int256 shibaInuPrice = 0.000_010_88 * 1e8 * int256(PRICE_MULTIPLIER) / 1e8; // 10_880_000_000_000
        uint256 lowMargin = 10.02 * 1e6;

        vm.roll(3);
        vm.warp(3 hours);

        _updatePrice("BTC", shibaInuPrice);

        assertEq(collateral.balanceOf(BOB), 0, "bob zero");

        // Open a position with $10
        deal(address(collateral), BOB, lowMargin);

        positionId = _openPosition(BOB_PK, "BTC", lowMargin, LEVERAGE_0, true);

        vm.roll(4);
        vm.warp(4 hours);

        _updatePrice("BTC", shibaInuPrice / 2);

        _closePosition(BOB_PK, "BTC", positionId);

        // Should have made 500% profit
        // Just testing BOB received some profit, as fees applied
        assertGt(collateral.balanceOf(BOB), lowMargin * 2, "bob");
    }

    function test_worksWithNormalPricesAndHighMargins() public {
        int256 normalPrice = 200 * int256(PRICE_MULTIPLIER);
        uint256 highMargin = 1 * 1e12 * 1e6;

        vm.roll(3);
        vm.warp(3 hours);

        _updatePrice("BTC", normalPrice);

        assertEq(collateral.balanceOf(BOB), 0, "bob zero");

        // Open a position with $10
        deal(address(collateral), BOB, highMargin);

        positionId = _openPosition(BOB_PK, "BTC", highMargin, LEVERAGE_0, true);

        vm.roll(4);
        vm.warp(4 hours);

        _updatePrice("BTC", normalPrice / 2);

        _closePosition(BOB_PK, "BTC", positionId);

        // Should have made 500% profit
        // Just testing BOB received some profit, as fees applied
        assertGt(collateral.balanceOf(BOB), highMargin * 2, "bob");
        assertGt(collateral.balanceOf(BOB), highMargin * 2, "bob");
    }

    function test_worksWithLowPricesAndHighMargins() public {
        // $0.0000109
        int256 shibaInuPrice = 0.000_010_88 * 1e8 * int256(PRICE_MULTIPLIER) / 1e8; // 10_880_000_000_000
        uint256 highMargin = 1 * 1e12 * 1e6;

        vm.roll(3);
        vm.warp(3 hours);

        _updatePrice("BTC", shibaInuPrice);

        assertEq(collateral.balanceOf(BOB), 0, "bob zero");

        // Open a position with $10
        deal(address(collateral), BOB, highMargin);

        positionId = _openPosition(BOB_PK, "BTC", highMargin, LEVERAGE_0, true);

        vm.roll(4);
        vm.warp(4 hours);

        _updatePrice("BTC", shibaInuPrice / 2);

        _closePosition(BOB_PK, "BTC", positionId);

        // Should have made 500% profit
        // Just testing BOB received some profit, as fees applied
        assertGt(collateral.balanceOf(BOB), highMargin * 2, "bob");
    }

    function test_worksWithHighPricesAndLowMargins() public {
        // $0.0000109
        int256 btcToTheMoonPrice = 1e9 * int256(PRICE_MULTIPLIER);
        uint256 lowMargin = 10.02 * 1e6;

        vm.roll(3);
        vm.warp(3 hours);

        _updatePrice("BTC", btcToTheMoonPrice);

        assertEq(collateral.balanceOf(BOB), 0, "bob zero");

        // Open a position with $10
        deal(address(collateral), BOB, lowMargin);

        positionId = _openPosition(BOB_PK, "BTC", lowMargin, LEVERAGE_0, true);

        vm.roll(4);
        vm.warp(4 hours);

        _updatePrice("BTC", btcToTheMoonPrice / 2);

        _closePosition(BOB_PK, "BTC", positionId);

        // Should have made 500% profit
        // Just testing BOB received some profit, as fees applied
        assertGt(collateral.balanceOf(BOB), lowMargin * 2, "bob");
    }

    function test_worksWithHighPricesAndHighMargins() public {
        // $0.0000109
        int256 btcToTheMoonPrice = 1e9 * int256(PRICE_MULTIPLIER);
        uint256 highMargin = 1 * 1e12 * 1e6;

        vm.roll(3);
        vm.warp(3 hours);

        _updatePrice("BTC", btcToTheMoonPrice);

        assertEq(collateral.balanceOf(BOB), 0, "bob zero");

        // Open a position with $10
        deal(address(collateral), BOB, highMargin);

        positionId = _openPosition(BOB_PK, "BTC", highMargin, LEVERAGE_0, true);

        vm.roll(4);
        vm.warp(4 hours);

        _updatePrice("BTC", btcToTheMoonPrice / 2);

        _closePosition(BOB_PK, "BTC", positionId);

        // Should have made 500% profit
        // Just testing BOB received some profit, as fees applied
        assertGt(collateral.balanceOf(BOB), highMargin * 2, "bob");
    }
}
