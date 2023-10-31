// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityWrappedShort {
    function wrapShorts(uint256 shortAmount) external;
    function unwrapShorts(uint256 shortAmount) external;
    function redeemShorts(uint256 shortAmount) external;
}
