# ChainlinkUsdPriceFeed
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/ChainlinkUsdPriceFeed.sol)

**Inherits:**
[IPriceFeed](/src/interfaces/IPriceFeed.sol/contract.IPriceFeed.md)


## State Variables
### chainlinkPriceFeed

```solidity
AggregatorV2V3Interface internal immutable chainlinkPriceFeed;
```


## Functions
### constructor

Constructs the ChainlinkUsdPriceFeed contract.


```solidity
constructor(AggregatorV2V3Interface chainlinkPriceFeed_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainlinkPriceFeed_`|`AggregatorV2V3Interface`|The address of the Chainlink price feed.|


### price

Returns last price


```solidity
function price() external view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|the price from the last round|


