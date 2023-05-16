// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";

contract UpgradeLiquidityPoolsScript is Helper {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER"));

        // Deploy new implementation
        address implementationAddress = liquidityPoolImplementation();

        // Upgrade all LiquidityPools
        _upgradeLiquidityPool("liquidityPoolBluechip", implementationAddress);
        _upgradeLiquidityPool("liquidityPoolAltcoin", implementationAddress);
        _upgradeLiquidityPool("liquidityPoolDegen", implementationAddress);

        vm.stopBroadcast();
    }

    function _upgradeLiquidityPool(string memory name, address implementationAddress) internal {
        // Set Up
        ProxyAdmin proxyAdmin = ProxyAdmin(_getAddress("proxyAdmin"));

        // Upgrade
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(payable(_getAddress(name))), implementationAddress);

        _upgradeJson(name, _getAddress(name), implementationAddress);
    }
}
