// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";

contract UpgradeTradePairsScript is Helper {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER"));

        // Deploy new implementation
        address implementationAddress = tradePairImplementation();

        // Upgrade all TradePairs
        _upgradeTradePair("tradePairBTC", implementationAddress);
        _upgradeTradePair("tradePairETH", implementationAddress);
        _upgradeTradePair("tradePairLINK", implementationAddress);

        vm.stopBroadcast();
    }

    function _upgradeTradePair(string memory name, address implementationAddress) internal {
        // Set Up
        ProxyAdmin proxyAdmin = ProxyAdmin(_getAddress("proxyAdmin"));

        // Upgrade
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(payable(_getAddress(name))), implementationAddress);

        _upgradeJson(name, _getAddress(name), implementationAddress);
    }
}
