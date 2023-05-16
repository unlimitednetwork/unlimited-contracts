// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "test/setup/Constants.sol";
import "src/sys-controller/UnlimitedOwner.sol";

contract UnlimitedOwnerTest is Test {
    UnlimitedOwner unlimitedOwner;

    function setUp() public {
        vm.startPrank(UNLIMITED_OWNER);
        unlimitedOwner =
            UnlimitedOwner(address(new TransparentUpgradeableProxy(address(new UnlimitedOwner()), address(1), "")));

        unlimitedOwner.initialize();
    }

    function testInitialize() public {
        unlimitedOwner =
            UnlimitedOwner(address(new TransparentUpgradeableProxy(address(new UnlimitedOwner()), address(1), "")));

        unlimitedOwner.initialize();

        vm.expectRevert("Initializable: contract is already initialized");
        unlimitedOwner.initialize();
    }

    function testIsUnlimitedOwner() public {
        assertTrue(unlimitedOwner.isUnlimitedOwner(UNLIMITED_OWNER));
        assertFalse(unlimitedOwner.isUnlimitedOwner(address(0)));
    }

    function testOwner() public {
        assertEq(unlimitedOwner.owner(), UNLIMITED_OWNER);
    }

    function testRenounceOwnership() public {
        vm.expectRevert("UnlimitedOwner::renounceOwnership: Cannot renounce Unlimited ownership");
        unlimitedOwner.renounceOwnership();
    }
}
