# ITradeManagerOrders
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManagerOrders.sol)

**Inherits:**
[ITradeManager](/src/interfaces/ITradeManager.sol/contract.ITradeManager.md), [ITradeSignature](/src/interfaces/ITradeSignature.sol/contract.ITradeSignature.md)


## Functions
### openPositionViaSignature


```solidity
function openPositionViaSignature(
    OpenPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external returns (uint256 positionId);
```

### closePositionViaSignature


```solidity
function closePositionViaSignature(
    ClosePositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

### partiallyClosePositionViaSignature


```solidity
function partiallyClosePositionViaSignature(
    PartiallyClosePositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

### removeMarginFromPositionViaSignature


```solidity
function removeMarginFromPositionViaSignature(
    RemoveMarginFromPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

### addMarginToPositionViaSignature


```solidity
function addMarginToPositionViaSignature(
    AddMarginToPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

### extendPositionViaSignature


```solidity
function extendPositionViaSignature(
    ExtendPositionOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

### extendPositionToLeverageViaSignature


```solidity
function extendPositionToLeverageViaSignature(
    ExtendPositionToLeverageOrder calldata order_,
    UpdateData[] calldata updateData_,
    address maker_,
    bytes calldata signature_
) external;
```

## Events
### OpenedPositionViaSignature

```solidity
event OpenedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### ClosedPositionViaSignature

```solidity
event ClosedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### PartiallyClosedPositionViaSignature

```solidity
event PartiallyClosedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### ExtendedPositionViaSignature

```solidity
event ExtendedPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### ExtendedPositionToLeverageViaSignature

```solidity
event ExtendedPositionToLeverageViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### AddedMarginToPositionViaSignature

```solidity
event AddedMarginToPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### RemovedMarginFromPositionViaSignature

```solidity
event RemovedMarginFromPositionViaSignature(address indexed tradePair, uint256 indexed id, bytes indexed signature);
```

### OrderRewardTransfered

```solidity
event OrderRewardTransfered(address indexed collateral, address indexed from, address indexed to, uint256 orderReward);
```

