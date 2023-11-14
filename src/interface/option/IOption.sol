// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IOption {
    /////////

    // TODO move to NatSpec

    // max option token types                       = 2^248  = 4.5e74 = 2^256 / 2^8
    // max options                                  = 2^64   = 1.8e18 = ~18 trillion contracts OI, bc option scalar is 6
    // max W or X asset for an option token type    = 2^64   = 1.8e18 = ~18 million units notional, bc option scalar is 6
    // max W or X asset collateral for an option    = 2^126  = 3.4e38 = 2^64 * 2^64
    // max asset pairs, for option token types               = 2.1e96 = 2^160 * 2^160

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
    /// @param exerciseTimestamp The first timestamp in this window on or after which the option can be exercised
    /// @param expiryTimestamp The last timestamp in this window before or on which the option can be exercised
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

    /////////

    function optionTokenId(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        bool isCall
    ) external view returns (uint256 optionTokenId);

    function option(uint256 optionTokenId) external view returns (Option memory option);
}
