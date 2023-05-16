// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";
import "test/setup/WithPositionMaths.t.sol";

contract LiquidationTest is Test, WithPositionMaths {
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
            isShort: IS_SHORT_0,
            owner: msg.sender,
            lastAlterationBlock: uint40(block.number)
        });
    }

    function testIsNotdirectlyLiquidatable() public {
        assertFalse(position.isLiquidatable(ASSET_PRICE_0, 0, 0, 0), "liquidatable");
    }

    function testCanNotBeLiquidated() public {
        assertEq(position.currentNetEquity(ASSET_PRICE_0_2, 0, 0), int256(MARGIN_0 / 2), "current net equity");
        assertFalse(position.isLiquidatable(ASSET_PRICE_0_2, 0, 0, 0), "liquidatable");
    }

    function testCanBeLiquidated() public {
        assertEq(position.currentNetEquity(ASSET_PRICE_0_3, 0, 0), 0, "current net equity");
        assertEq(position.isLiquidatable(ASSET_PRICE_0_3, 0, 0, 0), true, "liquidatable");
    }

    function testAbsoluteMaintenanceMargin() public {
        assertEq(position.isLiquidatable(ASSET_PRICE_0_2, 0, 0, 0), false, "liquidatable");

        assertEq(position.isLiquidatable(ASSET_PRICE_0_2, 0, 0, MARGIN_0), true, "liquidatable");
    }
}
