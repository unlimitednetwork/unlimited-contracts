# IPriceFeedAdapter
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IPriceFeedAdapter.sol)

Provides a way to convert an asset amount to a collateral amount and vice versa
Needs two PriceFeedAggregators: One for asset and one for collateral


## Functions
### name


```solidity
function name() external view returns (string memory);
```

### collateralToAssetMin


```solidity
function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);
```

### collateralToAssetMax


```solidity
function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);
```

### assetToCollateralMin


```solidity
function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);
```

### assetToCollateralMax


```solidity
function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);
```

### assetToUsdMin


```solidity
function assetToUsdMin(uint256 assetAmount) external view returns (uint256);
```

### assetToUsdMax


```solidity
function assetToUsdMax(uint256 assetAmount) external view returns (uint256);
```

### collateralToUsdMin


```solidity
function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);
```

### collateralToUsdMax


```solidity
function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);
```

### markPriceMin


```solidity
function markPriceMin() external view returns (int256);
```

### markPriceMax


```solidity
function markPriceMax() external view returns (int256);
```

