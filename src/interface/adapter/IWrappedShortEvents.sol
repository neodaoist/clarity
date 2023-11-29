// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
    event ClarityCollateralRedeemed(
        address indexed caller, uint256 indexed shortTokenId, uint64 optionAmount
    );
}
