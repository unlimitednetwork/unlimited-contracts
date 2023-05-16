// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";

contract StressTest_WithDeployment_Test is WithDeployment {
    uint256 highLiquidityAmount = liquidityAmount * 1e30;
    uint256 highInitialBalance = INITIAL_BALANCE * 1e14;
    int256 highPrice = BTC_PRICE * 1e12;

    function setUp() public {
        _network = "StressTest_WithDeployment_Test";

        _deploy();

        // increase volume limit
        vm.startPrank(vm.addr(vm.envUint("DEPLOYER")));
        tradePairBtc.setVolumeLimit(1e70);
        tradePairBtc.setTotalVolumeLimit(1e70);
        vm.stopPrank();

        deal(address(collateral), ALICE, highLiquidityAmount);
        _depositLiquidity("liquidityPoolBluechip", ALICE, highLiquidityAmount);

        // OPEN POSITION
        deal(address(collateral), BOB, highInitialBalance);
        positionId = _openPosition(BOB_PK, "BTC", highInitialBalance, LEVERAGE_0, false);
        vm.roll(2);

        _updatePrice("BTC", highPrice);
    }

    function test_closePosition() public {
        _closePosition(BOB_PK, "BTC", positionId);

        // Only one simple assert to test if high values are accepted
        assertEq(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005, "bob");
    }

    function test_partiallyClosePosition() public {
        _partiallyClosePosition(BOB_PK, "BTC", positionId, 500_000);

        // Only one simple assert to test if high values are accepted
        assertEq(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005 / 2, "bob");
    }

    function test_extendPosition() public {
        deal(address(collateral), BOB, MARGIN_0 * 1002 * 1e10);
        _extendPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 1002 * 1e10, LEVERAGE_0);

        vm.roll(3);

        _closePosition(BOB_PK, "BTC", positionId);

        // Only one simple assert to test if high values are accepted
        assertGt(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005, "bob");
    }

    function test_extendPositionToLeverage() public {
        _extendPositionToLeverage(BOB_PK, "BTC", positionId, 100_000_000);

        vm.roll(3);

        _closePosition(BOB_PK, "BTC", positionId);

        // Only one simple assert to test if high values are accepted
        assertLt(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005, "bob");
    }

    function test_addMarginToPosition() public {
        deal(address(collateral), BOB, MARGIN_0 * 1002 * 1e10);
        _addMarginToPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 1002 * 1e10);

        vm.roll(3);

        _closePosition(BOB_PK, "BTC", positionId);

        // Only one simple assert to test if high values are accepted
        assertGt(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005, "bob");
    }

    function test_removeMarginFromPosition() public {
        _removeMarginFromPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 1002 * 1e10);

        vm.roll(3);

        _closePosition(BOB_PK, "BTC", positionId);

        // Only one simple assert to test if high values are accepted
        assertEq(collateral.balanceOf(BOB), highInitialBalance * 998 / 1005, "bob");
    }
}
