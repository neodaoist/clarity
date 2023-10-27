// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionState {
    /////////

    // QUESTION should this become strictly internal
    struct Ticket {
        address writer;
        uint80 shortAmount;
    }

    // QUESTION is this even needed, and if so, might we actually store it
    struct OptionState {
        uint80 amountWritten;
        uint80 amountExercised;
        uint80 amountNettedOff;
        uint16 numOpenTickets;
    }

    /////////

    function openInterest(uint256 optionTokenId) external view returns (uint80 amount);

    function writeableAmount(uint256 optionTokenId) external view returns (uint80 amount);

    function reedemableAmount(uint256 optionTokenId) external view returns (uint80 amount);
}
