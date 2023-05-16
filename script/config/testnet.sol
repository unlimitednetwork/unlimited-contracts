// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../src/shared/Constants.sol";

// Allready deployed contracts
address constant COLLATERAL = 0x52c7469869056e788598Bb0Dd4268e9e01EE6D63;

// Price Feeds
uint256 constant MAX_DEVIATION = 100;
address constant CHAINLINK_BTC = address(0);
address constant CHAINLINK_ETH = address(0);
address constant CHAINLINK_LINK = address(0);
address constant CHAINLINK_USDC = address(0);

// Decimals
uint16 constant COLLATERAL_DECIMALS = 6;
uint256 constant COLLATERAL_MULTIPLIER = 10 ** uint256(COLLATERAL_DECIMALS);

// TradeManager
uint256 constant ORDER_REWARD = 0;
address constant ORDER_EXECUTOR = address(13);

// TradePairs
uint128 constant MIN_LEVERAGE = 11 * uint128(LEVERAGE_MULTIPLIER) / 10;
uint128 constant MAX_LEVERAGE = 100 * uint128(LEVERAGE_MULTIPLIER);
uint256 constant MIN_MARGIN = 10 * COLLATERAL_MULTIPLIER;
uint256 constant LIQUIDATOR_REWARD = 5 * COLLATERAL_MULTIPLIER / 10;
uint256 constant VOLUME_LIMIT = 999_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant TOTAL_VOLUME_LIMIT = 10_000_000_000 * COLLATERAL_MULTIPLIER;
int256 constant BORROW_FEE = 5_000_000_000; // 0.005%
int256 constant MAX_FUNDING_FEE = 10_000_000_000; // 0.01%
int256 constant MAX_EXCESS_RATIO = 5 * FEE_MULTIPLIER;
uint256 constant TOTAL_ASSET_AMOUNT_LIMIT = 1_000_000_000 * ASSET_MULTIPLIER;

// UserManager
// set in the deployment script as array constants are not possible in solidity

// FeeManager
uint256 constant REFERRAL_FEE = 10_00;
address constant STAKERS_FEE_ADDRESS = 0x6c8C393F16B6898BeFd9d2a19002a45933A9BfbE;
address constant DEV_FEE_ADDRESS = 0x019bAd5362CeD7456bf857D225EF78aCD176bd31;
address constant INSURANCE_FUND_FEE_ADDRESS = 0x3a4DA92fF4779394051Ca07C9F0463bc1a0953e1;

// LiquidityPool
uint256 constant DEFAULT_LOCK_TIME = 6 hours;
uint256 constant EARLY_WITHDRAWAL_FEE = 30; // 0.3%
uint256 constant EARLY_WITHDRAWAL_TIME = 3 days;
uint256 constant MINIMUM_AMOUNT = 0;

uint40 constant LOCKTIME_POOL_0 = 30 days;
uint16 constant MULTIPLIER_POOL_0 = 25_00;
uint40 constant LOCKTIME_POOL_1 = 60 days;
uint16 constant MULTIPLIER_POOL_1 = 50_00;
uint40 constant LOCKTIME_POOL_2 = 90 days;
uint16 constant MULTIPLIER_POOL_2 = 100_00;
