// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "src/fee-manager/FeeManager.sol";
import "src/liquidity-pools/LiquidityPool.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";
import "src/price-feed/PriceFeedAggregator.sol";
import "src/price-feed/UnlimitedPriceFeedAdapter.sol";
import "src/sys-controller/Controller.sol";
import "src/sys-controller/UnlimitedOwner.sol";
import "src/trade-manager/TradeManagerOrders.sol";
import "src/trade-pair/TradePair.sol";
import "src/trade-pair/TradePairHelper.sol";
import "src/user-manager/UserManager.sol";
import "script/config/testnet.sol";

contract Helper is Script {
    using stdJson for string;
    using Strings for *;

    uint256 constant ORDER_PERIOD = 1 days;
    string constant ROOT = "root";
    string constant PROXY = "proxy";

    string _network;
    string constant GET_PRICE_SCRIPT = "script/external/getPrice.sh";

    struct ProxyGroup {
        address delegator;
        address implementation;
    }

    function setNetwork(string memory network_) public {
        _network = network_;
    }

    function _sign(uint256 signerPk_, bytes32 dataHash_) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk_, dataHash_);
        return abi.encodePacked(r, s, v);
    }

    function _getAddress(string memory name) internal view returns (address _address) {
        (_address,) = _getAddressAndIsProxy(_network, name);
    }

    function _getAddress(string memory network, string memory name) internal view returns (address _address) {
        (_address,) = _getAddressAndIsProxy(network, name);
    }

    function _getAddressAndIsProxy(string memory network, string memory name) internal view returns (address, bool) {
        string memory path = string.concat(vm.projectRoot(), "/deploy/contracts.", network, ".json");

        string memory json = vm.readFile(path);
        bytes memory data = json.parseRaw(string.concat(".", name));
        if (data.length > keccak256("").length) {
            ProxyGroup memory proxy = abi.decode(data, (ProxyGroup));
            return (proxy.delegator, true);
        }
        return (abi.decode(data, (address)), false);
    }

    function _deployProxy(address implementation, ProxyAdmin proxyAdmin) internal returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            ""
        );
        return address(proxy);
    }

    function _getConstant(string memory name) internal view returns (address) {
        return _getConstant(_network, name);
    }

    /// @dev Reads constants for network. If no constant file is found, a test is assumed and the local constants are used
    function _getConstant(string memory network, string memory name) internal view returns (address) {
        string memory json;

        try vm.readFile(string.concat(vm.projectRoot(), "/deploy/constants.", network, ".json")) returns (
            string memory _json
        ) {
            json = _json;
        } catch {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deploy/constants.", "local", ".json"));
        }
        bytes memory data = json.parseRaw(string.concat(".", name));
        return abi.decode(data, (address));
    }

    function _startJson(string memory path, string memory network, uint256 startBlock) internal {
        // forgefmt: disable-start
        _writeJson(path, "network", network);
        _writeJson(path, "startBlock", startBlock);
        // forgefmt: disable-end
    }

    function _writeJson(string memory path, string memory key, string memory value) internal {
        string memory json = vm.serializeString(ROOT, key, value);
        vm.writeJson(json, path);
    }

    function _writeJson(string memory path, string memory key, uint256 value) internal {
        string memory json = vm.serializeUint(ROOT, key, value);
        vm.writeJson(json, path);
    }

    function _writeJson(string memory path, string memory key, address value) internal {
        string memory json = vm.serializeAddress(ROOT, key, value);
        vm.writeJson(json, path);
    }

    function _writeJson(string memory path, string memory key, address proxy, address implementation) internal {
        // create the inner JSON object
        string memory innerJson;
        innerJson = vm.serializeAddress(PROXY, "implementation", implementation);
        innerJson = vm.serializeAddress(PROXY, "delegator", proxy);

        // add the inner object to the JSON file
        string memory json = ROOT.serialize(key, innerJson);

        // write the JSON file
        vm.writeJson(json, path);
    }

    function _upgradeJson(string memory path, string memory key, address proxy, address implementation) internal {
        // create the inner JSON object
        string memory innerJson;
        innerJson = vm.serializeAddress(PROXY, "implementation", implementation);
        innerJson = vm.serializeAddress(PROXY, "delegator", proxy);

        // replace the inner object in the JSON file
        vm.writeJson(innerJson, path, string.concat(".", key));
    }

    function _upgradeJson(string memory key, address proxy, address implementation) internal {
        // create the inner JSON object
        string memory innerJson;
        innerJson = vm.serializeAddress(PROXY, "implementation", implementation);
        innerJson = vm.serializeAddress(PROXY, "delegator", proxy);

        // replace the inner object in the JSON file
        vm.writeJson(innerJson, _getPath(), string.concat(".", key));
    }

    function _getPath() internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deploy/contracts.", _network, ".json");
    }

    function _updatePriceData(uint256 signerPK, string memory id) internal {
        // always use testnet data to get price
        address tradePair = _getAddress("arbitrum-goerli", string.concat("tradePair", id));
        address priceFeedAdapter = _getAddress(string.concat("priceFeedAdapter", id));

        string[] memory command = new string[](2);
        command[0] = string.concat("./", GET_PRICE_SCRIPT);
        command[1] = tradePair.toHexString();

        bytes memory result = vm.ffi(command);
        int192 price = int192(vm.parseInt(string(result)));

        PriceData memory priceData =
            PriceData({createdOn: uint32(block.timestamp), validTo: type(uint32).max, price: price});

        bytes memory priceSignature = _sign(signerPK, keccak256(abi.encode(priceFeedAdapter, priceData)));
        bytes memory priceUpdateData =
            abi.encodePacked(priceSignature, abi.encode(vm.addr(signerPK)), abi.encode(priceData));
        IUpdatable(priceFeedAdapter).update(priceUpdateData);
    }

    // implementation functions
    // UnlimitedOwner
    function unlimitedOwnerImplementation() internal returns (address implementation) {
        implementation = address(new UnlimitedOwner());
    }

    // UserManager
    function userManagerImplementation() internal returns (address implementation) {
        IUnlimitedOwner unlimitedOwner = UnlimitedOwner(_getAddress("unlimitedOwner"));
        IController controller = Controller(_getAddress("controller"));
        ITradeManager tradeManager = ITradeManager(_getAddress("tradeManagerOrders"));
        implementation = address(new UserManager(unlimitedOwner, controller, tradeManager));
    }

    // FeeManager
    function feeManagerImplementation() internal returns (address implementation) {
        UnlimitedOwner unlimitedOwner = UnlimitedOwner(_getAddress("unlimitedOwner"));
        Controller controller = Controller(_getAddress("controller"));
        UserManager userManager = UserManager(_getAddress("userManager"));
        implementation = address(new FeeManager(unlimitedOwner, controller, userManager));
    }

    // LiquidityPool
    function liquidityPoolImplementation() internal returns (address implementation) {
        IUnlimitedOwner unlimitedOwner = UnlimitedOwner(_getAddress("unlimitedOwner"));
        IERC20Metadata collateral = IERC20Metadata(_getAddress("collateral"));
        IController controller = IController(_getAddress("controller"));
        implementation = address(new LiquidityPool(unlimitedOwner, collateral, controller));
    }

    // LiquidityPoolAdapter
    function liquidityPoolAdapterImplementation() internal returns (address implementation) {
        UnlimitedOwner unlimitedOwner = UnlimitedOwner(_getAddress("unlimitedOwner"));
        Controller controller = Controller(_getAddress("controller"));
        FeeManager feeManager = FeeManager(_getAddress("feeManager"));
        IERC20Metadata collateral = IERC20Metadata(_getAddress("collateral"));
        implementation = address(new LiquidityPoolAdapter(unlimitedOwner, controller, address(feeManager), collateral));
    }

    // PriceFeedAdapter
    function priceFeedAdapterImplementation() internal returns (address implementation) {
        Controller controller = Controller(_getAddress("controller"));
        UnlimitedOwner unlimitedOwner = UnlimitedOwner(_getAddress("unlimitedOwner"));

        implementation = address(
            new UnlimitedPriceFeedAdapter(
            COLLATERAL_DECIMALS,
            controller,
            unlimitedOwner
            )
        );
    }

    // TradePair
    function tradePairImplementation() internal returns (address implementation) {
        IUnlimitedOwner unlimitedOwner = IUnlimitedOwner(_getAddress("unlimitedOwner"));
        ITradeManager tradeManager = ITradeManager(_getAddress("tradeManagerOrders"));
        IUserManager userManager = IUserManager(_getAddress("userManager"));
        IFeeManager feeManager = IFeeManager(_getAddress("feeManager"));
        implementation = address(new TradePair(unlimitedOwner, tradeManager, userManager, feeManager));
    }
}
