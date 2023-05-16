// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionStats.sol";
import "test/setup/Constants.sol";

contract PositionStatsTotalCountTest is Test {
    PositionStats positionStats;

    using PositionStatsLib for PositionStats;

    function setUp() public {}

    function testTotalCountLong() public {
        assertEq(positionStats.totalLongMargin, 0, "totalLongMargin 0");
        assertEq(positionStats.totalLongVolume, 0, "totalLongVolume 0");
        assertEq(positionStats.totalLongAssetAmount, 0, "totalLongAssetAmount 0");
        positionStats.addTotalCount(MARGIN_0, VOLUME_0, ASSET_AMOUNT_0, IS_SHORT_0);
        assertEq(positionStats.totalLongMargin, MARGIN_0, "totalLongMargin");
        assertEq(positionStats.totalLongVolume, VOLUME_0, "totalLongVolume");
        assertEq(positionStats.totalLongAssetAmount, ASSET_AMOUNT_0, "totalLongAssetAmount");
        positionStats.removeTotalCount(MARGIN_0, VOLUME_0, ASSET_AMOUNT_0, IS_SHORT_0);
        assertEq(positionStats.totalLongMargin, 0, "totalLongMargin 0 after");
        assertEq(positionStats.totalLongVolume, 0, "totalLongVolume 0 after");
        assertEq(positionStats.totalLongAssetAmount, 0, "totalLongAssetAmount 0 after");
    }

    function testTotalCountShort() public {
        assertEq(positionStats.totalShortMargin, 0, "totalShortMargin 0");
        assertEq(positionStats.totalShortVolume, 0, "totalShortVolume 0");
        assertEq(positionStats.totalShortAssetAmount, 0, "totalShortAssetAmount 0");
        positionStats.addTotalCount(MARGIN_0, VOLUME_0, ASSET_AMOUNT_0, IS_SHORT_1);
        assertEq(positionStats.totalShortMargin, MARGIN_0, "totalShortMargin");
        assertEq(positionStats.totalShortVolume, VOLUME_0, "totalShortVolume");
        assertEq(positionStats.totalShortAssetAmount, ASSET_AMOUNT_0, "totalShortAssetAmount");
        positionStats.removeTotalCount(MARGIN_0, VOLUME_0, ASSET_AMOUNT_0, IS_SHORT_1);
        assertEq(positionStats.totalShortMargin, 0, "totalShortMargin 0 after");
        assertEq(positionStats.totalShortVolume, 0, "totalShortVolume 0 after");
        assertEq(positionStats.totalShortAssetAmount, 0, "totalShortAssetAmount 0 after");
    }
}
