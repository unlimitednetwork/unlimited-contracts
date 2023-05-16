# PriceFeedAggregator
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/PriceFeedAggregator.sol)

**Inherits:**
[IPriceFeedAggregator](/src/interfaces/IPriceFeedAggregator.sol/contract.IPriceFeedAggregator.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md)

Aggregates prices from one or multiple price feeds.
Provides min and max price and asset to usd conversion


## State Variables
### USD_MULTIPLIER

```solidity
uint256 constant USD_MULTIPLIER = 1e8;
```


### priceFeeds

```solidity
IPriceFeed[] priceFeeds;
```


### name

```solidity
string public name;
```


### assetDecimals

```solidity
uint256 public immutable assetDecimals;
```


## Functions
### constructor

Constructs the PriceFeedAggregator contract.


```solidity
constructor(
    IUnlimitedOwner unlimitedOwner_,
    string memory name_,
    uint256 assetDecimals_,
    IPriceFeed[] memory priceFeeds_
) UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The address of the unlimited owner.|
|`name_`|`string`|The name of the price feed aggregator.|
|`assetDecimals_`|`uint256`|The decimals of the asset.|
|`priceFeeds_`|`IPriceFeed[]`|The addresses of the price feeds.|


### addPriceFeed

Adds a price feeds


```solidity
function addPriceFeed(IPriceFeed priceFeed_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`priceFeed_`|`IPriceFeed`|the price feed|


### removePriceFeed

Removes PriceFeed at the index


```solidity
function removePriceFeed(uint256 index_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`index_`|`uint256`|the index of the price feed|


### minPrice

returns the current minimum price


```solidity
function minPrice() external view returns (int256);
```

### maxPrice

returns the current maximum price


```solidity
function maxPrice() external view returns (int256);
```

### minMaxPrices

returns minimum and maximum prices


```solidity
function minMaxPrices() public view returns (int256, int256);
```

### _minMaxFromMultiplePriceFeeds


```solidity
function _minMaxFromMultiplePriceFeeds() internal view returns (int256, int256);
```

