// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityWrappedShort {
    event ClarityWrappedShortDeployed(uint256 indexed shortTokenId, address indexed wrapperAddress);
    event ClarityShortsWrapped(address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount);
    event ClarityShortsUnwrapped(address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount);
    event ClarityShortsRedeemed(address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount);

    function wrapShorts(uint256 shortAmount) external;
    function unwrapShorts(uint256 shortAmount) external;
    function redeemShorts(uint256 shortAmount) external;
}
