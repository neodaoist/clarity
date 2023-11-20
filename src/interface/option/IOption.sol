// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOption {
    /////////

    enum OptionType {
        CALL,
        PUT
    }

    enum ExerciseStyle {
        AMERICAN,
        EUROPEAN,
        BERMUDAN
    }

    /// @dev Represents a time window in which an option can be exercised
    /// @param exerciseTimestamp The first timestamp in this window on or after
    /// which the
    /// option can be exercised
    /// @param expiryTimestamp The last timestamp in this window before or on
    /// which the
    /// option can be exercised
    struct ExerciseWindow {
        uint32 exerciseTimestamp; // max Sun Feb 07 2106 06:28:16 GMT+0000
        uint32 expiryTimestamp; // ditto
    }

    struct Option {
        address baseAsset;
        address quoteAsset;
        ExerciseWindow exerciseWindow;
        uint256 strikePrice;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
    }
}
