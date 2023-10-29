// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionToken {
    /////////

    // max option token types                       = 2^248  = 4.5e74 = 2^256 / 2^8
    // max options                                  = 2^80   = 1.2e18 = ~quintillion contracts OI, bc option scalar is 6
    // max W or X asset for an option token type    = 2^64   = 1.8e19 = ~18 million units notional, bc option scalar is 6
    // max W or X asset collateral for an option    = 2^136  = 8.7e40 = 2^80 * 2^56
    // max asset pairs, for option token types               = 2.1e96 = 2^160 * 2^160
    // max time pairs, for exercise windows                  = 128    = (2^32 * 2^8) / 2^32 / 2

    struct OptionStorage {
        address writeAsset;
        uint64 writeAmount;
        uint8 writeDecimals;
        uint8 exerciseDecimals;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
        address exerciseAsset;
        uint64 exerciseAmount;
        uint32 assignmentSeed;
        ExerciseWindow exerciseWindow; // TODO add Bermudan support
    }

    struct Option {
        address baseAsset;
        address quoteAsset;
        ExerciseWindow exerciseWindow;
        uint256 strikePrice;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
    }

    enum OptionType {
        CALL,
        PUT
    }

    enum ExerciseStyle {
        AMERICAN,
        EUROPEAN,
        BERMUDAN
    }

    enum TokenType {
        LONG,
        SHORT,
        ASSIGNED_SHORT
    }

    /// @dev Represents a time window in which an option can be exercised
    /// @param exerciseTimestamp The first timestamp in this window on or after which the option can be exercised
    /// @param expiryTimestamp The last timestamp in this window before or on which the option can be exercised
    struct ExerciseWindow {
        uint32 exerciseTimestamp; // max Sun Feb 07 2106 06:28:16 GMT+0000
        uint32 expiryTimestamp; // ditto
    }

    // TODO double check combinatorics of packing OTTs into uint248
    // TODO double check entropy of uint32 assignmentSeed

    /////////

    function optionTokenId(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        bool isCall
    ) external view returns (uint256 optionTokenId);

    function option(uint256 optionTokenId) external view returns (Option memory option);

    function optionType(uint256 optionTokenId) external view returns (OptionType optionType);

    function exerciseStyle(uint256 optionTokenId) external view returns (ExerciseStyle exerciseStyle);
}
