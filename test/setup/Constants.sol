// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./../../src/shared/Constants.sol";

/*
 * Accounts
 * These are the first addresses of the forge/anvil default addresses.
 */

address constant DEPLOYER = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
address constant ALICE = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
address constant BOB = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
address constant CAROL = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
address constant DAN = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
address constant FAYTHE = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
address constant MALLORY = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
address constant CLIENT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
address constant UNLIMITED_OWNER = address(9999);

address constant ETH_USD_CHAINLINK_AGGREGATOR = address(1);
address constant ADDRESS_ONE = address(1);

/*
 * Basic constants
 */
// Multiplier
uint8 constant ASSET_DECIMALS = 18;
uint256 constant COLLATERAL_DECIMALS = 6;
uint8 constant USD_DECIMALS = 8;
uint256 constant ASSET_MULTIPLIER = 10 ** ASSET_DECIMALS;
uint256 constant COLLATERAL_MULTIPLIER = 10 ** COLLATERAL_DECIMALS;
uint256 constant LP_FACTOR_MULTIPLIER = 1_000_000;
uint256 constant USD_MULTIPLIER = 10 ** USD_DECIMALS;
uint256 constant BPS_MULTIPLIER = 100_00;

// Configurations
uint128 constant MIN_LEVERAGE = 11 * uint128(LEVERAGE_MULTIPLIER) / 10;
uint128 constant MAX_LEVERAGE = 100 * uint128(LEVERAGE_MULTIPLIER);
uint256 constant MIN_MARGIN = 100 * COLLATERAL_MULTIPLIER;
int256 constant BASIS_BORROW_FEE_0 = 100_000_000_000; // 0.1%
int256 constant BASIS_BORROW_FEE_1 = 200_000_000_000; // 0.2%
int256 constant BASIS_BORROW_FEE_2 = 300_000_000_000; // 0.3%
int256 constant FUNDING_FEE_0 = 300_000_000_000; // 0.3%
int256 constant BUFFER_FACTOR = 250_000; // 25%
uint8 constant BASE_USER_FEE = 10;
int256 constant MAX_EXCESS_RATIO = 2 * FEE_MULTIPLIER;
int256 constant MAX_EXCESS_RATIO_1 = 4 * FEE_MULTIPLIER;
uint256 constant REMAINING_VOLUME_0 = MARGIN_0 * 1_000;
uint256 constant LP_FACTOR_1 = 70_000_000;
uint256 constant LP_FACTOR_2 = 30_000_000;
uint256 constant LP_SHARE_1 = (LP_FACTOR_1 * LP_FACTOR_MULTIPLIER) / (LP_FACTOR_1 + LP_FACTOR_2);
uint256 constant LP_SHARE_2 = (LP_FACTOR_2 * LP_FACTOR_MULTIPLIER) / (LP_FACTOR_1 + LP_FACTOR_2);
uint256 constant LIQUIDATOR_REWARD = 5 * COLLATERAL_MULTIPLIER;
uint256 constant VOLUME_LIMIT = 10_00_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant TOTAL_ASSET_AMOUNT_LIMIT = 1_000_000_000 * ASSET_MULTIPLIER;
address constant WHITELABEL_ADDRESS_0 = address(0);
address constant REFERRER_0 = address(0);

