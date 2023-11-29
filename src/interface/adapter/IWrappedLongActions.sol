// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWrappedLongActions {
    function wrapLongs(uint64 optionAmount) external;
    function unwrapLongs(uint64 optionAmount) external;
    function exerciseOption(uint64 optionAmount) external;
}
