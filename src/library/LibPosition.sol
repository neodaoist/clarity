// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Interfaces
import {IPosition} from "../interface/IPosition.sol";

library LibPosition {
    /////////

    ///////// Token ID Encoding

    function hashToId(uint248 instrumentHash) internal pure returns (uint256 id) {
        id = uint256(instrumentHash) << 8;
    }

    function idToHash(uint256 tokenId) internal pure returns (uint248 hash) {
        hash = uint248(tokenId >> 8);
    }

    function longToShort(uint256 tokenId) internal pure returns (uint256 id) {
        id = tokenId | 1;
    }

    function longToAssignedShort(uint256 tokenId) internal pure returns (uint256 id) {
        id = tokenId | 2;
    }

    function shortToLong(uint256 tokenId) internal pure returns (uint256 id) {
        id = tokenId ^ 1;
    }

    function shortToAssignedShort(uint256 tokenId) internal pure returns (uint256 id) {
        id = (tokenId ^ 1) | 2;
    }

    function assignedShortToLong(uint256 tokenId) internal pure returns (uint256 id) {
        id = tokenId ^ 2;
    }

    function assignedShortToShort(uint256 tokenId) internal pure returns (uint256 id) {
        id = (tokenId ^ 2) | 1;
    }

    ///////// Token Type

    /// @dev Discard the upper 31 bytes (the option hash) to get the lowest
    /// byte, then unsafely cast to TokenType enum type
    function tokenType(uint256 tokenId)
        internal
        pure
        returns (IPosition.TokenType _tokenType)
    {
        _tokenType = IPosition.TokenType(tokenId & 0xFF);
    }

    function toString(IPosition.TokenType _tokenType)
        internal
        pure
        returns (string memory str)
    {
        if (_tokenType == IPosition.TokenType.LONG) {
            str = "Long";
        } else if (_tokenType == IPosition.TokenType.SHORT) {
            str = "Short";
        } else if (_tokenType == IPosition.TokenType.ASSIGNED_SHORT) {
            str = "Assigned";
        } else {
            revert(); // theoretically unreachable
        }
    }
}
