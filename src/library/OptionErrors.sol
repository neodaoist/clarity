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

    /// @dev Also used in views and Exercise, Net Off, and Redeem features
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

    error InsufficientLongBalance(uint256 optionTokenId, uint256 optionBalance);

    error InsufficientShortBalance(uint256 optionTokenId, uint256 optionBalance);

    ///////// Views

    error InvalidPositionTokenType(uint256 tokenId);
}
