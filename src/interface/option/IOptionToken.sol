// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionToken {
    /////////

    // max option token types                       = 2^248  = 4.5e74 = 2^256 / 2^8
    // max options                                  = 2^80   = 1.2e24 = ~quadrillion contracts OI, bc option scalar is 9
    // max W or X asset for an option token type    = 2^56   = 7.2e16 = ~72 million units notional, bc option scalar is 9
    // max W or X asset collateral for an option    = 2^136  = 8.7e40 = 2^80 * 2^56
    // max asset pairs, for option token types               = 2.1e96 = 2^160 * 2^160
    // max time pairs, for exercise windows                  = 128    = (2^32 * 2^8) / 2^32 / 2

    struct OptionStorage {
        address writeAsset;
        uint56 writeAmount;
        bool isCall;
        uint32 assignmentSeed;
        address exerciseAsset;
        uint56 exerciseAmount;
        uint40 exerciseWindows;
    }

    struct Option {
        address baseAsset;
        uint56 baseAmount;
        address quoteAsset;
        uint56 quoteAmount;
        OptionType optionType;
        ExerciseWindow[] exerciseWindows;
    }

    enum OptionType {
        CALL,
        PUT
    }

    struct ExerciseWindow {
        uint32 exerciseTimestampIncl; // max Sun Feb 07 2106 06:28:16 GMT+0000
        uint32 expiryTimestampExcl; // ditto
    }

    // TODO double check combinatorics of packing OTTs into uint248
    // TODO double check entropy of uint32 assignmentSeed

    /////////

    function optionTokenId(
        address writeAsset,
        uint56 writeAmount,
        bool isCall,
        address exerciseAsset,
        uint56 exerciseAmount,
        uint40 exerciseWindows
    ) external pure returns (uint256 optionTokenId);

    function option(uint256 optionTokenId) external pure returns (Option memory _option);
}
