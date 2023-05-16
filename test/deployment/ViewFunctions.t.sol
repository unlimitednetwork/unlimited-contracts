// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Solarray} from "test/setup/Solarray.sol";
import "test/setup/WithDeployment.t.sol";

contract ViewFunctions_WithDeployment_Test is WithDeployment {
    uint256 highLiquidityAmount = liquidityAmount * 1e30;

    function setUp() public {
        _network = "ViewFunctions_WithDeployment_Test";

        _deploy();

        // increase volume limit
        vm.startPrank(vm.addr(vm.envUint("DEPLOYER")));
        tradePairBtc.setVolumeLimit(1e70);
        tradePairBtc.setTotalVolumeLimit(1e70);
        vm.stopPrank();

        deal(address(collateral), ALICE, highLiquidityAmount);
        _depositLiquidity("liquidityPoolBluechip", ALICE, highLiquidityAmount);
    }

    function testFail_isLiquidatableAtPrice_PositionDoesNotExist() public view {
        uint256[][] memory positions = new uint256[][](1);
        positions[0] = Solarray.uint256s(1);

        tradeManager.canLiquidatePositionsAtPrices(
            Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(BTC_PRICE)
        )[0][0];
    }

    function test_isLiquidatableAtPrice() public {
        int256 liquidationPrice = BTC_PRICE * 6 / 5;

        _updatePrice("BTC", BTC_PRICE);

        deal(address(collateral), BOB, INITIAL_BALANCE);

        positionId = _openPosition(BOB_PK, "BTC", INITIAL_BALANCE, LEVERAGE_0, true);

        uint256[][] memory positions = new uint256[][](1);
        positions[0] = Solarray.uint256s(0);

        // Should not be liquidatable at entryPrice
        assertFalse(
            tradeManager.canLiquidatePositionsAtPrices(
                Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(BTC_PRICE)
            )[0][0]
        );

        // Should be liquidatable at liquidationPrice
        assertTrue(
            tradeManager.canLiquidatePositionsAtPrices(
                Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(liquidationPrice)
            )[0][0]
        );
    }

    function test_isLiquidatableAtPrice_AfterFee() public {
        int256 liquidationPriceAfterFee = BTC_PRICE * 11 / 10;

        _updatePrice("BTC", BTC_PRICE);

        deal(address(collateral), BOB, INITIAL_BALANCE);

        positionId = _openPosition(BOB_PK, "BTC", INITIAL_BALANCE, LEVERAGE_0, true);

        uint256[][] memory positions = new uint256[][](1);
        positions[0] = Solarray.uint256s(0);

        // Initially should NOT be liquidatable at liquidationPriceAfterFee
        assertFalse(
            tradeManager.canLiquidatePositionsAtPrices(
                Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(liquidationPriceAfterFee)
            )[0][0],
            "initially not liquidatable"
        );

        vm.roll(4);
        vm.warp(1200 hours);

        // After fee SHOULD be liquidatable at entryPrice
        assertTrue(
            tradeManager.canLiquidatePositionsAtPrices(
                Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(liquidationPriceAfterFee)
            )[0][0],
            "after fee liquidatable"
        );

        // Should NOT be liquidatable at entryPrice
        assertFalse(
            tradeManager.canLiquidatePositionsAtPrices(
                Solarray.addresses(_getAddress("tradePairBTC")), positions, Solarray.int256s(BTC_PRICE)
            )[0][0],
            "after fee not liquidatable at entry price"
        );
    }
}
