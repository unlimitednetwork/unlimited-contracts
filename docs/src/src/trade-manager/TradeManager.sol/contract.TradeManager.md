# TradeManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/trade-manager/TradeManager.sol)

**Inherits:**
[ITradeManager](/src/interfaces/ITradeManager.sol/contract.ITradeManager.md)

Facilitates trading on trading pairs.


## State Variables
### controller

```solidity
IController public immutable controller;
```


### userManager

```solidity
IUserManager public immutable userManager;
```


## Functions
### constructor

Constructs the TradeManager contract.


```solidity
constructor(IController controller_, IUserManager userManager_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`controller_`|`IController`|The address of the controller.|
|`userManager_`|`IUserManager`|The address of the user manager.|


### _openPosition

Opens a position for a trading pair.


```solidity
function _openPosition(OpenPositionParams memory params_, address maker_) internal returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`OpenPositionParams`|The parameters for opening a position.|
|`maker_`|`address`|Maker of the position|


### _closePosition

Closes a position for a trading pair.


```solidity
function _closePosition(ClosePositionParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`ClosePositionParams`|The parameters for closing the position.|
|`maker_`|`address`|Maker of the position|


### _partiallyClosePosition

Partially closes a position on a trade pair.


```solidity
function _partiallyClosePosition(PartiallyClosePositionParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`PartiallyClosePositionParams`|The parameters for partially closing the position.|
|`maker_`|`address`|Maker of the position|


### _removeMarginFromPosition

Removes margin from a position


```solidity
function _removeMarginFromPosition(RemoveMarginFromPositionParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`RemoveMarginFromPositionParams`|The parameters for removing margin from the position.|
|`maker_`|`address`|Maker of the position|


### _addMarginToPosition

Adds margin to a position


```solidity
function _addMarginToPosition(AddMarginToPositionParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`AddMarginToPositionParams`|The parameters for adding margin to the position.|
|`maker_`|`address`|Maker of the position|


### _extendPosition

Extends position with margin and loan.


```solidity
function _extendPosition(ExtendPositionParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`ExtendPositionParams`|The parameters for extending the position.|
|`maker_`|`address`|Maker of the position|


### _extendPositionToLeverage

Extends position with loan to target leverage.


```solidity
function _extendPositionToLeverage(ExtendPositionToLeverageParams memory params_, address maker_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params_`|`ExtendPositionToLeverageParams`|The parameters for extending the position to target leverage.|
|`maker_`|`address`|Maker of the position|


### liquidatePosition

Liquidates position


```solidity
function liquidatePosition(address tradePair_, uint256 positionId_, UpdateData[] calldata updateData_)
    public
    onlyActiveTradePair(tradePair_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|
|`positionId_`|`uint256`|position id|
|`updateData_`|`UpdateData[]`|Data to update state before the execution of the function|


### _tryLiquidatePosition

Try to liquidate a position, return false if call reverts


```solidity
function _tryLiquidatePosition(address tradePair_, uint256 positionId_, address maker_)
    internal
    onlyActiveTradePair(tradePair_)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|
|`positionId_`|`uint256`|position id|
|`maker_`|`address`||


### batchLiquidatePositions

Trys to liquidates all given positions

*Requirements
- `tradePairs` and `positionIds` must have the same length*


```solidity
function batchLiquidatePositions(
    address[] calldata tradePairs,
    uint256[][] calldata positionIds,
    bool allowRevert,
    UpdateData[] calldata updateData_
) external returns (bool[][] memory didLiquidate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePairs`|`address[]`|addresses of the trade pairs|
|`positionIds`|`uint256[][]`|position ids|
|`allowRevert`|`bool`|if true, reverts if any call reverts|
|`updateData_`|`UpdateData[]`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`didLiquidate`|`bool[][]`|bool[][] results of the individual liquidation calls|


### _batchLiquidatePositionsOfTradePair

Trys to liquidates given positions of a trade pair


```solidity
function _batchLiquidatePositionsOfTradePair(
    address tradePair,
    uint256[] calldata positionIds,
    bool allowRevert,
    address maker_
) internal returns (bool[] memory didLiquidate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair`|`address`|address of the trade pair|
|`positionIds`|`uint256[]`|position ids|
|`allowRevert`|`bool`|if true, reverts if any call reverts|
|`maker_`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`didLiquidate`|`bool[]`|bool[] results of the individual liquidation calls|


### detailsOfPosition

returns the details of a position

*returns PositionDetails struct*


```solidity
function detailsOfPosition(address tradePair_, uint256 positionId_) external view returns (PositionDetails memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|
|`positionId_`|`uint256`|id of the position|


### positionIsLiquidatable

Indicates if a position is liquidatable


```solidity
function positionIsLiquidatable(address tradePair_, uint256 positionId_) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|
|`positionId_`|`uint256`|id of the position|


### canLiquidatePositions

Indicates if the positions are liquidatable

*Requirements:
- tradePairs_ and positionIds_ must have the same length*


```solidity
function canLiquidatePositions(address[] calldata tradePairs_, uint256[][] calldata positionIds_)
    external
    view
    returns (bool[][] memory canLiquidate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePairs_`|`address[]`|addresses of the trade pairs|
|`positionIds_`|`uint256[][]`|ids of the positions|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`canLiquidate`|`bool[][]`|array of bools indicating if the positions are liquidatable|


### _canLiquidatePositionsAtTradePair

Indicates if the positions are liquidatable


```solidity
function _canLiquidatePositionsAtTradePair(address tradePair_, uint256[] calldata positionIds_)
    internal
    view
    returns (bool[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|
|`positionIds_`|`uint256[]`|ids of the positions|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool[]`|canLiquidate array of bools indicating if the positions are liquidatable|


### getCurrentFundingFeeRates

Returns the current funding fee rates of a trade pair


```solidity
function getCurrentFundingFeeRates(address tradePair_)
    external
    view
    returns (int256 longFundingFeeRate, int256 shortFundingFeeRate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`longFundingFeeRate`|`int256`|long funding fee rate|
|`shortFundingFeeRate`|`int256`|short funding fee rate|


### totalAssetAmountLimitOfTradePair

Returns the maximum size in assets of a tradePair


```solidity
function totalAssetAmountLimitOfTradePair(address tradePair_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|maxSize maximum size|


### _verifyConstraints

*Checks if constraints_ are satisfied. If not, reverts.
When the transaction staid in the mempool for a long time, the price may change.
- Price is in price range
- Deadline is not exceeded*


```solidity
function _verifyConstraints(address tradePair_, Constraints calldata constraints_, UsePrice usePrice_) internal view;
```

### _updateContracts

*Updates all updatdable contracts. Reverts if one update operation is invalid or not successfull.*


```solidity
function _updateContracts(UpdateData[] calldata updateData_) internal;
```

### onlyActiveTradePair

Checks if trading pair is active.


```solidity
modifier onlyActiveTradePair(address tradePair_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair|


