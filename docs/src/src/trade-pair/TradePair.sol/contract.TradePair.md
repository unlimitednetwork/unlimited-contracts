# TradePair
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/trade-pair/TradePair.sol)

**Inherits:**
[ITradePair](/src/interfaces/ITradePair.sol/contract.ITradePair.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md), Initializable


## State Variables
### SURPLUS_MULTIPLIER

```solidity
uint256 private constant SURPLUS_MULTIPLIER = 1_000_000;
```


### BPS_MULTIPLIER

```solidity
uint256 private constant BPS_MULTIPLIER = 100_00;
```


### MIN_LEVERAGE

```solidity
uint256 private constant MIN_LEVERAGE = 11 * LEVERAGE_MULTIPLIER / 10;
```


### MAX_LEVERAGE

```solidity
uint256 private constant MAX_LEVERAGE = 100 * LEVERAGE_MULTIPLIER;
```


### USD_TRIM

```solidity
uint256 private constant USD_TRIM = 10 ** 8;
```


### tradeManager
Trade manager that manages trades.


```solidity
ITradeManager public immutable tradeManager;
```


### userManager
manages fees per user


```solidity
IUserManager public immutable userManager;
```


### feeManager
Fee Manager that collects and distributes fees


```solidity
IFeeManager public immutable feeManager;
```


### priceFeedAdapter
The price feed to calculate asset to collateral amounts


```solidity
IPriceFeedAdapter public priceFeedAdapter;
```


### liquidityPoolAdapter
The liquidity pool adapter that the funds will get borrowed from


```solidity
ILiquidityPoolAdapter public liquidityPoolAdapter;
```


### collateral
The token that is used as a collateral


```solidity
IERC20 public collateral;
```


### name
The name of this trade pair


```solidity
string public name;
```


### assetDecimals
Decimals of the asset


```solidity
uint256 public assetDecimals;
```


### minLeverage
Minimum Leverage


```solidity
uint128 public minLeverage;
```


### maxLeverage
Maximum Leverage


```solidity
uint128 public maxLeverage;
```


### minMargin
Minimum margin


```solidity
uint256 public minMargin;
```


### volumeLimit
Maximum Volume a position can have


```solidity
uint256 public volumeLimit;
```


### totalAssetAmountLimit
Limit for the total size of all positions


```solidity
uint256 public totalAssetAmountLimit;
```


### liquidatorReward
reward for liquidator


```solidity
uint256 public liquidatorReward;
```


### positions
The positions of this tradepair


```solidity
mapping(uint256 => Position) positions;
```


### positionIdToWhiteLabel
Maps position id to the white label address that opened a position

*White label recieves part of the open and close position fees collected*


```solidity
mapping(uint256 => address) public positionIdToWhiteLabel;
```


### userToPositionIds
position ids of each user


```solidity
mapping(address => uint256[]) public userToPositionIds;
```


### nextId
increasing counter for the next position id


```solidity
uint256 public nextId = 0;
```


### positionStats
Keeps track of total amounts of positions


```solidity
PositionStats public positionStats;
```


### feeIntegral
Calculates the fee integrals


```solidity
FeeIntegral public feeIntegral;
```


### feeBuffer
Keeps track of the fee buffer


```solidity
FeeBuffer public feeBuffer;
```


### overcollectedFees
Amount of overcollected fees


```solidity
int256 public overcollectedFees;
```


## Functions
### constructor

Constructs the TradePair contract


```solidity
constructor(
    IUnlimitedOwner unlimitedOwner_,
    ITradeManager tradeManager_,
    IUserManager userManager_,
    IFeeManager feeManager_
) UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The Unlimited Owner constract|
|`tradeManager_`|`ITradeManager`|The TradeManager contract|
|`userManager_`|`IUserManager`|The UserManager contract|
|`feeManager_`|`IFeeManager`|The FeeManager contract|


### initialize

Initializes state variables


```solidity
function initialize(
    string calldata name_,
    IERC20Metadata collateral_,
    uint256 assetDecimals_,
    IPriceFeedAdapter priceFeedAdapter_,
    ILiquidityPoolAdapter liquidityPoolAdapter_
) external onlyOwner initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of this trade pair|
|`collateral_`|`IERC20Metadata`|the collateral ERC20 contract|
|`assetDecimals_`|`uint256`|the decimals of the asset|
|`priceFeedAdapter_`|`IPriceFeedAdapter`|The price feed adapter|
|`liquidityPoolAdapter_`|`ILiquidityPoolAdapter`|The liquidity pool adapter|


