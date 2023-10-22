// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}
