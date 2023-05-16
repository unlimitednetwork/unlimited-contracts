# ITradeSignature
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeSignature.sol)


## Functions
### hash


```solidity
function hash(OpenPositionOrder calldata openPositionOrder) external view returns (bytes32);
```

### hash


```solidity
function hash(ClosePositionOrder calldata closePositionOrder) external view returns (bytes32);
```

### hash


```solidity
function hash(ClosePositionParams calldata closePositionParams) external view returns (bytes32);
```

### hashPartiallyClosePositionOrder


```solidity
function hashPartiallyClosePositionOrder(PartiallyClosePositionOrder calldata partiallyClosePositionOrder)
    external
    view
    returns (bytes32);
```

### hashPartiallyClosePositionParams


```solidity
function hashPartiallyClosePositionParams(PartiallyClosePositionParams calldata partiallyClosePositionParams)
    external
    view
    returns (bytes32);
```

### hashExtendPositionOrder


```solidity
function hashExtendPositionOrder(ExtendPositionOrder calldata extendPositionOrder) external view returns (bytes32);
```

### hashExtendPositionParams


```solidity
function hashExtendPositionParams(ExtendPositionParams calldata extendPositionParams) external view returns (bytes32);
```

### hashExtendPositionToLeverageOrder


```solidity
function hashExtendPositionToLeverageOrder(ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder)
    external
    view
    returns (bytes32);
```

### hashExtendPositionToLeverageParams


```solidity
function hashExtendPositionToLeverageParams(ExtendPositionToLeverageParams calldata extendPositionToLeverageParams)
    external
    view
    returns (bytes32);
```

### hashAddMarginToPositionOrder


```solidity
function hashAddMarginToPositionOrder(AddMarginToPositionOrder calldata addMarginToPositionOrder)
    external
    view
    returns (bytes32);
```

### hashAddMarginToPositionParams


```solidity
function hashAddMarginToPositionParams(AddMarginToPositionParams calldata addMarginToPositionParams)
    external
    view
    returns (bytes32);
```

### hashRemoveMarginFromPositionOrder


```solidity
function hashRemoveMarginFromPositionOrder(RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder)
    external
    view
    returns (bytes32);
```

### hashRemoveMarginFromPositionParams


```solidity
function hashRemoveMarginFromPositionParams(RemoveMarginFromPositionParams calldata removeMarginFromPositionParams)
    external
    view
    returns (bytes32);
```

