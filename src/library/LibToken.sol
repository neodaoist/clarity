// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IPosition} from "../interface/IPosition.sol";
import {IOption} from "../interface/option/IOption.sol";

// Libraries
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";

// TODO use named return vars
library LibToken {
    /////////

    ///////// Token ID

    function paramsToHash(
        address baseAsset,
        address quoteAsset,
        uint32[] memory exerciseWindow,
        uint256 strikePrice,
        IOption.OptionType optionType
    ) internal pure returns (uint248) {
        return uint248(
            bytes31(
                keccak256(
                    abi.encode(
                        baseAsset, quoteAsset, exerciseWindow, strikePrice, optionType
                    )
                )
            )
        );
    }

    function hashToId(uint248 instrumentHash) internal pure returns (uint256) {
        return uint256(instrumentHash) << 8;
    }

    function idToHash(uint256 tokenId) internal pure returns (uint248) {
        return uint248(tokenId >> 8);
    }

    function longToShort(uint256 tokenId) internal pure returns (uint256) {
        return tokenId | 1;
    }

    function longToAssignedShort(uint256 tokenId) internal pure returns (uint256) {
        return tokenId | 2;
    }

    function shortToLong(uint256 tokenId) internal pure returns (uint256) {
        return tokenId ^ 1;
    }

    function shortToAssignedShort(uint256 tokenId) internal pure returns (uint256) {
        return (tokenId ^ 1) | 2;
    }

    function assignedShortToLong(uint256 tokenId) internal pure returns (uint256) {
        return tokenId ^ 2;
    }

    function assignedShortToShort(uint256 tokenId) internal pure returns (uint256) {
        return (tokenId ^ 2) | 1;
    }

    ///////// Token Type

    function tokenType(uint256 tokenId) internal pure returns (IPosition.TokenType) {
        return IPosition.TokenType(tokenId & 0xFF);
    }
}
