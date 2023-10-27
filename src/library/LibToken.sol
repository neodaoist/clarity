// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/option/IOptionToken.sol";

library LibToken {
    /////////

    function paramsToHash(
        address baseAsset,
        address quoteAsset,
        uint32[] memory exerciseWindow,
        uint256 strikePrice,
        IOptionToken.OptionType optionType
    ) internal pure returns (uint248) {
        return uint248(
            bytes31(keccak256(abi.encode(baseAsset, quoteAsset, exerciseWindow, strikePrice, optionType)))
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

    function assignedShortToLong(uint256 tokenId) internal pure returns (uint256) {
        return tokenId ^ 2;
    }

    function tokenType(uint256 tokenId) internal pure returns (IOptionToken.TokenType) {
        return IOptionToken.TokenType(tokenId & 0xFF);
    }
}
