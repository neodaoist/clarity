// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IInstrument {
    function openInterest(uint256 optionTokenId) external view returns (uint64 amount);
}
