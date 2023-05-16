# ChainlinkUsdPriceFeedPrevious
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/ChainlinkUsdPriceFeedPrevious.sol)

**Inherits:**
[IPriceFeed](/src/interfaces/IPriceFeed.sol/contract.IPriceFeed.md)

Price feed that returns the previous price from Chainlink.

*The previous price is used by PriceFeedAggregator in case there is only one price feed. By this a price spread
can be simulated. A price spread is used to offer different prices for buy and sell operations.*


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

Returns previous price


```solidity
function price() external view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|the price from the previous round|


