# PriceFeedAdapter
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/PriceFeedAdapter.sol)

**Inherits:**
[IPriceFeedAdapter](/src/interfaces/IPriceFeedAdapter.sol/contract.IPriceFeedAdapter.md)

Aggregates prices from a price feed and offers exchange rates from asset to collateral.


## State Variables
### assetPriceFeedAggregator
Price Feed Aggregator for the asset


```solidity
IPriceFeedAggregator immutable assetPriceFeedAggregator;
```


### collateralPriceFeedAggregator
Price Feed Aggregator for the collateral


```solidity
IPriceFeedAggregator immutable collateralPriceFeedAggregator;
```


### name

```solidity
string public override name;
```


### ASSET_MULTIPLIER

```solidity
uint256 private immutable ASSET_MULTIPLIER;
```


### COLLATERAL_MULTIPLIER

```solidity
uint256 private immutable COLLATERAL_MULTIPLIER;
```


## Functions
### constructor

Constructs the PriceFeedAdapter contract.


```solidity
constructor(
    string memory name_,
    IPriceFeedAggregator assetPriceFeedAggregator_,
    IPriceFeedAggregator collateralPriceFeedAggregator_,
    uint256 assetDecimals_,
    uint256 collateralDecimals_
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the price feed adapter.|
|`assetPriceFeedAggregator_`|`IPriceFeedAggregator`|The address of the price feed aggregator for the asset.|
|`collateralPriceFeedAggregator_`|`IPriceFeedAggregator`|The address of the price feed aggregator for the collateral.|
|`assetDecimals_`|`uint256`|The decimals of the asset.|
|`collateralDecimals_`|`uint256`|The decimals of the collateral.|


### collateralToAssetMax

Returns max asset equivalent to the collateral amount


```solidity
function collateralToAssetMax(uint256 collateralAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount_`|`uint256`|the amount of collateral|


### collateralToAssetMin

Returns min asset equivalent to the collateral amount


```solidity
function collateralToAssetMin(uint256 collateralAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount_`|`uint256`|the amount of collateral|


### assetToCollateralMax

Returns maximumim collateral equivalent to the asset amount


```solidity
function assetToCollateralMax(uint256 assetAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetAmount_`|`uint256`|the amount of asset|


### assetToCollateralMin

Returns minimum collateral equivalent to the asset amount


```solidity
function assetToCollateralMin(uint256 assetAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetAmount_`|`uint256`|the amount of asset|


### assetToUsdMin

Returns the minimum usd equivalent to the asset amount

*The minimum collateral amount gets returned. It takes into accounts the minimum price.*


```solidity
function assetToUsdMin(uint256 assetAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetAmount_`|`uint256`|the amount of asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of usd|


### assetToUsdMax

Returns the maximum usd equivalent to the asset amount

*The maximum collateral amount gets returned. It takes into accounts the maximum price.*


```solidity
function assetToUsdMax(uint256 assetAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetAmount_`|`uint256`|the amount of asset|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of usd|


### collateralToUsdMin

Returns the minimum usd equivalent to the collateral amount

*The minimum collateral amount gets returned. It takes into accounts the minimum price.*


```solidity
function collateralToUsdMin(uint256 collateralAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount_`|`uint256`|the amount of collateral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of usd|


### collateralToUsdMax

Returns the maximum usd equivalent to the collateral amount

*The maximum collateral amount gets returned. It takes into accounts the maximum price.*


```solidity
function collateralToUsdMax(uint256 collateralAmount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount_`|`uint256`|the amount of collateral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of usd|


### markPriceMax

Returns the max price of the asset in the collateral

*Takes into account the maximum price of the asset and the minimum price of the collateral*


```solidity
function markPriceMax() external view returns (int256);
```

### markPriceMin

Returns the min price of the asset in the collateral

*Takes into account the minimum price of the asset and the maximum price of the collateral*


```solidity
function markPriceMin() external view returns (int256);
```

