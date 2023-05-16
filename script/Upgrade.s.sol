// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";

contract Upgrade is Helper {
    string path;
    address _proxyAdmin;

    using Strings for string;

    function run(string memory contractName) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        string memory network = vm.envString("NETWORK");
        _proxyAdmin = _getAddress("proxyAdmin");
        path = _getPath();

        vm.startBroadcast(deployerPrivateKey);

        (address _proxy, bool isProxy) = _getAddressAndIsProxy(network, contractName);
        require(isProxy, "Upgrade::run: Contract is not a proxy.");

        ProxyAdmin proxyAdmin = ProxyAdmin(_proxyAdmin);
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(payable(_proxy));

        address implementation = _getNewImplementation(contractName);

        proxyAdmin.upgrade(proxy, implementation);

        _upgradeJson(path, contractName, _proxy, implementation);

        vm.stopBroadcast();
    }

    function run(string memory contractName, string memory id) public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        _proxyAdmin = _getAddress("proxyAdmin");
        path = _getPath();
        vm.startBroadcast(deployerPrivateKey);

        string memory contractNameWithId = string.concat(contractName, id);

        (address _proxy, bool isProxy) = _getAddressAndIsProxy(_network, contractNameWithId);
        require(isProxy, "Upgrade::run: Contract is not a proxy.");

        ProxyAdmin proxyAdmin = ProxyAdmin(_proxyAdmin);
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(payable(_proxy));

        address implementation = _getNewImplementation(contractName);

        console.log("upgrading", contractNameWithId);

        proxyAdmin.upgrade(proxy, implementation);

        _upgradeJson(path, contractNameWithId, _proxy, implementation);

        vm.stopBroadcast();
    }

    function _getNewImplementation(string memory name) internal returns (address implementation) {
        if (name.equal("unlimitedOwner")) implementation = unlimitedOwnerImplementation();
        if (name.equal("userManager")) implementation = userManagerImplementation();
        if (name.equal("feeManager")) implementation = feeManagerImplementation();
        if (name.equal("liquidityPool")) implementation = liquidityPoolImplementation();
        if (name.equal("liquidityPoolAdapter")) implementation = liquidityPoolAdapterImplementation();
        if (name.equal("tradePair")) implementation = tradePairImplementation();
    }
}
