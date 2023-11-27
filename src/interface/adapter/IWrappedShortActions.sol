// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWrappedShortActions {
    function wrapShorts(uint64 shortAmount) external;
    function unwrapShorts(uint64 shortAmount) external;
    function redeemCollateral(uint64 shortAmount) external;
}
