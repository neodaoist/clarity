// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionToken {
    /////////

    // max option token types                       = 2^248  = 4.5e74 = 2^256 / 2^8
    // max options                                  = 2^80   = 1.2e18 = ~quintillion contracts OI, bc option scalar is 6
    // max W or X asset for an option token type    = 2^48   = 2.8e14 = ~280 million units notional, bc option scalar is 6
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
        ExerciseWindow exerciseWindows; // TODO add Bermudan support
    }

    struct Option {
        address baseAsset;
        address quoteAsset;
        ExerciseWindow[] exerciseWindows;
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

    struct ExerciseWindow {
        uint32 exerciseTimestampIncl; // max Sun Feb 07 2106 06:28:16 GMT+0000
        uint32 expiryTimestampIncl; // ditto
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

    function option(uint256 optionTokenId) external view returns (Option memory _option);
}
