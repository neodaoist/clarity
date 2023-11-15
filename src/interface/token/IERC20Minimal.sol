// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC20Minimal {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}
