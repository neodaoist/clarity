// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionState {
    /////////

    // QUESTION should this become strictly internal
    struct Ticket {
        address writer;
        uint80 shortAmount;
    }

    struct OptionState {
        uint80 amountWritten;
        uint80 amountExercised;
        uint80 amountNettedOff;
        uint16 numOpenTickets; // QUESTION ditto
    }

    /////////

    function optionState(uint256 optionTokenId) external view returns (OptionState memory optionState);

    function openInterest(uint256 optionTokenId) external view returns (uint80 amount);

    function writeableAmount(uint256 optionTokenId) external view returns (uint80 amount);

    function reedemableAmount(uint256 optionTokenId) external view returns (uint80 amount);
}
