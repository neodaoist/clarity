// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPosition {
    /////////

    enum TokenType {
        LONG,
        SHORT,
        ASSIGNED_SHORT
    }

    /// @notice Explain to an end user what this does
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

    function positionNettableAmount(uint256 tokenId)
        external
        view
        returns (uint64 amount);

    function positionRedeemableAmount(uint256 tokenId)
        external
        view
        returns (
            uint64 writeAssetAmount,
            uint32 writeAssetWhen,
            uint64 exerciseAssetAmount,
            uint32 exerciseAssetWhen
        );
}