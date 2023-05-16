# UserManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/user-manager/UserManager.sol)

**Inherits:**
[IUserManager](/src/interfaces/IUserManager.sol/contract.IUserManager.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md), Initializable


## State Variables
### MAX_FEE_SIZE
Maximum fee size that can be set is 1%. 0.01% - 1%


```solidity
uint256 private constant MAX_FEE_SIZE = 1_00;
```


### DAYS_IN_WORD
Defines number of days in a `DailyVolumes` struct.


```solidity
uint256 public constant DAYS_IN_WORD = 6;
```


### NO_REFERRER_ADDRESS
This address is used when the user has no referrer


```solidity
address private constant NO_REFERRER_ADDRESS = address(type(uint160).max);
```


### controller
Controller contract.


```solidity
IController public immutable controller;
```


### tradeManager
TradeManager contract.


```solidity
ITradeManager public immutable tradeManager;
```


### userDailyVolumes
Contains user traded volume for each day.


```solidity
mapping(address => mapping(uint256 => DailyVolumes)) public userDailyVolumes;
```


### manualUserTiers
Defines mannualy set tier for a user.


```solidity
mapping(address => ManualUserTier) public manualUserTiers;
```


### _userReferrer
User referrer.


```solidity
mapping(address => address) private _userReferrer;
```


### feeSizes
Defines fee size for volume.


```solidity
FeeSizes public feeSizes;
```


### feeVolumes
Defines volume for each tier.


```solidity
FeeVolumes public feeVolumes;
```


## Functions
### constructor

Constructs the UserManager contract.


```solidity
constructor(IUnlimitedOwner unlimitedOwner_, IController controller_, ITradeManager tradeManager_)
    UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|Unlimited owner contract.|
|`controller_`|`IController`|Controller contract.|
|`tradeManager_`|`ITradeManager`||


### initialize

Initializes the data.


```solidity
function initialize(uint8[7] memory feeSizes_, uint32[6] memory feeVolumes_) public onlyOwner initializer;
```

### getUserFee

Gets users open and close position fee.

*The fee is based on users last 30 day volume.*


```solidity
function getUserFee(address user_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|fee size in BPS|


### getUserTier

Gets users fee tier.

*The fee is the bigger tier of the volume tier or manualy set one.*


```solidity
function getUserTier(address user_) public view returns (Tier userTier);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`userTier`|`Tier`|fee tier of the user|


### getUserVolumeTier

Gets users fee tier based on volume.

*The fee is based on users last 30 day volume.*


```solidity
function getUserVolumeTier(address user_) public view returns (Tier);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Tier`|Tier fee tier of the user|


### getUserManualTier

Gets users fee manual tier.


```solidity
function getUserManualTier(address user_) public view returns (Tier);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Tier`|Tier fee tier of the user|


### getUser30DaysVolume

Gets users last 30 days traded volume.


```solidity
function getUser30DaysVolume(address user_) public view returns (uint256 user30dayVolume);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`user30dayVolume`|`uint256`|users last 30 days volume|


### getUserReferrer

Gets the referrer of the user.


```solidity
function getUserReferrer(address user_) external view returns (address referrer);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`referrer`|`address`|adress of the refererrer|


### setUserReferrer

Sets the referrer of the user. Referrer can only be set once. Of referrer is null, the user will be set
to NO_REFERRER_ADDRESS.


```solidity
function setUserReferrer(address user_, address referrer_) external onlyTradeManager;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|address of the user|
|`referrer_`|`address`|address of the referrer|


### addUserVolume

Adds user volume to total daily traded when new position is open.

*
Requirements:
- The caller must be a valid trade pair*


```solidity
function addUserVolume(address user_, uint40 volume_) external onlyValidTradePair(msg.sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|user address|
|`volume_`|`uint40`|volume to add|


### setUserManualTier

Sets users manual tier including valid time.

*
Requirements:
- The caller must be a controller*


```solidity
function setUserManualTier(address user, Tier tier, uint32 validUntil) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|user address|
|`tier`|`Tier`|tier to set|
|`validUntil`|`uint32`|unix time when the manual tier expires|


### setFeeSizes

Sets fee sizes for a tier.

*
`feeIndexes` start with 0 as the base fee and increase by 1 for each tier.
Requirements:
- The caller must be a controller
- `feeIndexes` and `feeSizes` must be of same length*


```solidity
function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeIndexes`|`uint256[]`|Index of feeSizes to update|
|`feeSizes_`|`uint8[]`|Fee sizes in BPS|


### setFeeVolumes

Sets minimum volume for a fee tier.

*
`feeIndexes` start with 1 as the tier one and increment by one.
Requirements:
- The caller must be a controller
- `feeIndexes` and `feeVolumes_` must be of same length*


```solidity
function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeIndexes`|`uint256[]`|Index of feeVolumes_ to update|
|`feeVolumes_`|`uint32[]`|Fee volume for an index|


### _addUserDailyVolume

*Adds volume to users daily volume.*


```solidity
function _addUserDailyVolume(address user, uint256 index, uint256 position, uint40 volume) private;
```

### _getUserDailyVolume

*Returns users daily volume.*


```solidity
function _getUserDailyVolume(address user, uint256 index, uint256 position) private view returns (uint256);
```

### _getTodaysIndexAndPosition

*Returns todays index and position.*


```solidity
function _getTodaysIndexAndPosition() private view returns (uint256, uint256);
```

### _getPastIndexAndPosition

*Returns index and position for a point of time that is "saysInThePast" days away from now.*


```solidity
function _getPastIndexAndPosition(uint256 daysInThePast) private view returns (uint256, uint256);
```

### _getTimeIndexAndPosition

*Gets index and position for a point of time.*


```solidity
function _getTimeIndexAndPosition(uint256 timestamp) private pure returns (uint256 index, uint256 position);
```

### _setFeeSize

*Sets fee size for an index.*


```solidity
function _setFeeSize(uint256 feeIndex, uint8 feeSize) private;
```

### _setFeeVolume

*Sets fee volume for an index.*


```solidity
function _setFeeVolume(uint256 feeIndex, uint32 feeVolume) private;
```

### _onlyValidTradePair

*Reverts if TradePair is not valid.*


```solidity
function _onlyValidTradePair(address tradePair) private view;
```

### _onlyTradeManager

*Reverts when sender is not the TradeManager*


```solidity
function _onlyTradeManager() private view;
```

### onlyValidTradePair

*Reverts if TradePair is not valid.*


```solidity
modifier onlyValidTradePair(address tradePair);
```

### onlyTradeManager

*Verifies that TradeManager sent the transaction*


```solidity
modifier onlyTradeManager();
```

