// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IWrappedShortEvents {
    event ClarityWrappedShortDeployed(
        uint256 indexed shortTokenId, address indexed wrapperAddress
    );
    event ClarityShortsWrapped(
        address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount
    );
    event ClarityShortsUnwrapped(
        address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount
    );
    event ClarityShortsRedeemed(
        address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount
    );
}
