// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Interfaces
import "./IOptionToken.sol";

interface IOptionEvents {
    /////////

    ///////// Write

    event OptionCreated(
        uint256 indexed optionTokenId,
        address indexed baseAsset,
        address indexed quoteAsset,
        uint32 exerciseTimestamp,
        uint32 expiryTimestamp,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    );

    event OptionsWritten(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );

    ///////// Exercise

    event OptionsExercised(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );

    ///////// Net Off

    event OptionsNettedOff(
        address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount
    );
}
