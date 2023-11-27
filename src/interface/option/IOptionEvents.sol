// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Interfaces
import "./IOption.sol";

interface IOptionEvents {
    /////////

    ///////// Write

    event OptionCreated(
        uint256 indexed optionTokenId,
        address indexed baseAsset,
        address indexed quoteAsset,
        uint32 expiry,
        uint256 strike,
        IOption.OptionType optionType,
        IOption.ExerciseStyle exerciseStyle
    );

    event OptionsWritten(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );

    ///////// Net

    event OptionsNettedOff(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );

    ///////// Exercise

    event OptionsExercised(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );

    ///////// Redeem

    event ShortsRedeemed(address indexed caller, uint256 indexed shortTokenId);
}
