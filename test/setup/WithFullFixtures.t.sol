// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/PriceFeedAdapter.sol";
import "src/interfaces/IPriceFeedAdapter.sol";
import "src/interfaces/IController.sol";
import "src/trade-pair/TradePair.sol";
import "src/liquidity-pools/LiquidityPool.sol";
import "src/fee-manager/FeeManager.sol";
import "src/trade-manager/TradeManagerOrders.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";
import "src/sys-controller/Controller.sol";
import "src/sys-controller/UnlimitedOwner.sol";
import "src/user-manager/UserManager.sol";

import "test/mocks/MockArbSys.sol";
import "test/mocks/MockToken.sol";
import "test/mocks/MockPriceFeedAdapter.sol";
import "./Constants.sol";
import "./WithAlterationHelpers.t.sol";

/**
 * @notice Test fixtures help to simulate specific scenarios in test cases
 */
contract WithFullFixtures is Test, WithAlterationHelpers {
    using PositionMaths for Position;

    IController public controller;
    IUserManager public userManager;
    ITradeManagerOrders public tradeManager;
    IFeeManager public feeManager;
    UnlimitedOwner unlimitedOwner;

    address internal constant WHITELABEL_ADDRESS = address(9);
    address internal constant STAKERS_ADDRESS = address(10);
    address internal constant DEV_ADDRESS = address(11);
    address internal constant INSURANCE_ADDRESS = address(12);

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function _deployMainContracts() internal {
        controller = _deployController();
        address tradeManager_ = computeCreateAddress(address(this), vm.getNonce(address(this)) + 2);
        userManager = _deployUserManager(controller, ITradeManager(tradeManager_));

        tradeManager = _deployTradeManager(controller, userManager);
        feeManager = _deployFeeManager(controller, userManager);

        // Setup Arbitrum environment
        vm.etch(address(100), address(new MockArbSys()).code);
    }

    function _deployController() internal returns (IController) {
        unlimitedOwner =
            UnlimitedOwner(address(new TransparentUpgradeableProxy(address(new UnlimitedOwner()), address(1), "")));
        unlimitedOwner.initialize();

        Controller _controller = new Controller(unlimitedOwner);
        _controller.addOrderExecutor(BACKEND);

        return _controller;
    }

    function _deployUserManager(IController _controller, ITradeManager _tradeManager) internal returns (IUserManager) {
        // To simplify tests, we use the same fee sizes for the first two tiers
        uint8[7] memory feeSizes = [10, 10, 8, 7, 6, 5, 4];
        uint32[6] memory volumes = [1_000_000, 20_000_000, 100_000_000, 250_000_000, 500_000_000, 1_000_000_000];

        UserManager _userManagerImplementation = new UserManager(unlimitedOwner, _controller, _tradeManager);

        UserManager _userManager =
            UserManager(address(new TransparentUpgradeableProxy(address(_userManagerImplementation), address(1), "")));

        _userManager.initialize(feeSizes, volumes);

        return _userManager;
    }

    function _deployTradeManager(IController _controller, IUserManager _userManager)
        internal
        returns (ITradeManagerOrders)
    {
        TradeManagerOrders _tradeManager = new TradeManagerOrders(_controller, _userManager);
        return ITradeManagerOrders(_tradeManager);
    }

    function _deployFeeManager(IController _controller, IUserManager _userManager) internal returns (IFeeManager) {
        IFeeManager feeManagerImplementation = new FeeManager(unlimitedOwner, _controller, _userManager);
        FeeManager _feeManager = FeeManager(
            address(new TransparentUpgradeableProxy(address(feeManagerImplementation), address(unlimitedOwner), ""))
        );
        _feeManager.initialize(
            10_00, // 10% max payout
            STAKERS_ADDRESS,
            DEV_ADDRESS,
            INSURANCE_ADDRESS
        );
        return _feeManager;
    }

    function _deployPriceFeed(IController _controller) internal returns (MockPriceFeedAdapter) {
        MockPriceFeedAdapter priceFeedAdapter =
            new MockPriceFeedAdapter("Mock Price Feed Adapter", ASSET_DECIMALS, COLLATERAL_DECIMALS);
        int256 price = int256(2_000 * (PRICE_MULTIPLIER));
        priceFeedAdapter.setMarkPrices(price, price);

        _controller.addPriceFeed(address(priceFeedAdapter));

        return priceFeedAdapter;
    }

    function _deployLiquidityPool(IController _controller, IERC20Metadata collateral, string memory name)
        internal
        returns (ILiquidityPool)
    {
        LiquidityPool liquidityPoolImplementation = new LiquidityPool(unlimitedOwner, collateral, _controller);

        LiquidityPool liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(unlimitedOwner), ""))
        );

        liquidityPool.initialize(name, name, 0, 0, 0, 0);

        _controller.addLiquidityPool(address(liquidityPool));

        return liquidityPool;
    }

    function _deployLiquidityPoolAdapter(
        IController _controller,
        IFeeManager _feeManager,
        IERC20Metadata collateral,
        LiquidityPoolConfig[] memory liquidityConfig
    ) internal returns (ILiquidityPoolAdapter) {
        LiquidityPoolAdapter liquidityPoolAdapterImplementation =
            new LiquidityPoolAdapter(unlimitedOwner, _controller, address(_feeManager), collateral);

        LiquidityPoolAdapter liquidityPoolAdapter = LiquidityPoolAdapter(
            address(
                new TransparentUpgradeableProxy(address(liquidityPoolAdapterImplementation), address(unlimitedOwner), "")
            )
        );

        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        _controller.addLiquidityPoolAdapter(address(liquidityPoolAdapter));

        return liquidityPoolAdapter;
    }

    function _deployTradePair(
        IController _controller,
        IUserManager _userManager,
        IFeeManager _feeManager,
        ITradeManager _tradeManager,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) internal returns (ITradePair) {
        TradePair tradePairImplementation = new TradePair(unlimitedOwner,
            _tradeManager,
            _userManager,
            _feeManager
        );
        TradePair tradePair = TradePair(
            address(new TransparentUpgradeableProxy(address(tradePairImplementation), address(unlimitedOwner), ""))
        );

        tradePair.initialize("Shit Coin Trade Pair", collateral, priceFeedAdapter, liquidityPoolAdapter);

        _controller.addTradePair(address(tradePair));

        // Configure
        tradePair.setLiquidatorReward(LIQUIDATOR_REWARD);
        tradePair.setMinLeverage(MIN_LEVERAGE);
        tradePair.setMaxLeverage(MAX_LEVERAGE);
        tradePair.setMinMargin(MIN_MARGIN);
        tradePair.setVolumeLimit(VOLUME_LIMIT);
        tradePair.setBorrowFeeRate(BASIS_BORROW_FEE_0);
        tradePair.setMaxFundingFeeRate(FUNDING_FEE_0);
        tradePair.setMaxExcessRatio(MAX_EXCESS_RATIO);
        tradePair.setFeeBufferFactor(BUFFER_FACTOR);
        tradePair.setTotalVolumeLimit(TOTAL_VOLUME_LIMIT);

        return tradePair;
    }
}
