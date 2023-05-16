// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";

contract ChangeMarginOfPositionTest is Test {
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

    function testAddMargin() public {
        position.addMargin(MARGIN_0);
        assertEq(position.margin, MARGIN_0 * 2, "margin");
        assertEq(position.volume, VOLUME_0, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(position.entryLeverage(), VOLUME_0 * LEVERAGE_MULTIPLIER / (MARGIN_0 * 2), "leverage");
    }

    function testRemoveMargin() public {
        position.removeMargin(MARGIN_0 / 2);
        assertEq(position.margin, MARGIN_0 / 2, "margin");
        assertEq(position.volume, VOLUME_0, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0, "size");
        assertEq(position.entryLeverage(), ((VOLUME_0) / (MARGIN_0 / 2)) * LEVERAGE_MULTIPLIER, "leverage");
    }

    function testShouldRevertWhenMarginWouldBeZero() public {
        vm.expectRevert("PositionMaths::_removeMargin: cannot remove more margin than available");
        position.removeMargin(MARGIN_0);
    }
}
