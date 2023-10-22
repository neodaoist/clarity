// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionPosition {
    /////////

    /// @notice Explain to an end user what this does
    /// @dev amountExercisable =
    /// amountNettable =
    /// amountRedeemable =
    struct Position {
        uint80 amountLong; // optionTokenId
        uint80 amountShort; // optionTokenId + 1
        uint80 amountAssignedShort; // optionTokenId + 2
    }

    enum PositionTokenType {
        LONG,
        SHORT,
        ASSIGNED_SHORT
    }

    /////////

    function position(uint256 optionTokenId)
        external
        view
        returns (Position memory position, int160 magnitude);

    function positionTokenType(uint256 tokenId) external view returns (PositionTokenType positionTokenType);
}
