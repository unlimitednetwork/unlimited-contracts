# TradeSignature
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/trade-manager/TradeSignature.sol)

**Inherits:**
EIP712, [ITradeSignature](/src/interfaces/ITradeSignature.sol/contract.ITradeSignature.md)

This contract is used to verify signatures for trade orders

*This contract is based on the EIP712 standard*


## State Variables
### OPEN_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant OPEN_POSITION_ORDER_TYPEHASH = keccak256(
    "OpenPositionOrder(OpenPositionParams params,Constraints constraints,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)OpenPositionParams(address tradePair,uint256 margin,uint256 leverage,bool isShort,address referrer,address whitelabelAddress)"
);
```


### OPEN_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant OPEN_POSITION_PARAMS_TYPEHASH = keccak256(
    "OpenPositionParams(address tradePair,uint256 margin,uint256 leverage,bool isShort,address referrer,address whitelabelAddress)"
);
```


### CLOSE_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant CLOSE_POSITION_ORDER_TYPEHASH = keccak256(
    "ClosePositionOrder(ClosePositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)ClosePositionParams(address tradePair,uint256 positionId)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)"
);
```


### CLOSE_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant CLOSE_POSITION_PARAMS_TYPEHASH =
    keccak256("ClosePositionParams(address tradePair,uint256 positionId)");
```


### PARTIALLY_CLOSE_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant PARTIALLY_CLOSE_POSITION_ORDER_TYPEHASH = keccak256(
    "PartiallyClosePositionOrder(PartiallyClosePositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)PartiallyClosePositionParams(address tradePair,uint256 positionId,uint256 proportion)"
);
```


### PARTIALLY_CLOSE_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant PARTIALLY_CLOSE_POSITION_PARAMS_TYPEHASH =
    keccak256("PartiallyClosePositionParams(address tradePair,uint256 positionId,uint256 proportion)");
```


### EXTEND_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant EXTEND_POSITION_ORDER_TYPEHASH = keccak256(
    "ExtendPositionOrder(ExtendPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)ExtendPositionParams(address tradePair,uint256 positionId,uint256 addedMargin,uint256 addedLeverage)"
);
```


### EXTEND_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant EXTEND_POSITION_PARAMS_TYPEHASH =
    keccak256("ExtendPositionParams(address tradePair,uint256 positionId,uint256 addedMargin,uint256 addedLeverage)");
```


### EXTEND_POSITION_TO_LEVERAGE_ORDER_TYPEHASH

```solidity
bytes32 public constant EXTEND_POSITION_TO_LEVERAGE_ORDER_TYPEHASH = keccak256(
    "ExtendPositionToLeverageOrder(ExtendPositionToLeverageParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)ExtendPositionToLeverageParams(address tradePair,uint256 positionId,uint256 targetLeverage)"
);
```


### EXTEND_POSITION_TO_LEVERAGE_PARAMS_TYPEHASH

```solidity
bytes32 public constant EXTEND_POSITION_TO_LEVERAGE_PARAMS_TYPEHASH =
    keccak256("ExtendPositionToLeverageParams(address tradePair,uint256 positionId,uint256 targetLeverage)");
```


### REMOVE_MARGIN_FROM_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant REMOVE_MARGIN_FROM_POSITION_ORDER_TYPEHASH = keccak256(
    "RemoveMarginFromPositionOrder(RemoveMarginFromPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)RemoveMarginFromPositionParams(address tradePair,uint256 positionId,uint256 removedMargin)"
);
```


### REMOVE_MARGIN_FROM_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant REMOVE_MARGIN_FROM_POSITION_PARAMS_TYPEHASH =
    keccak256("RemoveMarginFromPositionParams(address tradePair,uint256 positionId,uint256 removedMargin)");
```


### ADD_MARGIN_TO_POSITION_ORDER_TYPEHASH

```solidity
bytes32 public constant ADD_MARGIN_TO_POSITION_ORDER_TYPEHASH = keccak256(
    "AddMarginToPositionOrder(AddMarginToPositionParams params,Constraints constraints,bytes32 signatureHash,uint256 salt)AddMarginToPositionParams(address tradePair,uint256 positionId,uint256 addedMargin)Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)"
);
```


### ADD_MARGIN_TO_POSITION_PARAMS_TYPEHASH

```solidity
bytes32 public constant ADD_MARGIN_TO_POSITION_PARAMS_TYPEHASH =
    keccak256("AddMarginToPositionParams(address tradePair,uint256 positionId,uint256 addedMargin)");
```


### CONSTRAINTS_TYPEHASH

```solidity
bytes32 public constant CONSTRAINTS_TYPEHASH =
    keccak256("Constraints(uint256 deadline,int256 minPrice,int256 maxPrice)");
```


