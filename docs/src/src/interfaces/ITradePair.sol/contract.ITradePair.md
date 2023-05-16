# ITradePair
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradePair.sol)


## Functions
### name


```solidity
function name() external view returns (string memory);
```

### collateral


```solidity
function collateral() external view returns (IERC20);
```

### positionIdsOf


```solidity
function positionIdsOf(address maker) external view returns (uint256[] memory);
```

### detailsOfPosition


```solidity
function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);
```

### priceFeedAdapter


```solidity
function priceFeedAdapter() external view returns (IPriceFeedAdapter);
```

### liquidityPoolAdapter


```solidity
function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);
```

### userManager


```solidity
function userManager() external view returns (IUserManager);
```

### feeManager


```solidity
function feeManager() external view returns (IFeeManager);
```

### tradeManager


```solidity
function tradeManager() external view returns (ITradeManager);
```

### positionIsLiquidatable


```solidity
function positionIsLiquidatable(uint256 positionId) external view returns (bool);
```

### getCurrentFundingFeeRates


```solidity
function getCurrentFundingFeeRates() external view returns (int256, int256);
```

### getCurrentPrices


```solidity
function getCurrentPrices() external view returns (int256, int256);
```

### positionIsShort


```solidity
function positionIsShort(uint256) external view returns (bool);
```

### feeIntegral


```solidity
function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);
```

### liquidatorReward


```solidity
function liquidatorReward() external view returns (uint256);
```

### maxLeverage


```solidity
function maxLeverage() external view returns (uint128);
```

### minLeverage


```solidity
function minLeverage() external view returns (uint128);
```

### minMargin


```solidity
function minMargin() external view returns (uint256);
```

### volumeLimit


```solidity
function volumeLimit() external view returns (uint256);
```

### totalAssetAmountLimit


```solidity
function totalAssetAmountLimit() external view returns (uint256);
```

### positionStats


```solidity
function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
```

### overcollectedFees


```solidity
function overcollectedFees() external view returns (int256);
```

### feeBuffer


```solidity
function feeBuffer() external view returns (int256, int256);
```

### positionIdToWhiteLabel


```solidity
function positionIdToWhiteLabel(uint256) external view returns (address);
```

### openPosition


```solidity
function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
    external
    returns (uint256 positionId);
```

### closePosition


```solidity
function closePosition(address maker, uint256 positionId) external;
```

### addMarginToPosition


```solidity
function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;
```

### removeMarginFromPosition


```solidity
function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;
```

### partiallyClosePosition


```solidity
function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;
```

### extendPosition


```solidity
function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;
```

### extendPositionToLeverage


```solidity
function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;
```

### liquidatePosition


```solidity
function liquidatePosition(address liquidator, uint256 positionId) external;
```

### syncPositionFees


```solidity
function syncPositionFees() external;
```

### initialize


```solidity
function initialize(
    string memory name,
    IERC20Metadata collateral,
    uint256 assetDecimals,
    IPriceFeedAdapter priceFeedAdapter,
    ILiquidityPoolAdapter liquidityPoolAdapter
) external;
```

### setBorrowFeeRate


```solidity
function setBorrowFeeRate(int256 borrowFeeRate) external;
```

### setMaxFundingFeeRate


```solidity
function setMaxFundingFeeRate(int256 fee) external;
```

### setMaxExcessRatio


```solidity
function setMaxExcessRatio(int256 maxExcessRatio) external;
```

### setLiquidatorReward


```solidity
function setLiquidatorReward(uint256 liquidatorReward) external;
```

### setMinLeverage


```solidity
function setMinLeverage(uint128 minLeverage) external;
```

### setMaxLeverage


```solidity
function setMaxLeverage(uint128 maxLeverage) external;
```

### setMinMargin


```solidity
function setMinMargin(uint256 minMargin) external;
```

### setVolumeLimit


```solidity
function setVolumeLimit(uint256 volumeLimit) external;
```

### setFeeBufferFactor


```solidity
function setFeeBufferFactor(int256 feeBufferAmount) external;
```

### setTotalAssetAmountLimit


```solidity
function setTotalAssetAmountLimit(uint256 totalAssetAmountLimit) external;
```

## Events
### OpenedPosition

```solidity
event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);
```

### ClosedPosition

```solidity
event ClosedPosition(uint256 id, int256 closePrice);
```

### LiquidatedPosition

```solidity
event LiquidatedPosition(uint256 indexed id, address indexed liquidator);
```

### AlteredPosition

```solidity
event AlteredPosition(
    PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
);
```

### FeeOvercollected

```solidity
event FeeOvercollected(int256 amount);
```

### PayedOutCollateral

```solidity
event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);
```

### LiquidityGapWarning

```solidity
event LiquidityGapWarning(uint256 amount);
```

### RealizedPnL

```solidity
event RealizedPnL(address indexed maker, uint256 indexed positionId, int256 realizedPnL);
```

### UpdatedFeeIntegrals

```solidity
event UpdatedFeeIntegrals(int256 borrowFeeIntegral, int256 longFundingFeeIntegral, int256 shortFundingFeeIntegral);
```

## Enums
### PositionAlterationType

```solidity
enum PositionAlterationType {
    partiallyClose,
    extend,
    extendToLeverage,
    removeMargin,
    addMargin
}
```

