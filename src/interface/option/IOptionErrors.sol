// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOptionErrors {
    /////////

    ///////// Views

    /// @dev Also used in Net Off, Exercise, and Redeem
    error OptionDoesNotExist(uint256 optionTokenId);

    error InvalidTokenType(uint256 tokenId);

    error TempInvalidTokenType();

    ///////// Write

    error AssetsIdentical(address baseAsset, address quoteAsset);

    error AssetDecimalsOutOfRange(address asset, uint8 decimals);

    error ExerciseWindowMispaired();

    error ExerciseWindowZeroTime(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseWindowMisordered(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseWindowExpiryPast(uint32 expiryTimestamp);

    error ExerciseWindowExpiryTooFarInFuture(uint32 expiryTimestamp);

    error StrikePriceTooSmall(uint256 strikePrice);

    error StrikePriceTooLarge(uint256 strikePrice);

    error OptionExpired(uint256 optionTokenId, uint32 expiryTimestamp);

    error OptionAlreadyExists(uint256 optionTokenId);

    error WriteAmountZero();

    error WriteAmountTooSmall();

    error WriteAmountTooLarge(uint64 optionAmount);

    error BatchWriteArrayLengthZero();

    error BatchWriteArrayLengthMismatch();

    ///////// Transfer

    error CanOnlyTransferLongOrShort();

    error CanOnlyTransferShortIfUnassigned();

    ///////// Net Off

    error NetOffAmountZero();

    /// @dev Also used in ERC20Factory and ClarityWrappedLong
    error InsufficientLongBalance(uint256 optionTokenId, uint256 optionBalance);

    /// @dev Also used in ERC20Factory and ClarityWrappedShort
    error InsufficientShortBalance(uint256 shortTokenId, uint256 shortBalance);

    ///////// Exercise

    error ExerciseAmountZero();

    error OptionTokenIdNotLong(uint256 optionTokenId);

    error OptionNotWithinExerciseWindow(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseAmountExceedsLongBalance(uint256 optionAmount, uint256 optionBalance);

    ///////// Redeem

    error ShortBalanceZero(uint256 shortTokenId);

    error EarlyRedemptionOnlyIfFullyAssigned();

    error CanOnlyRedeemShort(uint256 tokenId); // TODO reframe to standardize with other
        // errors

    ///////// Adapter

    error WrappedLongAlreadyDeployed(uint256 optionTokenId);

    error WrappedShortAlreadyDeployed(uint256 shortTokenId);

    error TokenIdNotShort(uint256 tokenId); // TODO consider using elsewhere, do one for
        // other types also

    error ShortAlreadyAssigned(uint256 shortTokenId);

    error WrapAmountZero();

    error UnwrapAmountZero();

    error InsufficientWrappedBalance(uint256 optionTokenId, uint256 wrappedBalance);
}
