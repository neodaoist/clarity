// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOptionState {
    /////////

    function openInterest(uint256 optionTokenId) external view returns (uint80 amount);

    function writeableAmount(uint256 optionTokenId) external view returns (uint80 amount);

    function reedemableAmount(uint256 optionTokenId) external view returns (uint80 amount);
}
