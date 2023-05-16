# PositionStatsLib
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/PositionStats.sol)

Provides data structures and functions for Aggregated positions statistics at TradePair

*This contract is a library and should be used by a contract that implements the ITradePair interface
Provides methods to keep track of total volume, margin and volume for long and short positions*


## State Variables
### PERCENTAGE_MULTIPLIER

```solidity
uint256 constant PERCENTAGE_MULTIPLIER = 1_000_000;
```


## Functions
### addTotalCount

add total margin, volume and size


```solidity
function addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
    public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`PositionStats`||
|`margin`|`uint256`|the margin to add|
|`volume`|`uint256`|the volume to add|
|`size`|`uint256`|the size to add|
|`isShort`|`bool`|bool if the data belongs to a short position|


### removeTotalCount

remove total margin, volume and size


```solidity
function removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
    public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`PositionStats`||
|`margin`|`uint256`|the margin to remove|
|`volume`|`uint256`|the volume to remove|
|`size`|`uint256`|the size to remove|
|`isShort`|`bool`|bool if the data belongs to a short position|


### _addTotalCount

add total margin, volume and size


```solidity
function _addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`PositionStats`||
|`margin`|`uint256`|the margin to add|
|`volume`|`uint256`|the volume to add|
|`size`|`uint256`|the size to add|
|`isShort`|`bool`|bool if the data belongs to a short position|


### _removeTotalCount

remove total margin, volume and size


```solidity
function _removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`PositionStats`||
|`margin`|`uint256`|the margin to remove|
|`volume`|`uint256`|the volume to remove|
|`size`|`uint256`|the size to remove|
|`isShort`|`bool`|bool if the data belongs to a short position|


