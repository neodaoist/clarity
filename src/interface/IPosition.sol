// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPosition {
    /////////

    enum TokenType {
        LONG,
        SHORT,
        ASSIGNED_SHORT
    }

    struct Position {
        uint64 amountLong; // optionTokenId
        uint64 amountShort; // optionTokenId | 1
        uint64 amountAssignedShort; // optionTokenId | 2
    }

    /////////

    function tokenType(uint256 tokenId) external view returns (TokenType _tokenType);

    function position(uint256 tokenId)
        external
        view
        returns (Position memory position, int160 magnitude);
}
