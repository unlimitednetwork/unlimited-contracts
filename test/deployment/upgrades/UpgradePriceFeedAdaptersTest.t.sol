// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";
import "script/UpgradePriceFeedAdapters.s.sol";

contract UpgradePriceFeedAdaptersTest_WithDeployment_Test is WithDeployment {
    function setUp() public {
        _network = "UpgradePriceFeedAdaptersTest_WithDeployment_Test";

        _deploy();
    }

    function test_upgradesPriceFeedAdapters() public {
        address delegatorBefore = _getAddress("priceFeedAdapterBTC");

        vm.prank(_getAddress("proxyAdmin"));
        address implementationBefore =
            ITransparentUpgradeableProxy(payable(_getAddress("priceFeedAdapterBTC"))).implementation();

        UpgradePriceFeedAdaptersScript script = new UpgradePriceFeedAdaptersScript();
        script.setNetwork(_network);
        script.run();

        address delegatorAfter = _getAddress("priceFeedAdapterBTC");
        vm.prank(_getAddress("proxyAdmin"));
        address implementationAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("priceFeedAdapterBTC"))).implementation();

        vm.prank(_getAddress("proxyAdmin"));
        address implementationETHAfter =
            ITransparentUpgradeableProxy(payable(_getAddress("priceFeedAdapterETH"))).implementation();

        assertEq(delegatorBefore, delegatorAfter, "priceFeedAdapterBTC delegator should not change");
        assertTrue(implementationBefore != implementationAfter, "priceFeedAdapterBTC implementation should change");
        assertEq(
            implementationAfter,
            implementationETHAfter,
            "priceFeedAdapterBTC and priceFeedAdapterETH should have same implementation"
        );
    }
}
