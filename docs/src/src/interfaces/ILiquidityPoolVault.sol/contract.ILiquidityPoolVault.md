# ILiquidityPoolVault
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ILiquidityPoolVault.sol)


## Functions
### asset


```solidity
function asset() external view returns (address assetTokenAddress);
```

### totalAssets


```solidity
function totalAssets() external view returns (uint256 totalManagedAssets);
```

### convertToShares


```solidity
function convertToShares(uint256 assets) external view returns (uint256 shares);
```

### convertToAssets


```solidity
function convertToAssets(uint256 shares) external view returns (uint256 assets);
```

### previewDeposit


```solidity
function previewDeposit(uint256 assets) external view returns (uint256);
```

### previewMint


```solidity
function previewMint(uint256 shares) external view returns (uint256 assets);
```

### previewWithdraw


```solidity
function previewWithdraw(uint256 assets) external view returns (uint256 shares);
```

### previewRedeem


```solidity
function previewRedeem(uint256 shares) external view returns (uint256 assets);
```

## Events
### Deposit

```solidity
event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
```

### Withdraw

```solidity
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
```

