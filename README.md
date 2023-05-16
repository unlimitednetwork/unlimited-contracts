# Unlimited Leverage

Unlimited Leverage contracts implementation.

## About

Unlimited Leverage is a margin trading plattform that allows traders to open synthetic positions on coins and tokens with a leverage of up to 100x.

## Contracts

Contracts can be found in the `src` folder.
Main Unlimited Leverage contracts consist of:

- `TradePair.sol`
  - Manages the Trades by providing the chore functionalities of opening, closing and extending positions
  - Each TradePair allows trades on one assets, with one collateral (usually USDC)
  - TradePair can only be accessed by TradeManager
  - Interacts with LiquidityPoolAdapter to deposit profits and fees and request loss payouts
- `TradeManager.sol`
  - Takes Orders from users and sends them to the TradePairs
  - Takes signed orders from the order book backend and sends them to the TradePairs
  - Takes automated orders, maps signatures to position ids and allows for limit stop orders and other automated orders
- `PriceFeedAdapter.sol`
  - Provides price information to TradePairs
  - Uses PriceFeedAggregator to get price information from multiple price feeds
  - Provides conversion functions to converse Asset, USD and Collateral in all possible directions
- `LiquidityPoolAdapter.sol`
  - Provides functions to TradePair to request losses and deposit profits
  - Distributes profits and losses to LiquidityPools
- `LiquidityPool.sol`
  - Allows liquidity providers to deposit assets and lock deposits to increase earnings
  - Provides liquidity to TradePairs via the LiquidityPoolAdapter
- `FeeManager.sol`
  - Calculates, receives and distributes all fees.
  - Fees include: OpenPositionFee, ClosePositionFee
  - Fees also include BorrowFee, which is the hourly fee for holding a position.
  - Fee Receivers include: LiquidityPools, Referrer, Dev, Whitelabel
- `UserManager.sol`
  - Keeps track of fees and daily volumes for each individual user
  - Users can reach new (cheaper) fee tiers with certain 30-day volumes
- `Controller.sol`
  - Implements a registry to register the different parts of the Unlimited system
  - Provides restriction functions to other smart contracts, i.e. *isTradePair()*
- `UnlimitedOwner.sol`
  - Simple contract holding the address of Unlimited Leverage
  - All the contracts controlled by the Unlimited DAO inherit `contracts/shared/UnlimitedOwnable.sol` that holds the logic to verify if the caller is Unlimited Leverage
  - If Unlimited Leverage changes it's address only one call to this contract needs to be performed to transfer the contract ownership privileges.

## Run

Unlimited uses [Foundry](https://book.getfoundry.sh/) as a solidity framework.

### Install dependencies

- `forge install`

### Compile solidity

- `forge build`

### Run tests

#### Run test on local node

- `forge test`

#### Run test in watch mode, with run-all parameter

This command will compile the project and run all tests when a file gets saved. Useful for development.

- `forge test -w --run-all`

### Run coverage report

Run coverage report in terminal

- `forge coverage`

Compile lcov report to be used by code editor extension and GitHub Jobs (i.e. [Coverage Gutters](https://github.com/ryanluker/vscode-coverage-gutters))

- `forge coverage --report lcov`

## Licensing

The primary license for Unlimited Leverate is the Business Source License 1.1 (`BUSL-1.1`), see [`LICENSE`](./LICENSE).

### Exceptions

- All files in `src/external/` are licensed under the license they were originally published with (as indicated in their SPDX headers)
- All files in `test/` are licensed under `MIT`.
