// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionState {
    /////////

    struct Ticket {
        address writer;
        uint80 shortAmount;
    }

    struct OptionState {
        uint80 amountWritten;
        uint80 amountExercised;
        uint80 amountNettedOff;
        uint16 openTicketAmount;
    }

    /////////

    function openInterest(uint256 optionTokenId) external view returns (uint80 optionAmount);

    function writeableAmount(uint256 optionTokenId) external view returns (uint80 writeableAmount);

    function exercisableAmount(uint256 optionTokenId) external view returns (uint80 assignableAmount);

    function writerNettableAmount(uint256 optionTokenId) external view returns (uint80 nettableAmount);

    function writerRedeemableAmount(uint256 optionTokenId) external view returns (uint80 redeemableAmount);
}
