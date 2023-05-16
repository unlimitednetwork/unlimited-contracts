# IFeeManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IFeeManager.sol)


## Functions
### depositOpenFees


```solidity
function depositOpenFees(address user, address asset, uint256 amount, address whitelabelAddress) external;
```

### depositCloseFees


```solidity
function depositCloseFees(address user, address asset, uint256 amount, address whitelabelAddress) external;
```

### depositBorrowFees


```solidity
function depositBorrowFees(address asset, uint256 amount) external;
```

### calculateUserOpenFeeAmount


```solidity
function calculateUserOpenFeeAmount(address user, uint256 amount) external view returns (uint256);
```

### calculateUserOpenFeeAmount


```solidity
function calculateUserOpenFeeAmount(address user, uint256 amount, uint256 leverage) external view returns (uint256);
```

### calculateUserExtendToLeverageFeeAmount


```solidity
function calculateUserExtendToLeverageFeeAmount(address user, uint256 margin, uint256 volume, uint256 targetLeverage)
    external
    view
    returns (uint256);
```

### calculateUserCloseFeeAmount


```solidity
function calculateUserCloseFeeAmount(address user, uint256 amount) external view returns (uint256);
```

## Events
### ReferrerFeesPaid

```solidity
event ReferrerFeesPaid(address indexed referrer, address indexed asset, uint256 amount);
```

### WhiteLabelFeesPaid

```solidity
event WhiteLabelFeesPaid(address indexed whitelabel, address indexed asset, uint256 amount);
```

### UpdatedReferralFee

```solidity
event UpdatedReferralFee(uint256 newReferrerFee);
```

### UpdatedStakersFeeAddress

```solidity
event UpdatedStakersFeeAddress(address stakersFeeAddress);
```

### UpdatedDevFeeAddress

```solidity
event UpdatedDevFeeAddress(address devFeeAddress);
```

### UpdatedInsuranceFundFeeAddress

```solidity
event UpdatedInsuranceFundFeeAddress(address insuranceFundFeeAddress);
```

### SetWhitelabelFee

```solidity
event SetWhitelabelFee(address indexed whitelabelAddress, uint256 feeSize);
```

### SetCustomReferralFee

```solidity
event SetCustomReferralFee(address indexed referrer, uint256 feeSize);
```

### SpreadFees

```solidity
event SpreadFees(
    address asset,
    uint256 stakersFeeAmount,
    uint256 devFeeAmount,
    uint256 insuranceFundFeeAmount,
    uint256 liquidityPoolFeeAmount
);
```

