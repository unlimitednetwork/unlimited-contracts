// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";

contract UpgradeLiquidityPoolAdaptersScript is Helper {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER"));

        // Deploy new implementation
        address implementationAddress = liquidityPoolAdapterImplementation();

        // Upgrade all LiquidityPoolAdapters
        _upgradeLiquidityPoolAdapter("liquidityPoolAdapterBluechip", implementationAddress);
        _upgradeLiquidityPoolAdapter("liquidityPoolAdapterAltcoin", implementationAddress);

        vm.stopBroadcast();
    }

    function _upgradeLiquidityPoolAdapter(string memory name, address implementationAddress) internal {
        // Set Up
        ProxyAdmin proxyAdmin = ProxyAdmin(_getAddress("proxyAdmin"));

        // Upgrade
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(payable(_getAddress(name))), implementationAddress);

        _upgradeJson(name, _getAddress(name), implementationAddress);
    }
}