### openPosition

opens a position


```solidity
function openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_, address whitelabelAddress)
    external
    verifyLeverage(leverage_)
    onlyTradeManager
    syncFeesBefore
    checkAssetAmountLimitAfter
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|owner of the position|
|`margin_`|`uint256`|the amount of collateral used as a margin|
|`leverage_`|`uint256`|the target leverage, should respect LEVERAGE_MULTIPLIER|
|`isShort_`|`bool`|bool if the position is a short position|
|`whitelabelAddress`|`address`||


### _openPosition

*Should have received margin from TradeManager*


```solidity
function _openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_) private returns (uint256);
```

### closePosition

Closes A position


```solidity
function closePosition(address maker_, uint256 positionId_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|address of the maker of this position.|
|`positionId_`|`uint256`|the position id.|


### _closePosition


```solidity
function _closePosition(uint256 positionId_) private;
```

### partiallyClosePosition

Partially closes a position on a trade pair.


```solidity
function partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    syncFeesBefore
    updatePositionFees(positionId_)
    onlyValidAlteration(positionId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|owner of the position|
|`positionId_`|`uint256`|id of the position|
|`proportion_`|`uint256`|the proportion of the position that should be closed, should respect PERCENTAGE_MULTIPLIER|


### _partiallyClosePosition


```solidity
function _partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_) private;
```

### extendPosition

Extends position with margin and leverage. Leverage determins added loan. New margin and loan get added
to the existing position.


```solidity
function extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    verifyLeverage(addedLeverage_)
    syncFeesBefore
    updatePositionFees(positionId_)
    onlyValidAlteration(positionId_)
    checkAssetAmountLimitAfter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|Address of the position maker.|
|`positionId_`|`uint256`|ID of the position.|
|`addedMargin_`|`uint256`|Margin added to the position.|
|`addedLeverage_`|`uint256`|Denoted in LEVERAGE_MULTIPLIER.|


### _extendPosition

Should have received margin from TradeManager

*extendPosition simply "adds" a "new" position on top of the existing position. The two positions get merged.*


```solidity
function _extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_) private;
```

### extendPositionToLeverage

Extends position with loan to target leverage.


