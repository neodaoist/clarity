// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IWrappedShortActions {
    function wrapShorts(uint64 shortAmount) external;
    function unwrapShorts(uint64 shortAmount) external;
    function redeemShorts(uint64 shortAmount) external;
}
