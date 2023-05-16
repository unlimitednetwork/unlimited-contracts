# PositionMaths
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/PositionMaths.sol)

Provides financial maths for leveraged positions.


## Functions
### entryPrice

External Functions

Price at entry level


```solidity
function entryPrice(Position storage self) public view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|price int|


### _entryPrice


```solidity
function _entryPrice(Position storage self) internal view returns (int256);
```

### entryLeverage

Leverage at entry level


```solidity
function entryLeverage(Position storage self) public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|leverage uint|


### _entryLeverage


```solidity
function _entryLeverage(Position storage self) internal view returns (uint256);
```

### lastNetLeverage

Last net leverage is calculated with the last net margin, which is entry margin minus last total fees. Margin of zero means position is liquidatable.

*this value is only valid when the position got updated at the same block*


```solidity
function lastNetLeverage(Position storage self) public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|net leverage uint. When margin is less than zero, leverage is max uint256|


### _lastNetLeverage


```solidity
function _lastNetLeverage(Position storage self) internal view returns (uint256);
```

### currentNetMargin

Current Net Margin, which is entry margin minus current total fees. Margin of zero means position is liquidatable.


```solidity
function currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    public
    view
    returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|net margin int|


### _currentNetMargin


```solidity
function _currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    internal
    view
    returns (uint256);
```

### lastNetMargin

Returns the last net margin, calculated at the moment of last fee update

*this value is only valid when the position got updated at the same block
It is a convenience function because the caller does not need to provice fee integrals*


```solidity
function lastNetMargin(Position storage self) internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|last net margin uint. Can be zero.|


### _lastNetMargin


```solidity
function _lastNetMargin(Position storage self) internal view returns (uint256);
```

### currentNetLeverage

Current Net Leverage, which is entry volume divided by current net margin


```solidity
function currentNetLeverage(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    public
    view
    returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|current net leverage|


### _currentNetLeverage


```solidity
function _currentNetLeverage(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    internal
    view
    returns (uint256);
```

### liquidationPrice

Liquidation price takes into account fee-reduced collateral and absolute maintenance margin


```solidity
function liquidationPrice(
    Position storage self,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral,
    uint256 maintenanceMargin
) public view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|liquidationPrice int|


### _liquidationPrice


```solidity
function _liquidationPrice(
    Position storage self,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral,
    uint256 maintenanceMargin
) internal view returns (int256);
```

### _shortMultiplier


```solidity
function _shortMultiplier(Position storage self) internal view returns (int256);
```

### currentVolume

Current Volume is the current mark price times the asset amount (this is not the current value)


```solidity
function currentVolume(Position storage self, int256 currentPrice) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|currentVolume uint|


### _currentVolume


```solidity
function _currentVolume(Position storage self, int256 currentPrice) internal view returns (uint256);
```

### currentPnL

Current Profit and Losses (without fees)


```solidity
function currentPnL(Position storage self, int256 currentPrice) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentPnL int|


### _currentPnL


```solidity
function _currentPnL(Position storage self, int256 currentPrice) internal view returns (int256);
```

### currentValue

Current Value is the derived value that takes into account entry volume and PNL

*This value is shown on the UI. It normalized the differences of LONG/SHORT into a single value*


```solidity
function currentValue(Position storage self, int256 currentPrice) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentValue int|


### _currentValue


```solidity
function _currentValue(Position storage self, int256 currentPrice) internal view returns (int256);
```

### currentEquity

Current Equity (without fees)


```solidity
function currentEquity(Position storage self, int256 currentPrice) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentEquity int|


### _currentEquity


```solidity
function _currentEquity(Position storage self, int256 currentPrice) internal view returns (int256);
```

### currentTotalFeeAmount


```solidity
function currentTotalFeeAmount(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    public
    view
    returns (int256);
```

### _currentTotalFeeAmount


```solidity
function _currentTotalFeeAmount(
    Position storage self,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral
) internal view returns (int256);
```

### currentFundingFeeAmount

Current Amount of Funding Fee, accumulated over time


```solidity
function currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
    public
    view
    returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentFundingFeeIntegral`|`int256`|uint current funding fee integral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentFundingFeeAmount int|


### _currentFundingFeeAmount


```solidity
function _currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
    internal
    view
    returns (int256);
```

### currentBorrowFeeAmount

Current amount of borrow fee, accumulated over time


```solidity
function currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentBorrowFeeIntegral`|`int256`|uint current fee integral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentBorrowFeeAmount int|


### _currentBorrowFeeAmount


```solidity
function _currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral)
    internal
    view
    returns (int256);
```

### currentNetPnL

Current Net PnL, including fees


```solidity
function currentNetPnL(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral
) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|
|`currentBorrowFeeIntegral`|`int256`|uint current fee integral|
|`currentFundingFeeIntegral`|`int256`|uint current funding fee integral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentNetPnL int|


### _currentNetPnL


```solidity
function _currentNetPnL(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral
) internal view returns (int256);
```

### currentNetEquity

Current Net Equity, including fees


```solidity
function currentNetEquity(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral
) public view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|
|`currentBorrowFeeIntegral`|`int256`|uint current fee integral|
|`currentFundingFeeIntegral`|`int256`|uint current funding fee integral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|currentNetEquity int|


### _currentNetEquity


```solidity
function _currentNetEquity(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral
) internal view returns (int256);
```

### isLiquidatable

Determines if the position can be liquidated

*A position is liquidatable, when either the margin or the current equity
falls under or equals the absolute maintenance margin*


```solidity
function isLiquidatable(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral,
    uint256 absoluteMaintenanceMargin
) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|
|`currentBorrowFeeIntegral`|`int256`|uint current fee integral|
|`currentFundingFeeIntegral`|`int256`|uint current funding fee integral|
|`absoluteMaintenanceMargin`|`uint256`|absolute amount of maintenance margin.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|isLiquidatable bool|


### _isLiquidatable


```solidity
function _isLiquidatable(
    Position storage self,
    int256 currentPrice,
    int256 currentBorrowFeeIntegral,
    int256 currentFundingFeeIntegral,
    uint256 absoluteMaintenanceMargin
) internal view returns (bool);
```

### partiallyClose

Partially closes a position


```solidity
function partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion) public returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|int current mark price|
|`closeProportion`|`uint256`|the share of the position that should be closed|


### _partiallyClose

*Partially closing works as follows:
1. Sell a share of the position, and use the proceeds to either:
2.a) Get a payout and by this, leave the leverage as it is
2.b) "Buy" new margin and by this decrease the leverage
2.c) a mixture of 2.a) and 2.b)*


```solidity
function _partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion)
    internal
    returns (int256);
