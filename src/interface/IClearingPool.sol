// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IClearingPool {
    function skimmable(address asset) external view returns (uint256 amount);
    function skim(address asset) external returns (uint256 amount);
}
