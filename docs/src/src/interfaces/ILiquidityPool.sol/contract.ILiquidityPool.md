# ILiquidityPool
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ILiquidityPool.sol)


## Functions
### deposit


```solidity
function deposit(uint256 amount, uint256 minOut) external returns (uint256);
```

### withdraw


```solidity
function withdraw(uint256 lpAmount, uint256 minOut) external returns (uint256);
```

### depositAndLock


```solidity
function depositAndLock(uint256 amount, uint256 minOut, uint256 poolId) external returns (uint256);
```

### requestLossPayout


```solidity
function requestLossPayout(uint256 loss) external;
```

### depositProfit


```solidity
function depositProfit(uint256 profit) external;
```

### depositFees


```solidity
function depositFees(uint256 amount) external;
```

### previewPoolsOf


```solidity
function previewPoolsOf(address user) external view returns (UserPoolDetails[] memory);
```

### previewRedeemPoolShares


```solidity
function previewRedeemPoolShares(uint256 poolShares_, uint256 poolId_) external view returns (uint256);
```

### updateDefaultLockTime


```solidity
function updateDefaultLockTime(uint256 defaultLockTime) external;
```

### updateEarlyWithdrawalFee


```solidity
function updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee) external;
```

### updateEarlyWithdrawalTime


```solidity
function updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime) external;
```

### updateMinimumAmount


```solidity
function updateMinimumAmount(uint256 minimumAmount) external;
```

### addPool


```solidity
function addPool(uint40 lockTime_, uint16 multiplier_) external returns (uint256);
```

### updatePool


```solidity
function updatePool(uint256 poolId_, uint40 lockTime_, uint16 multiplier_) external;
```

### availableLiquidity


```solidity
function availableLiquidity() external view returns (uint256);
```

### canTransferLps


```solidity
function canTransferLps(address user) external view returns (bool);
```

### canWithdrawLps


```solidity
function canWithdrawLps(address user) external view returns (bool);
```

### userWithdrawalFee


```solidity
function userWithdrawalFee(address user) external view returns (uint256);
```

## Events
### PoolAdded

```solidity
event PoolAdded(uint256 indexed poolId, uint256 lockTime, uint256 multiplier);
```

### PoolUpdated

```solidity
event PoolUpdated(uint256 indexed poolId, uint256 lockTime, uint256 multiplier);
```

### AddedToPool

```solidity
event AddedToPool(uint256 indexed poolId, uint256 assetAmount, uint256 amount, uint256 shares);
```

### RemovedFromPool

```solidity
event RemovedFromPool(address indexed user, uint256 indexed poolId, uint256 poolShares, uint256 lpShares);
```

### DepositedFees

```solidity
event DepositedFees(address liquidityPoolAdapter, uint256 amount);
```

### UpdatedDefaultLockTime

```solidity
event UpdatedDefaultLockTime(uint256 defaultLockTime);
```

### UpdatedEarlyWithdrawalFee

```solidity
event UpdatedEarlyWithdrawalFee(uint256 earlyWithdrawalFee);
```

### UpdatedEarlyWithdrawalTime

```solidity
event UpdatedEarlyWithdrawalTime(uint256 earlyWithdrawalTime);
```

### UpdatedMinimumAmount

```solidity
event UpdatedMinimumAmount(uint256 minimumAmount);
```

### DepositedProfit

```solidity
event DepositedProfit(address indexed liquidityPoolAdapter, uint256 profit);
```

### PayedOutLoss

```solidity
event PayedOutLoss(address indexed liquidityPoolAdapter, uint256 loss);
```

