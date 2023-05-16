// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";
import "script/UpgradeLiquidityPoolAdapters.s.sol";

contract UpgradeLiquidityPoolAdaptersTest_WithDeployment_Test is WithDeployment {
    function setUp() public {
        _network = "UpgradeLiquidityPoolAdaptersTest_WithDeployment_Test";

        _deploy();
    }

    function test_upgradesLiquidityPoolAdapters() public {
        address delegatorBefore = _getAddress("liquidityPoolAdapterBluechip");

        vm.prank(_getAddress("proxyAdmin"));
        address implementationBefore =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAdapterBluechip"))).implementation();

        UpgradeLiquidityPoolAdaptersScript script = new UpgradeLiquidityPoolAdaptersScript();
        script.setNetwork(_network);
        script.run();

        address delegatorAfter = _getAddress("liquidityPoolAdapterBluechip");
        vm.prank(_getAddress("proxyAdmin"));
        address implementationAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAdapterBluechip"))).implementation();

        vm.prank(_getAddress("proxyAdmin"));
        address implementationAltcoinAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAdapterAltcoin"))).implementation();

        assertEq(delegatorBefore, delegatorAfter, "liquidityPoolAdapterBluechip delegator should not change");
        assertTrue(
            implementationBefore != implementationAfter, "liquidityPoolAdapterBluechip implementation should change"
        );
        assertEq(
            implementationAfter,
            implementationAltcoinAfter,
            "liquidityPoolAdapterBluechip and liquidityPoolAdapterAltcoin should have same implementation"
        );
    }
}
