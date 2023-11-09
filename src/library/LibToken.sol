// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOptionToken} from "../interface/option/IOptionToken.sol";

// Libraries
import {OptionErrors} from "../library/OptionErrors.sol";

// TODO use named return vars
library LibToken {
    /////////

    ///////// Token ID

    function paramsToHash(
        address baseAsset,
        address quoteAsset,
        uint32[] memory exerciseWindow,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
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

    function tokenType(uint256 tokenId) internal pure returns (IOptionToken.TokenType) {
        return IOptionToken.TokenType(tokenId & 0xFF);
    }

    // TODO write unit test
    function toTokenTypeString(uint256 tokenId)
        internal
        pure
        returns (string memory str)
    {
        IOptionToken.TokenType _tokenType = tokenType(tokenId);

        if (_tokenType == IOptionToken.TokenType.LONG) {
            str = "Long";
        } else if (_tokenType == IOptionToken.TokenType.SHORT) {
            str = "Short";
        } else if (_tokenType == IOptionToken.TokenType.ASSIGNED_SHORT) {
            str = "Assigned Short";
        } else {
            revert OptionErrors.InvalidTokenType(tokenId); // unreachable
        }
    }
}