uint256 constant MILLION = 1_000_000;
/* ========== scenario 0 ========== */
int256 constant ASSET_PRICE_0 = int256(2_000 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_0_USD = int256(2_000 * USD_MULTIPLIER);
uint256 constant COLLATERAL_AMOUNT_0 = 2_000 * COLLATERAL_MULTIPLIER;
uint256 constant USD_AMOUNT_0 = 2_000 * USD_MULTIPLIER;
int256 constant COLLATERAL_PRICE_0 = int256(1 * USD_MULTIPLIER);

/* ========== scenario 1 ========== */
int256 constant ASSET_PRICE_1 = int256(3_000 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_1_SHORT = int256(1_000 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_1_USD = int256(3_000 * USD_MULTIPLIER);
int256 constant MARK_PRICE_1 = int256(3_000 * COLLATERAL_MULTIPLIER);
uint256 constant ASSET_AMOUNT_1 = 2 * ASSET_MULTIPLIER;
uint256 constant USD_AMOUNT_1 = 6_000 * USD_MULTIPLIER;
uint256 constant COLLATERAL_AMOUNT_1 = 6_000 * COLLATERAL_MULTIPLIER;

/* ========== scenario 2 ========== */
int256 constant COLLATERAL_PRICE_2 = int256((80 * USD_MULTIPLIER) / 100);
uint256 constant ASSET_AMOUNT_2 = ASSET_AMOUNT_0;
uint256 constant USD_AMOUNT_2 = 2_000 * USD_MULTIPLIER;
uint256 constant COLLATERAL_AMOUNT_2 = 2_500 * COLLATERAL_MULTIPLIER;

/* ========== position 0 ========== */
uint256 constant MARGIN_0 = 1_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant LEVERAGE_0 = 5 * LEVERAGE_MULTIPLIER;
// Initial balance is set so, that after deducting the open position fee, position has a margin of MARGIN_0
uint256 constant OPEN_POSITION_FEE_0 = VOLUME_0 * BASE_USER_FEE / BPS_MULTIPLIER;
uint256 constant INITIAL_BALANCE = MARGIN_0 + OPEN_POSITION_FEE_0;
uint256 constant LEVERAGE_50 = 50 * LEVERAGE_MULTIPLIER;
uint256 constant VOLUME_0 = (MARGIN_0 * LEVERAGE_0) / LEVERAGE_MULTIPLIER; // 5_000_000
uint256 constant LOAN_0 = VOLUME_0 - MARGIN_0; // 4_000_000
uint256 constant CLOSE_POSITION_FEE_0 = MARGIN_0 * BASE_USER_FEE / BPS_MULTIPLIER;
bool constant IS_SHORT_0 = false;
uint256 constant ASSET_AMOUNT_0 = 2_500 * ASSET_MULTIPLIER;
int256 constant PRICE_BANKRUPTCY_0 = (ASSET_PRICE_0 * 4) / 5;
// I - I * L * F = M
// I = M / (1 - L * F)

uint256 constant BALANCE_AFTER_CLOSE_0 = MARGIN_0 - MARGIN_0 * BASE_USER_FEE / BPS_MULTIPLIER;

/* ========== fees for position 0 ========== */
// borrow fee: 0.1%, funding fee: 0.3%, elapsed time: 30 hours
// makes total fee integral of 12%
// So 60% of MARGIN_0 is used up in fees. (12% get applied to VOLUME_0)
// 3% (= 0.1% * 30)
int256 constant BORROW_FEE_INTEGRAL_0 = 30 * BASIS_BORROW_FEE_0;
// 150_000 (= 5_000_000 * 3%)
int256 constant BORROW_FEE_AMOUNT_0 = int256(VOLUME_0) * BORROW_FEE_INTEGRAL_0 / FEE_MULTIPLIER;
// 9% ( 0.3% * 30)
int256 constant FUNDING_FEE_INTEGRAL_0 = 30 * FUNDING_FEE_0;
// 450_000 (= 5_000_000 * 9%)
int256 constant FUNDING_FEE_AMOUNT_0 = int256(VOLUME_0) * FUNDING_FEE_INTEGRAL_0 / FEE_MULTIPLIER;
// 400_000 (= 1_000_000 - 150_000 - 450_000)
uint256 constant NET_MARGIN_0 = MARGIN_0 - uint256(BORROW_FEE_AMOUNT_0) - uint256(FUNDING_FEE_AMOUNT_0);
// 12.5
uint256 constant NET_LEVERAGE_0 = VOLUME_0 * LEVERAGE_MULTIPLIER / NET_MARGIN_0;

/* ========== partially close ========== */
uint256 constant CLOSE_PROPORTION_1 = 500_000; // 50%
uint256 constant LEAVE_LEVERAGE_0 = 0;
uint256 constant LEAVE_LEVERAGE_1 = 1_000_000; // 100%
uint256 constant LEAVE_LEVERAGE_2 = 500_000; // 50%
uint256 constant TARGET_LEVERAGE_0 = 2 * LEVERAGE_MULTIPLIER;
uint256 constant ASSET_AMOUNT_AFTER_CLOSE_TO_LEVERAGE_0 = (ASSET_AMOUNT_0 * 2) / 5;

/* ===== position 0 = price 1 (3_000) ===== */
uint256 constant VOLUME_0_1 = (ASSET_AMOUNT_0 * uint256(ASSET_PRICE_1)) / ASSET_MULTIPLIER;
int256 constant PNL_0_1 = int256(VOLUME_0_1 - VOLUME_0);
int256 constant EQUITY_0_1 = PNL_0_1 + int256(MARGIN_0);
// fee integral after 1 hours
int256 constant FEE_INTEGRAL_0 = BASIS_BORROW_FEE_0;
// fee integral after 2 hours
int256 constant FEE_INTEGRAL_0_1 = FEE_INTEGRAL_0 + BASIS_BORROW_FEE_0;
int256 constant FEE_INTEGRAL_1 = BASIS_BORROW_FEE_0 * 201; // 20.1% (makes a 20% fee to FEE_INTEGRAL_0)
int256 constant NET_PNL_0_1 = PNL_0_1 - BORROW_FEE_AMOUNT_0 - FUNDING_FEE_AMOUNT_0;
int256 constant NET_EQUITY_0_1 = NET_PNL_0_1 + int256(MARGIN_0);
uint256 constant CLOSE_POSITION_FEE_0_1 = uint256(EQUITY_0_1) * BASE_USER_FEE / BPS_MULTIPLIER;

/* ===== position 0 = price 2 (1_800) ===== */
int256 constant ASSET_PRICE_0_2 = int256(1_800 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_0_2_USD = int256(1_800 * USD_MULTIPLIER);
uint256 constant VOLUME_0_2 = (ASSET_AMOUNT_0 * uint256(ASSET_PRICE_0_2)) / ASSET_MULTIPLIER;
int256 constant PNL_0_2 = int256(VOLUME_0_2) - int256(VOLUME_0); // -500_000__000_000
int256 constant EQUITY_0_2 = PNL_0_2 + int256(MARGIN_0); //          500_000__000_000
uint256 constant CLOSE_POSITION_FEE_0_2 = uint256(EQUITY_0_2) * BASE_USER_FEE / BPS_MULTIPLIER;

/* ===== position 0 = price 2 (1_800) and normal fee ===== */
uint256 constant ELAPSED_TIME_0_2_2 = 10 hours;
uint256 constant TOTAL_FEE_AMOUNT_0_2_2 = uint256(
    (int256(ELAPSED_TIME_0_2_2) * (BASIS_BORROW_FEE_0 + FUNDING_FEE_0) * int256(VOLUME_0)) / 1 hours / FEE_MULTIPLIER
); // 80_000_000_000
uint256 constant NET_MARGIN_0_2_2 = MARGIN_0 - TOTAL_FEE_AMOUNT_0_2_2;
uint256 constant NET_LEVERAGE_0_2_2 = VOLUME_0 * LEVERAGE_MULTIPLIER / NET_MARGIN_0_2_2;
int256 constant EQUITY_0_2_2 = EQUITY_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_2); // 420_000__000_000
int256 constant PNL_0_2_2 = PNL_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_2); // -580_000__000_000

/* ===== position 0 = price 2 (1_800) and "over" fee covered by margin ===== */
uint256 constant ELAPSED_TIME_0_2_3 = 100 hours;
uint256 constant TOTAL_FEE_AMOUNT_0_2_3 = uint256(
    (int256(ELAPSED_TIME_0_2_3) * (BASIS_BORROW_FEE_0 + FUNDING_FEE_0) * int256(VOLUME_0)) / 1 hours / FEE_MULTIPLIER
); // 800_000__000_000
int256 constant EQUITY_0_2_3 = EQUITY_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_3);
int256 constant PNL_0_2_3 = PNL_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_3);

