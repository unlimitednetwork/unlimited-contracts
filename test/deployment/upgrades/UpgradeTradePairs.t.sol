// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";
import "script/UpgradeTradePairs.s.sol";

contract UpgradeTradePairsTest_WithDeployment_Test is WithDeployment {
    function setUp() public {
        _network = "UpgradeTradePairsTest_WithDeployment_Test";

        _deploy();
    }

    function test_upgradesTradePairs() public {
        address delegatorBefore = _getAddress("tradePairBTC");

        vm.prank(_getAddress("proxyAdmin"));
        address implementationBefore =
            ITransparentUpgradeableProxy(payable(_getAddress("tradePairBTC"))).implementation();

        UpgradeTradePairsScript script = new UpgradeTradePairsScript();
        script.setNetwork(_network);
        script.run();

        address delegatorAfter = _getAddress("tradePairBTC");
        vm.prank(_getAddress("proxyAdmin"));
        address implementationAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("tradePairBTC"))).implementation();

        vm.prank(_getAddress("proxyAdmin"));
        address implementationETHAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("tradePairETH"))).implementation();

        assertEq(delegatorBefore, delegatorAfter, "tradePairBTC delegator should not change");
        assertTrue(implementationBefore != implementationAfter, "tradePairBTC implementation should change");
        assertEq(
            implementationAfter, implementationETHAfter, "tradePairBTC and tradePairETH should have same implementation"
        );
    }
}
