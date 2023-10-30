// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../option/IOptionToken.sol";

interface IWrappedOption {
    function optionTokenId() external view returns (uint256 optionTokenId);
    function option() external view returns (IOptionToken.Option memory option);
    function optionType() external view returns (IOptionToken.OptionType optionType);
    function exerciseStyle() external view returns (IOptionToken.ExerciseStyle exerciseStyle);
    function exerciseWindow() external view returns (IOptionToken.ExerciseWindow memory exerciseWindow);
}
