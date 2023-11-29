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
        EUROPEAN
    }
    // BERMUDAN

    struct Option {
        address baseAsset;
        address quoteAsset;
        uint32 expiry;
        uint256 strike;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
    }
}
