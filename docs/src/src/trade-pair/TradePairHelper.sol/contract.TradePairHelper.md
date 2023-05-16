# TradePairHelper
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/trade-pair/TradePairHelper.sol)

**Inherits:**
[ITradePairHelper](/src/interfaces/ITradePairHelper.sol/contract.ITradePairHelper.md)


## Functions
### positionIdsOf

Returns all position ids of a maker


```solidity
function positionIdsOf(address maker_, ITradePair[] calldata tradePairs_)
    external
    view
    returns (uint256[][] memory positionIds);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|The maker to get the position ids of|
|`tradePairs_`|`ITradePair[]`|The TradePairs to get the position ids of|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`positionIds`|`uint256[][]`|All position ids of the maker|


### positionDetailsOf

Returns all PositionDetails of a maker


```solidity
function positionDetailsOf(address maker_, ITradePair[] calldata tradePairs_)
    external
    view
    returns (PositionDetails[][] memory positionDetails);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|The maker to get the PositionDetails of|
|`tradePairs_`|`ITradePair[]`|The TradePairs to get the PositionDetails of|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`positionDetails`|`PositionDetails[][]`|All PositionDetails of the maker|


### pricesOf

Returns the current prices (min and max) of the given TradePairs


```solidity
function pricesOf(ITradePair[] calldata tradePairs_) external view override returns (PricePair[] memory prices);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePairs_`|`ITradePair[]`|The TradePairs to get the current prices of|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`prices`|`PricePair[]`|PricePairy[] of min and max prices|