```solidity
function extendPositionToLeverage(address maker_, uint256 positionId_, uint256 targetLeverage_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    syncFeesBefore
    updatePositionFees(positionId_)
    onlyValidAlteration(positionId_)
    verifyLeverage(targetLeverage_)
    checkAssetAmountLimitAfter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|Address of the position maker.|
|`positionId_`|`uint256`|ID of the position.|
|`targetLeverage_`|`uint256`|Target leverage in respect to LEVERAGE_MULTIPLIER.|


### _extendPositionToLeverage


```solidity
function _extendPositionToLeverage(uint256 positionId_, uint256 targetLeverage_) private;
```

### removeMarginFromPosition

Removes margin from a position


```solidity
function removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    syncFeesBefore
    updatePositionFees(positionId_)
    onlyValidAlteration(positionId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|owner of the position|
|`positionId_`|`uint256`|id of the position|
|`removedMargin_`|`uint256`|the margin to be removed|


### _removeMarginFromPosition


```solidity
function _removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_) private;
```

### addMarginToPosition

Adds margin to a position


```solidity
function addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_)
    external
    onlyTradeManager
    verifyOwner(maker_, positionId_)
    syncFeesBefore
    updatePositionFees(positionId_)
    onlyValidAlteration(positionId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|owner of the position|
|`positionId_`|`uint256`|id of the position|
|`addedMargin_`|`uint256`|the margin to be added|


### _addMarginToPosition

*Should have received margin from TradeManager*


```solidity
function _addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_) private;
```

### liquidatePosition

Liquidates position and sends liquidation reward to msg.sender


```solidity
function liquidatePosition(address liquidator_, uint256 positionId_)
    external
    onlyTradeManager
    onlyLiquidatable(positionId_)
    syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidator_`|`address`|Address of the liquidator.|
|`positionId_`|`uint256`|position id|


### _liquidatePosition

liquidates a position


```solidity
function _liquidatePosition(address liquidator_, uint256 positionId_) private;
```

### syncPositionFees

Calculates outstanding borrow fees, transfers it to FeeManager and updates the fee integrals.
Funding fee stays at this TradePair as it is transfered virtually to the opposite positions ("long pays short").
All positions' margins make up the trade pair's balance of which the fee is transfered from.

*This function is public to allow possible fee syncing in periods without trades.*


```solidity
function syncPositionFees() public;
```

### _deletePosition

*Deletes position entries from storage.*


```solidity
function _deletePosition(uint256 positionId_) internal;
```

### _clearBuffer

Clears the fee buffer and returns the remaining margin, remaining buffer fee and request loss.


```solidity
function _clearBuffer(Position storage position_, bool isLiquidation_) private returns (uint256, uint256, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`position_`|`Position`|The position to clear the buffer for.|
|`isLiquidation_`|`bool`|Whether the buffer is cleared due to a liquidation. In this case, liquidatorReward is added to funding fee.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|remainingMargin the _margin of the position after clearing the buffer and paying fees|
|`<none>`|`uint256`|remainingBuffer remaining amount that needs to be transferred to the fee manager|
|`<none>`|`uint256`|requestLoss the amount of loss that needs to be requested from the liquidity pool|


### _updatePositionFees

updates the fee of this position. Necessary before changing its volume.


```solidity
function _updatePositionFees(uint256 positionId_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId_`|`uint256`|the id of the position|


### _registerProtocolPnL

Registers profit or loss at liquidity pool adapter


```solidity
function _registerProtocolPnL(int256 protocolPnL_) internal returns (uint256 payout);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`protocolPnL_`|`int256`|Profit or loss of protocol|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`payout`|`uint256`|Payout received from the liquidity pool adapter|


### _payOut

Pays out amount to receiver. If balance does not suffice, registers loss.


```solidity
function _payOut(address receiver_, uint256 amount_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver_`|`address`|Address of receiver.|
|`amount_`|`uint256`|Amount to pay out.|


### _payoutToMaker

*Deducts fees from the given amount and pays the rest to maker*


```solidity
function _payoutToMaker(address maker_, int256 amount_, uint256 positionId_) private;
```

### _deductAndTransferOpenFee

Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.

*The fee is exactly [userFee] of the resulting volume.*


```solidity
function _deductAndTransferOpenFee(address maker_, uint256 margin_, uint256 leverage_, uint256 positionId_)
    internal
    returns (uint256 marginAfterFee_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`||
|`margin_`|`uint256`|The margin of the position.|
|`leverage_`|`uint256`|The leverage of the position.|
|`positionId_`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marginAfterFee_`|`uint256`|The margin after fee deduction.|


### _deductAndTransferExtendToLeverageFee

Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.

*The fee is exactly [userFee] of the resulting volume.*


```solidity
function _deductAndTransferExtendToLeverageFee(
    address maker_,
    uint256 margin_,
    uint256 volume_,
    uint256 targetLeverage_,
    uint256 positionId_
) internal returns (uint256 marginAfterFee_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|The maker of the position.|
|`margin_`|`uint256`|The margin of the position.|
|`volume_`|`uint256`|The volume of the position.|
|`targetLeverage_`|`uint256`|The target leverage of the position.|
|`positionId_`|`uint256`|The id of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marginAfterFee_`|`uint256`|The margin after fee deduction.|


### _registerUserVolume

Registers user volume in USD.

*Trimms decimals from USD value.*


```solidity
function _registerUserVolume(address user_, uint256 volume_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User address.|
|`volume_`|`uint256`|Volume in collateral.|


### _depositOpenPositionFees

*Deposits the open position fees to the FeeManager.*


```solidity
function _depositOpenPositionFees(address user_, uint256 amount_, uint256 positionId_) private;
```

### _depositClosePositionFees

*Deposits the close position fees to the FeeManager.*


```solidity
function _depositClosePositionFees(address user_, uint256 amount_, uint256 positionId_) private;
```

### _depositBorrowFees

*Deposits the borrow fees to the FeeManager*


```solidity
function _depositBorrowFees(uint256 amount_) private;
```

### _resetApprove

*Sets the allowance on the collateral to 0.*


```solidity
function _resetApprove(address user_, uint256 amount_) private;
```

### getCurrentFundingFeeRates

Calculates the current funding fee rates


```solidity
function getCurrentFundingFeeRates() external view returns (int256 longFundingFeeRate, int256 shortFundingFeeRate);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`longFundingFeeRate`|`int256`|long funding fee rate|
|`shortFundingFeeRate`|`int256`|short funding fee rate|


### positionIdsOf

Returns positionIds of a user/maker


```solidity
function positionIdsOf(address maker_) external view returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker_`|`address`|Address of maker|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[]`|positionIds of maker|


### detailsOfPosition

returns the details of a position

*returns PositionDetails*


```solidity
function detailsOfPosition(uint256 positionId_) external view returns (PositionDetails memory);
```

### positionIsLiquidatable

Returns if a position is liquidatable


```solidity
function positionIsLiquidatable(uint256 positionId_) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId_`|`uint256`|the position id|


### positionIsShort

Returns if the position is short


```solidity
function positionIsShort(uint256 positionId_) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId_`|`uint256`|the position id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|isShort_ true if the position is short|


### getCurrentPrices

Returns the current min and max price


```solidity
function getCurrentPrices() external view returns (int256, int256);
```

### absoluteMaintenanceMargin

returns absolute maintenance margin

*Currently only the liquidator reward is the absolute maintenance margin, but this could change in the future*


```solidity
function absoluteMaintenanceMargin() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|absoluteMaintenanceMargin|


### setBorrowFeeRate

Sets the basis hourly borrow fee


```solidity
function setBorrowFeeRate(int256 borrowFeeRate_) public onlyOwner syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`borrowFeeRate_`|`int256`|should be in FEE_DECIMALS and per hour|


### setMaxFundingFeeRate

Sets the surplus fee


```solidity
function setMaxFundingFeeRate(int256 maxFundingFeeRate_) public onlyOwner syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxFundingFeeRate_`|`int256`|should be in FEE_DECIMALS and per hour|


### setMaxExcessRatio

Sets the max excess ratio at which the full funding fee is charged


```solidity
function setMaxExcessRatio(int256 maxExcessRatio_) public onlyOwner syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxExcessRatio_`|`int256`|should be denominated by FEE_MULTIPLER|


### setLiquidatorReward

Sets the liquidator reward


```solidity
function setLiquidatorReward(uint256 liquidatorReward_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidatorReward_`|`uint256`|in collateral decimals|


### setMinLeverage

Sets the minimum leverage


```solidity
function setMinLeverage(uint128 minLeverage_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minLeverage_`|`uint128`|in respect to LEVERAGE_MULTIPLIER|


### setMaxLeverage

Sets the maximum leverage


```solidity
function setMaxLeverage(uint128 maxLeverage_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxLeverage_`|`uint128`|in respect to LEVERAGE_MULTIPLIER|


### setMinMargin

Sets the minimum margin


```solidity
function setMinMargin(uint256 minMargin_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minMargin_`|`uint256`|in collateral decimals|


### setVolumeLimit

Sets the borrow limit


```solidity
function setVolumeLimit(uint256 volumeLimit_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`volumeLimit_`|`uint256`|in collateral decimals|


### setFeeBufferFactor

Sets the factor for the fee buffer. Denominated by BUFFER_MULTIPLIER


```solidity
function setFeeBufferFactor(int256 feeBufferFactor_) public onlyOwner syncFeesBefore;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeBufferFactor_`|`int256`|the factor for the fee buffer|


### setTotalAssetAmountLimit

Sets the limit for the total size of all positions


```solidity
function setTotalAssetAmountLimit(uint256 totalAssetAmountLimit_) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`totalAssetAmountLimit_`|`uint256`|limit for the total size of all positions|


### _getPayoutToMaker

Returns the payout to the maker of this position


```solidity
function _getPayoutToMaker(Position storage position_) private view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`position_`|`Position`|the position to calculate the payout for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the payout to the maker of this position|


### _getCurrentNetPnL

Returns the current price


```solidity
function _getCurrentNetPnL(Position storage position_) private view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`position_`|`Position`|the position to calculate the price for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|the current price|


### _getCurrentFeeIntegrals

*Returns borrow and funding fee intagral for long or short position*


```solidity
function _getCurrentFeeIntegrals(bool isShort_) internal view returns (int256, int256);
```

### _positionIsLiquidatable

Returns if a position is liquidatable


```solidity
function _positionIsLiquidatable(uint256 positionId_) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId_`|`uint256`|the position id|


### _getCurrentPrice

Returns current price depending on the direction of the trade and if is buying or selling


```solidity
function _getCurrentPrice(bool isShort_, bool isDecreasingPosition_) internal view returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isShort_`|`bool`|bool if the position is short|
|`isDecreasingPosition_`|`bool`|true on closing and decreasing the position. False on open and extending.|


### _onlyTradeManager

*Reverts when sender is not the TradeManager*


```solidity
function _onlyTradeManager() private view;
```

### _checkAssetAmountLimit

*Reverts when the total asset amount limit is reached by the sum of either all long or all short position*


```solidity
function _checkAssetAmountLimit() private view;
```

### _verifyAndUpdateLastAlterationBlock

Verifies that the position did not get altered this block and updates lastAlterationBlock of this position.

*Positions must not be altered at the same block. This reduces that risk of sandwich attacks.*


```solidity
function _verifyAndUpdateLastAlterationBlock(uint256 positionId_) private;
```

### _verifyPositionsValidity

Checks if the position is valid:
- The position must exists
- The position must not be liquidatable
- The position must not reach the volume limit


```solidity
function _verifyPositionsValidity(uint256 positionId_) private view;
```

### _verifyLeverage

*Reverts when leverage is out of bounds*


```solidity
function _verifyLeverage(uint256 leverage_) private view;
```

### _verifyOwner


```solidity
function _verifyOwner(address maker_, uint256 positionId_) private view;
```

### updatePositionFees

*updates the fee collected fees of this position. Necessary before changing its volume.*


```solidity
modifier updatePositionFees(uint256 positionId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId_`|`uint256`|the id of the position|


### syncFeesBefore

*collects fees by transferring them to the FeeManager*


```solidity
modifier syncFeesBefore();
```

### onlyLiquidatable

*reverts when position is not liquidatable*


```solidity
modifier onlyLiquidatable(uint256 positionId_);
```

### checkAssetAmountLimitAfter

*Reverts when aggregated size reaches asset amount limit after transaction*


```solidity
modifier checkAssetAmountLimitAfter();
```

### onlyValidAlteration

Checks if the alteration is valid. Alteration is valid, when:
- The position did not get altered at this block
- The position is not liquidatable after the alteration


```solidity
modifier onlyValidAlteration(uint256 positionId_);
```

### verifyLeverage

*verifies that leverage is in bounds*


```solidity
modifier verifyLeverage(uint256 leverage_);
```

### verifyOwner

*Verfies that sender is the owner of the position*


```solidity
modifier verifyOwner(address maker_, uint256 positionId_);
```

### onlyTradeManager

*Verfies that TradeManager sent the transactions*


```solidity
modifier onlyTradeManager();
```

## Enums
### PositionAlteration

```solidity
enum PositionAlteration {
    partialClose,
    partiallyCloseToLeverage,
    extend,
    extendToLeverage,
    removeMargin,
    addMargin
}
```

