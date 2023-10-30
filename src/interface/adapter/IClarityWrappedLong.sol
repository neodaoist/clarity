// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityWrappedLong {
    function wrapLongs(uint256 amount) external;
    function unwrapLongs(uint256 amount) external;
    function exerciseLongs(uint256 amount) external;
}
