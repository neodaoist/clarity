// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IOptionToken.sol";

interface IOptionEvents {
    /////////

    ///////// Write

    event CreateOption(
        uint256 indexed optionTokenId,
        address indexed baseAsset,
        address indexed quoteAsset,
        uint32 exerciseTimestamp,
        uint32 expiryTimestamp,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    );

    event WriteOptions(address indexed caller, uint256 indexed optionTokenId, uint80 optionAmount);
}
