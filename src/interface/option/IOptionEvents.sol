// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import "./IOptionToken.sol";

interface IOptionEvents {
    /////////

    // TODO update uint widths to reduce type casts in production code

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

    ///////// Redeem

    event ShortsRedeemed(address indexed caller, uint256 indexed shortTokenId);
}