### isProcessedSignature

```solidity
mapping(bytes => bool) public isProcessedSignature;
```


## Functions
### constructor

Constructs the TradeSignature Contract

*Constructs the EIP712 Contract*


```solidity
constructor() EIP712("UnlimitedLeverage", "1");
```

### _processSignature


```solidity
function _processSignature(OpenPositionOrder calldata openPositionOrder_, address signer_, bytes calldata signature_)
    internal;
```

### _processSignature


```solidity
function _processSignature(ClosePositionOrder calldata closePositionOrder_, address signer_, bytes calldata signature_)
    internal;
```

### _processSignature


```solidity
function _processSignature(
    PartiallyClosePositionOrder calldata partiallyClosePositionOrder_,
    address signer_,
    bytes calldata signature_
) internal;
```

### _processSignatureExtendPosition


```solidity
function _processSignatureExtendPosition(
    ExtendPositionOrder calldata extendPositionOrder_,
    address signer_,
    bytes calldata signature_
) internal;
```

### _processSignatureExtendPositionToLeverage


```solidity
function _processSignatureExtendPositionToLeverage(
    ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder_,
    address signer_,
    bytes calldata signature_
) internal;
```

### _processSignatureRemoveMarginFromPosition


```solidity
function _processSignatureRemoveMarginFromPosition(
    RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder_,
    address signer_,
    bytes calldata signature_
) internal;
```

### _processSignatureAddMarginToPosition


```solidity
function _processSignatureAddMarginToPosition(
    AddMarginToPositionOrder calldata addMarginToPositionOrder_,
    address signer_,
    bytes calldata signature_
) internal;
```

### _verifySignature


```solidity
function _verifySignature(bytes32 hash_, address signer_, bytes calldata signature_) private view;
```

### _registerProcessedSignature


```solidity
function _registerProcessedSignature(bytes calldata signature_) private;
```

### _onlyNonProcessedSignature


```solidity
function _onlyNonProcessedSignature(bytes calldata signature_) private view;
```

### hash


```solidity
function hash(OpenPositionOrder calldata openPositionOrder) public view returns (bytes32);
```

### hash


```solidity
function hash(OpenPositionParams calldata openPositionParams) internal pure returns (bytes32);
```

### hash


```solidity
function hash(ClosePositionOrder calldata closePositionOrder) public view returns (bytes32);
```

### hash


```solidity
function hash(ClosePositionParams calldata closePositionParams) public pure returns (bytes32);
```

### hashPartiallyClosePositionOrder


```solidity
function hashPartiallyClosePositionOrder(PartiallyClosePositionOrder calldata partiallyClosePositionOrder)
    public
    view
    returns (bytes32);
```

### hashPartiallyClosePositionParams


```solidity
function hashPartiallyClosePositionParams(PartiallyClosePositionParams calldata partiallyClosePositionParams)
    public
    pure
    returns (bytes32);
```

### hashExtendPositionOrder


```solidity
function hashExtendPositionOrder(ExtendPositionOrder calldata extendPositionOrder) public view returns (bytes32);
```

### hashExtendPositionParams


```solidity
function hashExtendPositionParams(ExtendPositionParams calldata extendPositionParams) public pure returns (bytes32);
```

### hashExtendPositionToLeverageOrder


```solidity
function hashExtendPositionToLeverageOrder(ExtendPositionToLeverageOrder calldata extendPositionToLeverageOrder)
    public
    view
    returns (bytes32);
```

### hashExtendPositionToLeverageParams


```solidity
function hashExtendPositionToLeverageParams(ExtendPositionToLeverageParams calldata extendPositionToLeverageParams)
    public
    pure
    returns (bytes32);
```

### hashAddMarginToPositionOrder


```solidity
function hashAddMarginToPositionOrder(AddMarginToPositionOrder calldata addMarginToPositionOrder)
    public
    view
    returns (bytes32);
```

### hashAddMarginToPositionParams


```solidity
function hashAddMarginToPositionParams(AddMarginToPositionParams calldata addMarginToPositionParams)
    public
    pure
    returns (bytes32);
```

### hashRemoveMarginFromPositionOrder


```solidity
function hashRemoveMarginFromPositionOrder(RemoveMarginFromPositionOrder calldata removeMarginFromPositionOrder)
    public
    view
    returns (bytes32);
```

### hashRemoveMarginFromPositionParams


```solidity
function hashRemoveMarginFromPositionParams(RemoveMarginFromPositionParams calldata removeMarginFromPositionParams)
    public
    pure
    returns (bytes32);
```

### hash


```solidity
function hash(Constraints calldata constraints) internal pure returns (bytes32);
```

