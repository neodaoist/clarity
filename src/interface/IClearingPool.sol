// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IClearingPool {
    function skimmable(address asset) external view returns (uint256 amountSkimmable);
    function skim(address asset) external returns (uint256 amountSkimmed);
}
