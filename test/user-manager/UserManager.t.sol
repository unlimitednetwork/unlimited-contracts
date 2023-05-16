// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../src/user-manager/UserManager.sol";
import "../mocks/MockUnlimitedOwner.sol";
import "../mocks/MockController.sol";
import "test/setup/Constants.sol";
import "test/setup/WithMocks.t.sol";

contract UserManagerTest is WithMocks {
    uint256 constant START_TIME = 1641070800;
    UserManager private userManager;

    uint8[7] private feeSizes = [10, 9, 8, 7, 6, 5, 4];

    uint32[6] private volumes = [1_000_000, 10_000_000, 100_000_000, 250_000_000, 500_000_000, 1_000_000_000];

    function setUp() public {
        // random time, shouldn't be less than 30 days in seconds
        vm.warp(START_TIME);

        userManager = new UserManager(mockUnlimitedOwner, mockController);
        vm.prank(UNLIMITED_OWNER);
        userManager.initialize(feeSizes, volumes);
    }

    function testGetUserVolume() public {
        uint256 userTier = uint256(userManager.getUserVolumeTier(ALICE));
        assertEq(userTier, 0);
    }

    function testGetUserFee() public {
        uint256 userFee = uint256(userManager.getUserFee(ALICE));
        assertEq(userFee, feeSizes[0]);

        for (uint256 i; i < volumes.length; i++) {
            // we can add volume on top of eachother as we know they only increase for 1 tier
            userManager.addUserVolume(ALICE, volumes[i]);

            userFee = uint256(userManager.getUserFee(ALICE));
            assertEq(userFee, feeSizes[i + 1]);
        }
    }

    function testUserManualTier() public {
        vm.prank(UNLIMITED_OWNER);
        userManager.setUserManualTier(ALICE, Tier.ONE, type(uint32).max);

        uint256 userFee = uint256(userManager.getUserFee(ALICE));
        assertEq(userFee, feeSizes[1]);
    }

    function testAddUserVolume() public {
        userManager.addUserVolume(ALICE, uint40(MILLION));
        uint256 userVolume = userManager.getUser30DaysVolume(ALICE);
        assertEq(userVolume, MILLION);
    }

    function testAddUserVolume_Twice() public {
        userManager.addUserVolume(ALICE, uint40(MILLION));
        userManager.addUserVolume(ALICE, uint40(MILLION));
        uint256 userVolume = userManager.getUser30DaysVolume(ALICE);
        assertEq(userVolume, MILLION * 2);
    }

    function testAddUserVolume_SeparateDays() public {
        userManager.addUserVolume(ALICE, uint40(MILLION));
        vm.warp(START_TIME + 1 days);
        userManager.addUserVolume(ALICE, uint40(MILLION));
        uint256 userVolume = userManager.getUser30DaysVolume(ALICE);
        assertEq(userVolume, MILLION * 2);
    }

    function testAddUserVolume_31daysApart() public {
        userManager.addUserVolume(ALICE, uint40(MILLION));
        vm.warp(START_TIME + 31 days);
        userManager.addUserVolume(ALICE, uint40(MILLION));
        uint256 userVolume = userManager.getUser30DaysVolume(ALICE);
        assertEq(userVolume, MILLION);
    }

    function testAddUserVolume_AddEveryDay() public {
        // add a million every day for 30 days
        for (uint256 i = 0; i < 30; i++) {
            vm.warp(START_TIME + (i * 1 days));
            userManager.addUserVolume(ALICE, uint40(MILLION));
        }
        uint256 userVolume = userManager.getUser30DaysVolume(ALICE);
        assertEq(userVolume, MILLION * 30);

        // add a million every day for 10 days
        for (uint256 i = 30; i < 40; i++) {
            vm.warp(START_TIME + (i * 1 days));
            userManager.addUserVolume(ALICE, uint40(MILLION));
            userVolume = userManager.getUser30DaysVolume(ALICE);
            assertEq(userVolume, MILLION * 30);
        }

        // pass time for 30 days without adding volume
        for (uint256 i = 40; i < 70; i++) {
            vm.warp(START_TIME + (i * 1 days));
            userVolume = userManager.getUser30DaysVolume(ALICE);
            assertEq(userVolume, MILLION * (69 - i));
        }
    }

    function testInitialize() public {
        // ARRANGE
        userManager = new UserManager(mockUnlimitedOwner, mockController);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.initialize(feeSizes, volumes);

        // ASSERT
        (uint8 baseFeeSize,,,,,, uint8 feeSize6) = userManager.feeSizes();
        (uint40 volume1,,,,, uint40 volume6) = userManager.feeVolumes();

        assertEq(baseFeeSize, feeSizes[0], "baseFeeSize");
        assertEq(volume1, volumes[0], "baseFeeVolume");
        assertEq(feeSize6, feeSizes[6], "feeSize6");
        assertEq(volume6, volumes[5], "feeVolume6");
    }

    function testSetFeeSizes() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](2);
        newFeeSizes[0] = 99;
        newFeeSizes[1] = 88;
        uint256[] memory feeIndexes = new uint256[](2);
        feeIndexes[0] = 0;
        feeIndexes[1] = 6;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.setFeeSizes(feeIndexes, newFeeSizes);

        // ASSERT
        (uint8 baseFeeSize, uint8 oldFee1,,,,, uint8 feeSize6) = userManager.feeSizes();

        assertEq(baseFeeSize, newFeeSizes[0], "baseFeeSize");
        assertEq(oldFee1, feeSizes[1], "oldFee1");
        assertEq(feeSize6, newFeeSizes[1], "feeSize6");
    }

    function testFeeDiscount() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](1);
        newFeeSizes[0] = 5;
        uint256[] memory feeIndexes = new uint256[](1);
        feeIndexes[0] = 0;
        vm.prank(UNLIMITED_OWNER);
        userManager.setFeeSizes(feeIndexes, newFeeSizes);

        // ACT & ASSERT
        // should be discounted fee of 5
        assertEq(userManager.getUserFee(ALICE), newFeeSizes[0], "userFee no volume");

        // should be discounted fee of 5
        userManager.addUserVolume(ALICE, uint40(250_000_000));
        assertEq(userManager.getUserFee(ALICE), newFeeSizes[0], "userFee volume 250_000_000, tier 4");

        // When user is in last tier, fee should be less than discount
        // should be fee of 4
        userManager.addUserVolume(ALICE, uint40(750_000_000));
        assertEq(userManager.getUserFee(ALICE), feeSizes[6], "userFee volume 1_000_000_000, tier 6");
    }

    function testInvalidFeeIndex() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](1);
        newFeeSizes[0] = 5;
        uint256[] memory feeIndexes = new uint256[](1);
        feeIndexes[0] = 7;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::_setFeeSize: Invalid fee index");
        userManager.setFeeSizes(feeIndexes, newFeeSizes);
    }

    function testInvalidVolumeIndex() public {
        // ARRANGE
        uint32[] memory newVolumes = new uint32[](1);
        newVolumes[0] = 99;
        uint256[] memory feeIndexes = new uint256[](1);
        feeIndexes[0] = 7;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::_setFeeVolume: Invalid fee index");
        userManager.setFeeVolumes(feeIndexes, newVolumes);

        // ACT 2
        feeIndexes[0] = 0;
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::_setFeeVolume: Invalid fee index");
        userManager.setFeeVolumes(feeIndexes, newVolumes);
    }

    function testUserReferrer() public {
        // ARRANGE
        address referrer = address(0x1234);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.setUserReferrer(ALICE, referrer);

        // ASSERT
        assertEq(userManager.getUserReferrer(ALICE), referrer, "referrer");
    }

    function testNoReferrerAddress() public {
        // ARRANGE
        address referrer = address(0x0);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.setUserReferrer(ALICE, referrer);

        // ASSERT
        assertEq(userManager.getUserReferrer(ALICE), address(0x0), "referrer");
    }

    function testCannotOverwriteUserReferrer() public {
        // ARRANGE
        address referrer = address(0x1234);
        address newReferrer = address(0x5678);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.setUserReferrer(ALICE, referrer);
        userManager.setUserReferrer(ALICE, newReferrer);

        // ASSERT
        assertEq(userManager.getUserReferrer(ALICE), referrer, "referrer");
    }

    function testSetFeeVolumes() public {
        // ARRANGE
        uint32[] memory newVolumes = new uint32[](2);
        newVolumes[0] = 99;
        newVolumes[1] = 88;
        uint256[] memory feeIndexes = new uint256[](2);
        feeIndexes[0] = 1;
        feeIndexes[1] = 6;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        userManager.setFeeVolumes(feeIndexes, newVolumes);

        // ASSERT
        (uint40 volume1,,,,, uint40 volume6) = userManager.feeVolumes();

        assertEq(volume1, newVolumes[0], "volume1");
        assertEq(volume6, newVolumes[1], "volume6");
    }

    function testOnlyOwner() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](1);
        newFeeSizes[0] = 5;
        uint256[] memory feeIndexes = new uint256[](1);
        feeIndexes[0] = 0;

        // ACT
        vm.prank(address(0x1234));
        vm.expectRevert("UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
        userManager.setFeeSizes(feeIndexes, newFeeSizes);
    }

    function testOnlyValidTradePair() public {
        // ARRANGE
        vm.mockCall(
            address(mockController), abi.encodeWithSelector(IController.isTradePair.selector), abi.encode(false)
        );

        // ACT
        vm.expectRevert("UserManager::_onlyValidTradePair: Trade pair is not valid");
        userManager.addUserVolume(ALICE, uint40(500_000_000));
    }

    function testMaxFeeSize() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](1);
        newFeeSizes[0] = 101;

        uint256[] memory feeIndexes = new uint256[](1);
        feeIndexes[0] = 0;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::_setFeeSize: Fee size is too high");
        userManager.setFeeSizes(feeIndexes, newFeeSizes);
    }

    function testSetFeeSizesWrongLengths() public {
        // ARRANGE
        uint8[] memory newFeeSizes = new uint8[](1);
        newFeeSizes[0] = 5;
        uint256[] memory feeIndexes = new uint256[](2);
        feeIndexes[0] = 0;
        feeIndexes[1] = 1;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::setFeeSizes: Array lengths don't match");
        userManager.setFeeSizes(feeIndexes, newFeeSizes);
    }

    function testSetFeeVolumesWrongLengths() public {
        // ARRANGE
        uint32[] memory newVolumes = new uint32[](1);
        newVolumes[0] = 99;
        uint256[] memory feeIndexes = new uint256[](2);
        feeIndexes[0] = 0;
        feeIndexes[1] = 1;

        // ACT
        vm.prank(UNLIMITED_OWNER);
        vm.expectRevert("UserManager::setFeeVolumes: Array lengths don't match");
        userManager.setFeeVolumes(feeIndexes, newVolumes);
    }

    function testUserFee() public {
        // ASSERT
        assertEq(userManager.getUserFee(ALICE), 10, "user fee");

        // ACT: Move user to next fee level
        userManager.addUserVolume(ALICE, uint40(1_000_000));
        assertEq(userManager.getUserFee(ALICE), 9, "user fee");
    }

    function testUserCannotBeReferrer() public {
        // ASSERT
        vm.expectRevert("UserManager::setUserReferrer: User cannot be referrer");
        userManager.setUserReferrer(ALICE, ALICE);
    }
}
