# ILiquidityPoolAdapter
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ILiquidityPoolAdapter.sol)


## Functions
### requestLossPayout


```solidity
function requestLossPayout(uint256 profit) external returns (uint256);
```

### depositProfit


```solidity
function depositProfit(uint256 profit) external;
```

### depositFees


```solidity
function depositFees(uint256 fee) external;
```

### availableLiquidity


```solidity
function availableLiquidity() external view returns (uint256);
```

## Events
### PayedOutLoss

```solidity
event PayedOutLoss(address indexed tradePair, uint256 loss);
```

### DepositedProfit

```solidity
event DepositedProfit(address indexed tradePair, uint256 profit);
```

### UpdatedMaxPayoutProportion

```solidity
event UpdatedMaxPayoutProportion(uint256 maxPayoutProportion);
```

### UpdatedLiquidityPools

```solidity
event UpdatedLiquidityPools(LiquidityPoolConfig[] liquidityPools);
```