```

### addMargin

Adds margin to a position


```solidity
function addMargin(Position storage self, uint256 addedMargin) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`addedMargin`|`uint256`|the margin that gets added to the position|


### _addMargin


```solidity
function _addMargin(Position storage self, uint256 addedMargin) internal;
```

### removeMargin

Removes margin from a position

*The remaining equity has to stay positive*


```solidity
function removeMargin(Position storage self, uint256 removedMargin) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`removedMargin`|`uint256`|the margin to remove|


### _removeMargin


```solidity
function _removeMargin(Position storage self, uint256 removedMargin) internal;
```

### extend

Extends position with margin and loan.


```solidity
function extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`addedMargin`|`uint256`|Margin added to position.|
|`addedAssetAmount`|`uint256`|Asset amount added to position.|
|`addedVolume`|`uint256`|Loan added to position.|


### _extend


```solidity
function _extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume) internal;
```

### extendToLeverage

Extends position with loan to target leverage.


```solidity
function extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`self`|`Position`||
|`currentPrice`|`int256`|current asset price|
|`targetLeverage`|`uint256`|target leverage|


### _extendToLeverage


```solidity
function _extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) internal;
```

### exists

Returns if the position exists / is open


```solidity
function exists(Position storage self) public view returns (bool);
```

### _exists


```solidity
function _exists(Position storage self) internal view returns (bool);
```

### updateFees


```solidity
function updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) public;
```

### _updateFees

Internal Functions (that are only called internally and not mirror a public function)


```solidity
function _updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
    internal;
```

