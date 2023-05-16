// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";

contract UpgradePriceFeedAdaptersScript is Helper {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER"));

        // Deploy new implementation
        address implementationAddress = priceFeedAdapterImplementation();

        // Upgrade all PriceFeedAdapters
        _upgradePriceFeedAdapter("priceFeedAdapterBTC", implementationAddress);
        _upgradePriceFeedAdapter("priceFeedAdapterETH", implementationAddress);
        _upgradePriceFeedAdapter("priceFeedAdapterLINK", implementationAddress);

        vm.stopBroadcast();
    }

    function _upgradePriceFeedAdapter(string memory name, address implementationAddress) internal {
        // Set Up
        ProxyAdmin proxyAdmin = ProxyAdmin(_getAddress("proxyAdmin"));

        // Upgrade
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(payable(_getAddress(name))), implementationAddress);

        _upgradeJson(name, _getAddress(name), implementationAddress);
    }
}
