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

    error OptionDoesNotExist(uint256 optionTokenId);

    error OptionExpired(uint256 optionTokenId, uint32 expiryTimestamp);

    error WriteAmountZero();

    error BatchWriteArrayLengthZero();

    error BatchWriteArrayLengthMismatch();
}
