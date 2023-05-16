# IController
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IController.sol)


## Functions
### isTradePair

Is trade pair registered


```solidity
function isTradePair(address tradePair) external view returns (bool);
```

### isLiquidityPool

Is liquidity pool registered


```solidity
function isLiquidityPool(address liquidityPool) external view returns (bool);
```

### isLiquidityPoolAdapter

Is liquidity pool adapter registered


```solidity
function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);
```

### isPriceFeed

Is price fee adapter registered


```solidity
function isPriceFeed(address priceFeed) external view returns (bool);
```

### isUpdatable

Is contract updatable


```solidity
function isUpdatable(address contractAddress) external view returns (bool);
```

### isSigner

Is Signer registered


```solidity
function isSigner(address signer) external view returns (bool);
```

### isOrderExecutor

Is order executor registered


```solidity
function isOrderExecutor(address orderExecutor) external view returns (bool);
```

### checkTradePairActive

Reverts if trade pair inactive


```solidity
function checkTradePairActive(address tradePair) external view;
```

### orderRewardOfCollateral

Returns order reward for collateral token


```solidity
function orderRewardOfCollateral(address collateral) external view returns (uint256);
```

### addTradePair

Adds the trade pair to the registry


```solidity
function addTradePair(address tradePair) external;
```

### addLiquidityPool

Adds the liquidity pool to the registry


```solidity
function addLiquidityPool(address liquidityPool) external;
```

### addLiquidityPoolAdapter

Adds the liquidity pool adapter to the registry


```solidity
function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;
```

### addPriceFeed

Adds the price feed to the registry


```solidity
function addPriceFeed(address priceFeed) external;
```

### addUpdatable

Adds updatable contract to the registry


```solidity
function addUpdatable(address) external;
```

### addSigner

Adds signer to the registry


```solidity
function addSigner(address) external;
```

### addOrderExecutor

Adds order executor to the registry


```solidity
function addOrderExecutor(address) external;
```

### removeTradePair

Removes the trade pair from the registry


```solidity
function removeTradePair(address tradePair) external;
```

### removeLiquidityPool

Removes the liquidity pool from the registry


```solidity
function removeLiquidityPool(address liquidityPool) external;
```

### removeLiquidityPoolAdapter

Removes the liquidity pool adapter from the registry


```solidity
function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;
```

### removePriceFeed

Removes the price feed from the registry


```solidity
function removePriceFeed(address priceFeed) external;
```

### removeUpdatable

Removes updatable from the registry


```solidity
function removeUpdatable(address) external;
```

### removeSigner

Removes signer from the registry


```solidity
function removeSigner(address) external;
```

### removeOrderExecutor

Removes order executor from the registry


```solidity
function removeOrderExecutor(address) external;
```

### setOrderRewardOfCollateral

Sets order reward for collateral token


```solidity
function setOrderRewardOfCollateral(address, uint256) external;
```

## Events
### TradePairAdded

```solidity
event TradePairAdded(address indexed tradePair);
```

### LiquidityPoolAdded

```solidity
event LiquidityPoolAdded(address indexed liquidityPool);
```

### LiquidityPoolAdapterAdded

```solidity
event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);
```

### PriceFeedAdded

```solidity
event PriceFeedAdded(address indexed priceFeed);
```

### UpdatableAdded

```solidity
event UpdatableAdded(address indexed updatable);
```

### TradePairRemoved

```solidity
event TradePairRemoved(address indexed tradePair);
```

### LiquidityPoolRemoved

```solidity
event LiquidityPoolRemoved(address indexed liquidityPool);
```

### LiquidityPoolAdapterRemoved

```solidity
event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);
```

### PriceFeedRemoved

```solidity
event PriceFeedRemoved(address indexed priceFeed);
```

### UpdatableRemoved

```solidity
event UpdatableRemoved(address indexed updatable);
```

### SignerAdded

```solidity
event SignerAdded(address indexed signer);
```

### SignerRemoved

```solidity
event SignerRemoved(address indexed signer);
```

### OrderExecutorAdded

```solidity
event OrderExecutorAdded(address indexed orderExecutor);
```

### OrderExecutorRemoved

```solidity
event OrderExecutorRemoved(address indexed orderExecutor);
```

### SetOrderRewardOfCollateral

```solidity
event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);
```

