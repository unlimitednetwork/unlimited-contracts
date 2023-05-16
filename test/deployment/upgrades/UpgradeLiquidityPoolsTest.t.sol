// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";
import "script/UpgradeLiquidityPools.s.sol";

contract UpgradeLiquidityPoolsTest_WithDeployment_Test is WithDeployment {
    function setUp() public {
        _network = "UpgradeLiquidityPoolsTest_WithDeployment_Test";

        _deploy();
    }

    function test_upgradesLiquidityPools() public {
        address delegatorBefore = _getAddress("liquidityPoolBluechip");

        vm.prank(_getAddress("proxyAdmin"));
        address implementationBefore =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolBluechip"))).implementation();

        UpgradeLiquidityPoolsScript script = new UpgradeLiquidityPoolsScript();
        script.setNetwork(_network);
        script.run();

        address delegatorAfter = _getAddress("liquidityPoolBluechip");
        vm.prank(_getAddress("proxyAdmin"));
        address implementationAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolBluechip"))).implementation();

        vm.prank(_getAddress("proxyAdmin"));
        address implementationAltcoinAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAltcoin"))).implementation();

        assertEq(delegatorBefore, delegatorAfter, "liquidityPoolBluechip delegator should not change");
        assertTrue(implementationBefore != implementationAfter, "liquidityPoolBluechip implementation should change");
        assertEq(
            implementationAfter,
            implementationAltcoinAfter,
            "liquidityPoolBluechip and liquidityPoolAltcoin should have same implementation"
        );
    }
}
