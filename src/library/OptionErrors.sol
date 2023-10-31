// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library OptionErrors {
    /////////

    ///////// Write

    error AssetsIdentical(address baseAsset, address quoteAsset);

    error AssetDecimalsOutOfRange(address asset, uint8 decimals);

    error ExerciseWindowMispaired();

    error ExerciseWindowZeroTime(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseWindowMisordered(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseWindowExpiryPast(uint32 expiryTimestamp);

    error StrikePriceTooLarge(uint256 strikePrice);

    /// @dev Also used in Exercise, Net Off, Redeem, and views
    error OptionDoesNotExist(uint256 optionTokenId);

    error OptionExpired(uint256 optionTokenId, uint32 expiryTimestamp);

    error WriteAmountZero();

    error BatchWriteArrayLengthZero();

    error BatchWriteArrayLengthMismatch();

    ///////// Exercise

    error ExerciseAmountZero();

    error OptionTokenIdNotLong(uint256 optionTokenId);

    error OptionNotWithinExerciseWindow(uint32 exerciseTimestamp, uint32 expiryTimestamp);

    error ExerciseAmountExceedsLongBalance(uint256 optionAmount, uint256 optionBalance);

    ///////// Net Off

    /// @dev Also used in ERC20Factory and ClarityWrappedLong
    error InsufficientLongBalance(uint256 optionTokenId, uint256 optionBalance);

    /// @dev Also used in ERC20Factory and ClarityWrappedShort
    error InsufficientShortBalance(uint256 shortTokenId, uint256 shortBalance);

    ///////// Redeem

    error NoAssetsToRedeem();

    ///////// Views

    error InvalidPositionTokenType(uint256 tokenId);

    ///////// Adapter

    error WrappedLongAlreadyDeployed(uint256 optionTokenId);

    error WrapAmountZero();

    error UnwrapAmountZero();

    error InsufficientWrappedBalance(uint256 optionTokenId, uint256 wrappedBalance);
}
