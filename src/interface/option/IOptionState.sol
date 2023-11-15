// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOptionState {
    function openInterest(uint256 optionTokenId) external view returns (uint64 amount);
    function remainingWriteableAmount(uint256 optionTokenId)
        external
        view
        returns (uint64 amount);
}
