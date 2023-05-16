# UnlimitedPriceFeedAdapter
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/UnlimitedPriceFeedAdapter.sol)

**Inherits:**
[IPriceFeedAdapter](/src/interfaces/IPriceFeedAdapter.sol/contract.IPriceFeedAdapter.md), [UnlimitedPriceFeedUpdater](/src/price-feed/UnlimitedPriceFeedUpdater.sol/contract.UnlimitedPriceFeedUpdater.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md)

Gets the price data from the trusted Unlimited Leverage source.

*
The price is defined in token vs token price (e.g. ETH/USDC)
The Unlimited price has to be within a relative margin of the Chainlink one.
This acts as an additional price selfcheck with an external price feed source.
Limitation of this price feed is that Unlimited price, Chainlink asset and
Chainlink collateral price needs to be the same. This is done for optimization
puprposes as most Chainlink USD pairs have 8 decimals*


## State Variables
### MINIMUM_MAX_DEVIATION
Minimum value that can be set for max deviation.


```solidity
uint256 constant MINIMUM_MAX_DEVIATION = 5;
```


### name

```solidity
string public override name;
```


### collateralChainlinkPriceFeed

```solidity
AggregatorV2V3Interface public immutable collateralChainlinkPriceFeed;
```


### assetChainlinkPriceFeed

```solidity
AggregatorV2V3Interface public immutable assetChainlinkPriceFeed;
```


### ASSET_MULTIPLIER

```solidity
uint256 private immutable ASSET_MULTIPLIER;
```


### COLLATERAL_MULTIPLIER

```solidity
uint256 private immutable COLLATERAL_MULTIPLIER;
```


### maxDeviation

```solidity
uint256 public maxDeviation;
```


## Functions
### constructor

Constructs the UnlimitedPriceFeedAdapter contract.


```solidity
constructor(
    string memory name_,
    AggregatorV2V3Interface collateralChainlinkPriceFeed_,
    AggregatorV2V3Interface assetChainlinkPriceFeed_,
    uint256 assetDecimals_,
    uint256 collateralDecimals_,
    uint256 maxDeviation_,
    IController controller_,
    uint256 priceDecimals_,
    IUnlimitedOwner unlimitedOwner_
) UnlimitedPriceFeedUpdater(controller_, priceDecimals_) UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the price feed adapter.|
|`collateralChainlinkPriceFeed_`|`AggregatorV2V3Interface`|The address of the Chainlink price feed for the collateral, needed for usd price.|
|`assetChainlinkPriceFeed_`|`AggregatorV2V3Interface`|The address of the Chainlink price feed for the asset, needed for usd price.|
|`assetDecimals_`|`uint256`||
|`collateralDecimals_`|`uint256`||
|`maxDeviation_`|`uint256`||
|`controller_`|`IController`|The address of the controller contract.|
|`priceDecimals_`|`uint256`|Decimal places in a price.|
|`unlimitedOwner_`|`IUnlimitedOwner`||


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


### _collateralToAsset


```solidity
function _collateralToAsset(uint256 collateralAmount_) private view returns (uint256);
```

### assetToCollateralMax

Returns maximum collateral equivalent to the asset amount


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


### _assetToCollateral


```solidity
function _assetToCollateral(uint256 assetAmount_) private view returns (uint256);
```

### assetToUsdMin

Returns the minimum usd equivalent to the asset amount

*The minimum collateral amount gets returned. It takes into accounts the minimum price.
NOTE: This price should not be used to calculate PnL of the trades*


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

*The maximum collateral amount gets returned. It takes into accounts the maximum price.
NOTE: This price should not be used to calculate PnL of the trades*


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


### _assetToUsd


```solidity
function _assetToUsd(uint256 assetAmount_) private view returns (uint256);
```

### collateralToUsdMin

Returns the minimum usd equivalent to the collateral amount

*The minimum collateral amount gets returned. It takes into accounts the minimum price.
NOTE: This price should not be used to calculate PnL of the trades*


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

*The maximum collateral amount gets returned. It takes into accounts the maximum price.
NOTE: This price should not be used to calculate PnL of the trades*


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


### _collateralToUsd


```solidity
function _collateralToUsd(uint256 collateralAmount_) private view returns (uint256);
```

### markPriceMax

Returns the max price of the asset in the collateral

*Returns price of the last updated round*


```solidity
function markPriceMax() external view returns (int256);
```

### markPriceMin

Returns the min price of the asset in the collateral

*Returns price of the last updated round*


```solidity
function markPriceMin() external view returns (int256);
```

### updateMaxDeviation

Updates the maximum deviation from the chainlink price feed.


```solidity
function updateMaxDeviation(uint256 maxDeviation_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxDeviation_`|`uint256`|The new maximum deviation.|


### _updateMaxDeviation


```solidity
function _updateMaxDeviation(uint256 maxDeviation_) private;
```

### _verifyNewPrice


```solidity
function _verifyNewPrice(int256 newPrice) internal view override;
```

### _getChainlinkPrice


```solidity
function _getChainlinkPrice() internal view returns (int256);
```

