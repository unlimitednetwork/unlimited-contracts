# ITradeManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)


## Functions
### liquidatePosition


```solidity
function liquidatePosition(address tradePair, uint256 positionId, UpdateData[] calldata updateData) external;
```

### batchLiquidatePositions


```solidity
function batchLiquidatePositions(
    address[] calldata tradePairs,
    uint256[][] calldata positionIds,
    bool allowRevert,
    UpdateData[] calldata updateData
) external returns (bool[][] memory didLiquidate);
```

### detailsOfPosition


```solidity
function detailsOfPosition(address tradePair, uint256 positionId) external view returns (PositionDetails memory);
```

### positionIsLiquidatable


```solidity
function positionIsLiquidatable(address tradePair, uint256 positionId) external view returns (bool);
```

### canLiquidatePositions


```solidity
function canLiquidatePositions(address[] calldata tradePairs, uint256[][] calldata positionIds)
    external
    view
    returns (bool[][] memory canLiquidate);
```

### getCurrentFundingFeeRates


```solidity
function getCurrentFundingFeeRates(address tradePair) external view returns (int256, int256);
```

### totalAssetAmountLimitOfTradePair


```solidity
function totalAssetAmountLimitOfTradePair(address tradePair_) external view returns (uint256);
```

## Events
### PositionOpened

```solidity
event PositionOpened(address indexed tradePair, uint256 indexed id);
```

### PositionClosed

```solidity
event PositionClosed(address indexed tradePair, uint256 indexed id);
```

### PositionPartiallyClosed

```solidity
event PositionPartiallyClosed(address indexed tradePair, uint256 indexed id, uint256 proportion);
```

### PositionLiquidated

```solidity
event PositionLiquidated(address indexed tradePair, uint256 indexed id);
```

### PositionExtended

```solidity
event PositionExtended(address indexed tradePair, uint256 indexed id, uint256 addedMargin, uint256 addedLeverage);
```

### PositionExtendedToLeverage

```solidity
event PositionExtendedToLeverage(address indexed tradePair, uint256 indexed id, uint256 targetLeverage);
```

### MarginAddedToPosition

```solidity
event MarginAddedToPosition(address indexed tradePair, uint256 indexed id, uint256 addedMargin);
```

### MarginRemovedFromPosition

```solidity
event MarginRemovedFromPosition(address indexed tradePair, uint256 indexed id, uint256 removedMargin);
```