/* ===== position 0 = price 2 (1_800) and fee NOT covered by margin ===== */
uint256 constant ELAPSED_TIME_0_2_4 = 200 hours;
uint256 constant TOTAL_FEE_AMOUNT_0_2_4 = uint256(
    (int256(ELAPSED_TIME_0_2_4) * (BASIS_BORROW_FEE_0 + FUNDING_FEE_0) * int256(VOLUME_0)) / 1 hours / FEE_MULTIPLIER
); // 1_600_000__000_000
int256 constant EQUITY_0_2_4 = EQUITY_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_4);
int256 constant PNL_0_2_4 = PNL_0_2 - int256(TOTAL_FEE_AMOUNT_0_2_4);

/* ===== position 0 = price 1 (3_000) and fee NOT covered by margin ===== */
// Edge case: Equity positive, but fee not covered by margin
uint256 constant ELAPSED_TIME_0_1_4 = 200 hours;
uint256 constant TOTAL_FEE_AMOUNT_0_1_4 = uint256(
    (int256(ELAPSED_TIME_0_1_4) * (BASIS_BORROW_FEE_0 + FUNDING_FEE_0) * int256(VOLUME_0)) / 1 hours / FEE_MULTIPLIER
); // 1_600_000__000_000
int256 constant EQUITY_0_1_4 = EQUITY_0_1 - int256(TOTAL_FEE_AMOUNT_0_1_4); // 1_600_000__000_000
int256 constant PNL_0_1_4 = PNL_0_1 - int256(TOTAL_FEE_AMOUNT_0_1_4); // 900_000__000_000

