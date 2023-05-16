# TradeManagerOrders
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/trade-manager/TradeManagerOrders.sol)

**Inherits:**
[ITradeManagerOrders](/src/interfaces/ITradeManagerOrders.sol/contract.ITradeManagerOrders.md), [TradeSignature](/src/trade-manager/TradeSignature.sol/contract.TradeSignature.md), [TradeManager](/src/trade-manager/TradeManager.sol/contract.TradeManager.md)

Exposes Functions to open, alter and close positions via signed orders.

*This contract is called by the Unlimited backend. This allows for an order book.*


## State Variables
### sigHashToTradeId

```solidity
mapping(bytes32 => TradeId) public sigHashToTradeId;
```


## Functions
### constructor

Constructs the TradeManager contract.


```solidity
constructor(IController controller_, IUserManager userManager_)
    TradeManager(controller_, userManager_)
    TradeSignature;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`controller_`|`IController`|The address of the controller.|
|`userManager_`|`IUserManager`|The address of the user manager.|


### openPositionViaSignature

Opens a position with a signature


```solidity
function openPositionViaSignature(
    OpenPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`OpenPositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### closePositionViaSignature

Closes a position with a signature


```solidity
function closePositionViaSignature(
    ClosePositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ClosePositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### partiallyClosePositionViaSignature

Partially closes a position with a signature


```solidity
function partiallyClosePositionViaSignature(
    PartiallyClosePositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`PartiallyClosePositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### extendPositionViaSignature

Extends a position with a signature


```solidity
function extendPositionViaSignature(
    ExtendPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ExtendPositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### extendPositionToLeverageViaSignature

Partially extends a position to leverage with a signature


```solidity
function extendPositionToLeverageViaSignature(
    ExtendPositionToLeverageOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ExtendPositionToLeverageOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### addMarginToPositionViaSignature

Adds margin to a position with a signature


```solidity
function addMarginToPositionViaSignature(
    AddMarginToPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`AddMarginToPositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### removeMarginFromPositionViaSignature

Removes margin from a position with a signature


```solidity
function removeMarginFromPositionViaSignature(
    RemoveMarginFromPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external onlyOrderExecutor onlyActiveTradePair(order_.params.tradePair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`RemoveMarginFromPositionOrder`|Order struct|
|`updateData_`|`UpdateData[]`||
|`maker_`|`address`|address of the maker|
|`signature_`|`bytes`|signature of order_ by maker_|


### _injectPositionIdToCloseOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToCloseOrder(ClosePositionOrder calldata order_)
    internal
    view
    returns (ClosePositionOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ClosePositionOrder`|Close Position Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`ClosePositionOrder`|with positionId injected|


### _injectPositionIdToPartiallyCloseOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToPartiallyCloseOrder(PartiallyClosePositionOrder calldata order_)
    internal
    view
    returns (PartiallyClosePositionOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`PartiallyClosePositionOrder`|Partially Close Position Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`PartiallyClosePositionOrder`|with positionId injected|


### _injectPositionIdToExtendOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToExtendOrder(ExtendPositionOrder calldata order_)
    internal
    view
    returns (ExtendPositionOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ExtendPositionOrder`|Extend Position Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`ExtendPositionOrder`|with positionId injected|


### _injectPositionIdToExtendToLeverageOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToExtendToLeverageOrder(ExtendPositionToLeverageOrder calldata order_)
    internal
    view
    returns (ExtendPositionToLeverageOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`ExtendPositionToLeverageOrder`|Extend Position To Leverage Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`ExtendPositionToLeverageOrder`|with positionId injected|


### _injectPositionIdToAddMarginOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToAddMarginOrder(AddMarginToPositionOrder calldata order_)
    internal
    view
    returns (AddMarginToPositionOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`AddMarginToPositionOrder`|Add Margin Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`AddMarginToPositionOrder`|with positionId injected|


### _injectPositionIdToRemoveMarginOrder

Maybe Injects the positionId to the order. Injects positionId when order has a signatureHash

*Retrieves the positionId from sigHashToPositionId via the order's signatureHash.*


```solidity
function _injectPositionIdToRemoveMarginOrder(RemoveMarginFromPositionOrder calldata order_)
    internal
    view
    returns (RemoveMarginFromPositionOrder memory newOrder);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order_`|`RemoveMarginFromPositionOrder`|Remove Margin Order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newOrder`|`RemoveMarginFromPositionOrder`|with positionId injected|


### _transferOrderReward

transfers the order reward from maker to executor


```solidity
function _transferOrderReward(address tradePair_, address from_, address to_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|address of the trade pair (collateral is read from tradePair)|
|`from_`|`address`|address of the maker|
|`to_`|`address`|address of the executor|


### _verifyOrderExecutor


```solidity
function _verifyOrderExecutor() internal view;
```

### onlyOrderExecutor


```solidity
modifier onlyOrderExecutor();
```

