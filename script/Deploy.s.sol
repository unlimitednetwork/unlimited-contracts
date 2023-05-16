// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/helper/Helpers.s.sol";
import "./config/testnet.sol";

contract DeployScript is Helper {
    string path;

    address deployer;

    ProxyAdmin proxyAdmin;
    UnlimitedOwner unlimitedOwner;
    IController controller;
    UserManager userManager;
    ITradeManagerOrders tradeManagerOrders;
    FeeManager feeManager;
    ITradePairHelper tradePairHelper;
    IERC20Metadata collateral;

    ILiquidityPool blueChipLiquidityPool;
    ILiquidityPool altCoinLiquidityPool;
    ILiquidityPool degenLiquidityPool;
    ILiquidityPoolAdapter blueChipLiquidityPoolAdapter;
    ILiquidityPoolAdapter altCoinLiquidityPoolAdapter;

    ITradePair ethTradePair;
    ITradePair btcTradePair;
    ITradePair linkTradePair;

    PriceFeedAggregator collateralPriceFeedAggregator;

    IPriceFeedAdapter ethPriceFeedAdapter;
    IPriceFeedAdapter btcPriceFeedAdapter;
    IPriceFeedAdapter linkPriceFeedAdapter;

    // Read Constants
    AggregatorV3Interface btcPriceFeed = AggregatorV3Interface(_getConstant("CHAINLINK_BTC"));
    AggregatorV3Interface ethPriceFeed = AggregatorV3Interface(_getConstant("CHAINLINK_ETH"));
    AggregatorV3Interface linkPriceFeed = AggregatorV3Interface(_getConstant("CHAINLINK_LINK"));
    AggregatorV3Interface usdcPriceFeed = AggregatorV3Interface(_getConstant("CHAINLINK_USDC"));

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        deployer = vm.addr(deployerPrivateKey);
        path = string.concat("deploy/contracts.", _network, ".json");

        vm.startBroadcast(deployerPrivateKey);

        _startJson(path, _network, block.number - 1);

        _deployProxyAdmin();
        _deployUnlimitedOwner();

        // deploy system
        _deployController();
        _deployUserManager();

        _deployTradeManager();
        _deployFeeManager();

        _deployTradePairHelper();

        _setCollateral();

        // Deploy liquidity pools
        LiquidityPool liquidityPool_implementation = new LiquidityPool(unlimitedOwner, collateral, controller);
        blueChipLiquidityPool = _deployLiquidityPool("Bluechip", "blpUSDC", liquidityPool_implementation);
        altCoinLiquidityPool = _deployLiquidityPool("Altcoin", "alpUSDC", liquidityPool_implementation);
        degenLiquidityPool = _deployLiquidityPool("Degen", "dlpUSDC", liquidityPool_implementation);

        // Deploy liquidity pool adapters
        LiquidityPoolAdapter liquidityPoolAdapter_implementation =
            new LiquidityPoolAdapter(unlimitedOwner, controller, address(feeManager), collateral);

        // Deploy bluechip liquidity pool adapter
        LiquidityPoolConfig[] memory blueChipLiquidityConfig = new LiquidityPoolConfig[](3);
        blueChipLiquidityConfig[0] = LiquidityPoolConfig(address(blueChipLiquidityPool), uint96(FULL_PERCENT));
        blueChipLiquidityConfig[1] = LiquidityPoolConfig(address(altCoinLiquidityPool), uint96(FULL_PERCENT));
        blueChipLiquidityConfig[2] = LiquidityPoolConfig(address(degenLiquidityPool), uint96(FULL_PERCENT));

        blueChipLiquidityPoolAdapter =
            _deployLiquidityPoolAdapter(blueChipLiquidityConfig, liquidityPoolAdapter_implementation, "Bluechip");

        // Deploy alt coin liquidity pool adapter
        LiquidityPoolConfig[] memory altCoinLiquidityConfig = new LiquidityPoolConfig[](2);
        altCoinLiquidityConfig[0] = LiquidityPoolConfig(address(altCoinLiquidityPool), uint96(FULL_PERCENT));
        altCoinLiquidityConfig[1] = LiquidityPoolConfig(address(degenLiquidityPool), uint96(FULL_PERCENT));

        altCoinLiquidityPoolAdapter =
            _deployLiquidityPoolAdapter(altCoinLiquidityConfig, liquidityPoolAdapter_implementation, "Altcoin");

        // Deploy asset price feed adapters
        UnlimitedPriceFeedAdapter priceFeedAdapter_implementation = new UnlimitedPriceFeedAdapter(
            COLLATERAL_DECIMALS,
            controller,
            unlimitedOwner
        );

        ethPriceFeedAdapter =
            _deployUnlimitedPriceFeedAdapter("ETH", priceFeedAdapter_implementation, usdcPriceFeed, ethPriceFeed);
        btcPriceFeedAdapter =
            _deployUnlimitedPriceFeedAdapter("BTC", priceFeedAdapter_implementation, usdcPriceFeed, btcPriceFeed);
        linkPriceFeedAdapter =
            _deployUnlimitedPriceFeedAdapter("LINK", priceFeedAdapter_implementation, usdcPriceFeed, linkPriceFeed);

        // Deploy trade pairs
        TradePair tradePair_implementation =
            new TradePair(unlimitedOwner, ITradeManager(tradeManagerOrders), userManager, feeManager);

        ethTradePair =
            _deployTradePair(ethPriceFeedAdapter, tradePair_implementation, blueChipLiquidityPoolAdapter, "ETH");
        btcTradePair =
            _deployTradePair(btcPriceFeedAdapter, tradePair_implementation, blueChipLiquidityPoolAdapter, "BTC");
        linkTradePair =
            _deployTradePair(linkPriceFeedAdapter, tradePair_implementation, altCoinLiquidityPoolAdapter, "LINK");

        _addLockPoolsToLiquidityPool(blueChipLiquidityPool);
        _addLockPoolsToLiquidityPool(altCoinLiquidityPool);
        _addLockPoolsToLiquidityPool(degenLiquidityPool);

        _configure();

        vm.stopBroadcast();
    }

    function _configure() private {
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_0"));
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_1"));
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_2"));
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_3"));
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_4"));
        controller.addOrderExecutor(_getConstant("ORDER_EXECUTOR_5"));
        controller.addSigner(_getConstant("SIGNER_0"));
    }

    function _deployProxyAdmin() private {
        // init
        proxyAdmin = new ProxyAdmin();

        // write
        _writeJson(path, "proxyAdmin", address(proxyAdmin));
    }

    function _deployUnlimitedOwner() private {
        // init
        address implementation = address(new UnlimitedOwner());
        address proxy = _deployProxy(implementation, proxyAdmin);
        unlimitedOwner = UnlimitedOwner(proxy);
        unlimitedOwner.initialize();

        // write
        _writeJson(path, "unlimitedOwner", proxy, implementation);
    }

    function _deployController() private {
        // init
        controller = new Controller(unlimitedOwner);

        // setup
        controller.addOrderExecutor(deployer);
        controller.addOrderExecutor(_getConstant(_network, "ORDER_EXECUTOR"));
        controller.addSigner(deployer);
        controller.addSigner(_getConstant(_network, "SIGNER"));

        // write
        _writeJson(path, "controller", address(controller));
    }

    function _deployUserManager() private {
        // init
        address tradeManagerOrders_ = computeCreateAddress(deployer, vm.getNonce(deployer) + 3);
        address implementation =
            address(new UserManager(unlimitedOwner, controller, ITradeManager(tradeManagerOrders_)));
        address proxy = _deployProxy(implementation, proxyAdmin);
        userManager = UserManager(proxy);
        //
        uint8[7] memory feeSizes = [10, 9, 8, 7, 6, 5, 4];
        uint32[6] memory volumes = [1_000_000, 10_000_000, 100_000_000, 250_000_000, 500_000_000, 1_000_000_000];
        userManager.initialize(feeSizes, volumes);

        // write
        _writeJson(path, "userManager", proxy, implementation);
    }

    function _deployTradeManager() private {
        // init
        tradeManagerOrders = new TradeManagerOrders(controller, userManager);

        // write
        _writeJson(path, "tradeManagerOrders", address(tradeManagerOrders));
    }

    function _deployFeeManager() private {
        // init
        address implementation = address(new FeeManager(unlimitedOwner, controller, userManager));
        address proxy = _deployProxy(implementation, proxyAdmin);
        feeManager = FeeManager(proxy);
        feeManager.initialize(REFERRAL_FEE, STAKERS_FEE_ADDRESS, DEV_FEE_ADDRESS, INSURANCE_FUND_FEE_ADDRESS);

        // write
        _writeJson(path, "feeManager", proxy, implementation);
    }

    function _deployTradePairHelper() private {
        // init
        tradePairHelper = new TradePairHelper();

        // write
        _writeJson(path, "tradePairHelper", address(tradePairHelper));
    }

    function _setCollateral() private {
        collateral = IERC20Metadata(_getConstant("COLLATERAL"));

        // write to json to know which collateral is used for the deployment
        _writeJson(path, "collateral", address(collateral));
    }

    function _deployUnlimitedPriceFeedAdapter(
        string memory assetName_,
        UnlimitedPriceFeedAdapter implementation,
        AggregatorV3Interface collateralPriceFeed_,
        AggregatorV3Interface assetPriceFeed_
    ) private returns (IPriceFeedAdapter) {
        string memory adapterName = string.concat(assetName_, "/USDC Price Feed Adapter");

        UnlimitedPriceFeedAdapter priceFeedAdapter =
            UnlimitedPriceFeedAdapter(_deployProxy(address(implementation), proxyAdmin));

        priceFeedAdapter.initialize(adapterName, MAX_DEVIATION, collateralPriceFeed_, assetPriceFeed_);

        // Add price feed adapter to controller
        controller.addPriceFeed(address(priceFeedAdapter));
        controller.addUpdatable(address(priceFeedAdapter));

        _writeJson(
            path, string.concat("priceFeedAdapter", assetName_), address(priceFeedAdapter), address(implementation)
        );

        return IPriceFeedAdapter(address(priceFeedAdapter));
    }

    function _deployLiquidityPool(string memory id, string memory symbol, LiquidityPool implementation)
        private
        returns (ILiquidityPool)
    {
        // init
        string memory name = string.concat(id, " Pool USDC");
        address proxy = _deployProxy(address(implementation), proxyAdmin);
        LiquidityPool liquidityPool = LiquidityPool(proxy);
        liquidityPool.initialize(
            name, symbol, DEFAULT_LOCK_TIME, EARLY_WITHDRAWAL_FEE, EARLY_WITHDRAWAL_TIME, MINIMUM_AMOUNT
        );

        // setup
        controller.addLiquidityPool(address(liquidityPool));

        // write
        _writeJson(path, string.concat("liquidityPool", name), proxy, address(implementation));

        return liquidityPool;
    }

    function _addLockPoolsToLiquidityPool(ILiquidityPool liquidityPool) private {
        liquidityPool.addPool(LOCKTIME_POOL_0, MULTIPLIER_POOL_0);
        liquidityPool.addPool(LOCKTIME_POOL_1, MULTIPLIER_POOL_1);
        liquidityPool.addPool(LOCKTIME_POOL_2, MULTIPLIER_POOL_2);
    }

    function _deployLiquidityPoolAdapter(
        LiquidityPoolConfig[] memory liquidityConfig,
        LiquidityPoolAdapter implementation,
        string memory id
    ) private returns (ILiquidityPoolAdapter) {
        // init
        address proxy = _deployProxy(address(implementation), proxyAdmin);
        LiquidityPoolAdapter liquidityPoolAdapter = LiquidityPoolAdapter(proxy);
        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        // setup
        controller.addLiquidityPoolAdapter(address(liquidityPoolAdapter));

        // write
        _writeJson(path, string.concat("liquidityPoolAdapter", id), proxy, address(implementation));

        return liquidityPoolAdapter;
    }

    function _deployTradePair(
        IPriceFeedAdapter priceFeedAdapter,
        TradePair implementation,
        ILiquidityPoolAdapter liquidityPoolAdapter,
        string memory id
    ) private returns (ITradePair) {
        address proxy = _deployProxy(address(implementation), proxyAdmin);
        TradePair tradePair = TradePair(proxy);
        // NOTE: asset decimals should be same as the asset aggregator OR vice versa
        tradePair.initialize("Test Trade Pair", collateral, priceFeedAdapter, liquidityPoolAdapter);

        controller.addTradePair(address(tradePair));

        tradePair.setLiquidatorReward(LIQUIDATOR_REWARD);
        tradePair.setMinLeverage(MIN_LEVERAGE);
        tradePair.setMaxLeverage(MAX_LEVERAGE);
        tradePair.setMinMargin(MIN_MARGIN);
        tradePair.setVolumeLimit(VOLUME_LIMIT);
        tradePair.setBorrowFeeRate(BORROW_FEE);
        tradePair.setMaxFundingFeeRate(MAX_FUNDING_FEE);
        tradePair.setMaxExcessRatio(MAX_EXCESS_RATIO);
        tradePair.setTotalVolumeLimit(TOTAL_VOLUME_LIMIT);

        // write
        _writeJson(path, string.concat("tradePair", id), proxy, address(implementation));

        return tradePair;
    }
}