/* ===== position 0 = price 3 (1_600) ===== */
int256 constant ASSET_PRICE_0_3 = int256(1_600 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_0_3_USD = int256(1_600 * USD_MULTIPLIER);
uint256 constant VOLUME_0_3 = (ASSET_AMOUNT_0 * uint256(ASSET_PRICE_0_3)) / ASSET_MULTIPLIER;
int256 constant PNL_0_3 = int256(VOLUME_0_3) - int256(VOLUME_0); // -1_000_000__000_000
int256 constant EQUITY_0_3 = PNL_0_3 + int256(MARGIN_0); //          0
uint256 constant CLOSE_POSITION_FEE_0_3 = uint256(EQUITY_0_3) * BASE_USER_FEE / BPS_MULTIPLIER;

/* ========== position 1 ========== */
// Exactly the same as position 0, but is short
bool constant IS_SHORT_1 = true;
int256 constant PRICE_BANKRUPTCY_1 = (ASSET_PRICE_0 * 6) / 5;
int256 constant ASSET_PRICE_1_1 = int256(1_000 * COLLATERAL_MULTIPLIER);
int256 constant ASSET_PRICE_1_1_USD = int256(1_000 * USD_MULTIPLIER);
uint256 constant VOLUME_1_1 = (ASSET_AMOUNT_0 * uint256(ASSET_PRICE_1_1)) / ASSET_MULTIPLIER;

/* ========== LP scenario 1 ========== */
uint256 constant LIQUIDITY_0 = 100_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant LIQUIDITY_SHARE_1 = 70_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant LIQUIDITY_SHARE_2 = 30_000_000 * COLLATERAL_MULTIPLIER;
uint256 constant PROFIT_0 = 10_000 * COLLATERAL_MULTIPLIER;
