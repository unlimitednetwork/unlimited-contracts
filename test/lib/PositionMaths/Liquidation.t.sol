// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";

contract LiquidationTest is Test {
    using PositionMaths for Position;

    Position position;

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
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: IS_SHORT_0,
            owner: msg.sender,
            assetDecimals: ASSET_DECIMALS,
            lastAlterationBlock: uint40(block.number)
        });
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
