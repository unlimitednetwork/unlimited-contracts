// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "test/mocks/MockV3Aggregator.sol";

import "../../src/user-manager/UserManager.sol";
import "../../src/price-feed/UnlimitedPriceFeedAdapter.sol";
import "../mocks/MockTradeManager.sol";
import "test/mocks/MockArbSys.sol";
import "script/helper/Helpers.s.sol";
import "script/Deploy.s.sol";
import "test/mocks/MockToken.sol";

contract DeploymentTest is Helper, Test {
    function setUp() public {
        // Set the network to local, so contract addresses are not overwritten for testnet/mainnet
        _network = "DeploymentTest";

        // Deploy an ERC20 token to the collateral address
        vm.etch(_getConstant("COLLATERAL"), address(new MockToken()).code);

        // Setup Arbitrum environment
        vm.etch(address(100), address(new MockArbSys()).code);

        _deployMockPriceFeeds();

        DeployScript deployScript = new DeployScript();
        deployScript.setNetwork(_network);
        deployScript.run();
    }

    function testScriptRuns() public {}

    function testUnlimitedOwner() public {
        IUnlimitedOwner unlimitedOwner = IUnlimitedOwner(_getAddress("unlimitedOwner"));
        address expectedUnlimitedOwner = vm.addr(vm.envUint("DEPLOYER"));
        assertTrue(unlimitedOwner.isUnlimitedOwner(expectedUnlimitedOwner));
    }

    function testController() public {
        IController controller = IController(_getAddress("controller"));
        assertTrue(controller.isOrderExecutor(_getConstant(_network, "ORDER_EXECUTOR")));
        assertTrue(controller.isSigner(_getConstant(_network, "SIGNER")));
    }

    function testUserManager() public {
        IUserManager userManager = IUserManager(_getAddress("userManager"));
        assertEq(userManager.getUserFee(address(this)), 10);
    }

    function testTradeManager() public {
        ITradeManagerOrders tradeManager = ITradeManagerOrders(_getAddress("tradeManagerOrders"));
        vm.expectRevert("TradePair::detailsOfPosition: Position does not exist");
        tradeManager.detailsOfPosition(_getAddress("tradePairBTC"), 0);
    }

    function testFeeManager() public {
        IFeeManager feeManager = IFeeManager(_getAddress("feeManager"));
        assertEq(feeManager.calculateUserOpenFeeAmount(address(0), 10010), 10);
    }

    function testTradePairHelper() public {
        ITradePairHelper tradePairHelper = ITradePairHelper(_getAddress("tradePairHelper"));
        ITradePair[] memory tradePairs = new ITradePair[](1);
        tradePairs[0] = ITradePair(_getAddress("tradePairBTC"));

        vm.expectRevert("UnlimitedPriceFeedUpdater::_verifyValidTo: Price is not valid");
        tradePairHelper.pricesOf(tradePairs);
    }

    function testLiquidityPool() public {
        ILiquidityPool liquidityPool = ILiquidityPool(_getAddress("liquidityPoolBluechip"));
        assertEq(liquidityPool.availableLiquidity(), 0);
        assertEq(liquidityPool.userWithdrawalFee(address(this)), EARLY_WITHDRAWAL_FEE);
    }

    function testLiquidityPoolAdapter() public {
        ILiquidityPoolAdapter liquidityPoolAdapter = ILiquidityPoolAdapter(_getAddress("liquidityPoolAdapterBluechip"));
        assertEq(liquidityPoolAdapter.availableLiquidity(), 0);
    }

    function testPriceFeedAdapter() public {
        IPriceFeedAdapter priceFeedAdapter = IPriceFeedAdapter(_getAddress("priceFeedAdapterBTC"));
        vm.expectRevert("UnlimitedPriceFeedUpdater::_verifyValidTo: Price is not valid");
        priceFeedAdapter.markPriceMin();
    }

    function _deployMockPriceFeeds() internal {
        AggregatorV3Interface ethPriceFeed = new MockV3Aggregator(8, 1_600*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_ETH"), address(ethPriceFeed).code);

        AggregatorV3Interface btcPriceFeed = new MockV3Aggregator(8, 23_600*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_BTC"), address(btcPriceFeed).code);

        AggregatorV3Interface linkPriceFeed = new MockV3Aggregator(8, 600*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_LINK"), address(linkPriceFeed).code);

        AggregatorV3Interface usdcPriceFeed = new MockV3Aggregator(8, 1*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_USDC"), address(usdcPriceFeed).code);
    }

    function testTradePair() public {
        ITradePair _tradePair = ITradePair(_getAddress("tradePairBTC"));
        assertEq(_tradePair.totalVolumeLimit(), TOTAL_VOLUME_LIMIT);
    }

    function test_tradePairsHaveSameImplementation() public {
        vm.startPrank(_getAddress("proxyAdmin"));

        assertEq(
            ITransparentUpgradeableProxy(payable(_getAddress("tradePairBTC"))).implementation(),
            ITransparentUpgradeableProxy(payable(_getAddress("tradePairETH"))).implementation(),
            "TradePair BTC and ETH have different implementations"
        );
    }

    function test_liquidityPoolsHaveSameImplementation() public {
        vm.startPrank(_getAddress("proxyAdmin"));

        assertEq(
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolBluechip"))).implementation(),
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAltcoin"))).implementation(),
            "LiquidityPool Bluechip and Altcoin have different implementations"
        );
    }

    function test_liquidityPoolAdaptersHaveSameImplementation() public {
        vm.startPrank(_getAddress("proxyAdmin"));

        assertEq(
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAdapterBluechip"))).implementation(),
            ITransparentUpgradeableProxy(payable(_getAddress("liquidityPoolAdapterAltcoin"))).implementation(),
            "LiquidityPoolAdapter Bluechip and Altcoin have different implementations"
        );
    }

    function test_priceFeedAdaptersHaveSameImplementation() public {
        vm.startPrank(_getAddress("proxyAdmin"));

        assertEq(
            ITransparentUpgradeableProxy(payable(_getAddress("priceFeedAdapterBTC"))).implementation(),
            ITransparentUpgradeableProxy(payable(_getAddress("priceFeedAdapterETH"))).implementation(),
            "PriceFeedAdapter BTC and ETH have different implementations"
        );
    }
}
