// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityWrappedLong {
    // Events
    event ClarityWrappedLongDeployed(uint256 indexed optionTokenId, address indexed wrapperAddress);
    event ClarityLongsWrapped(address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount);
    event ClarityLongsUnwrapped(address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount);
    event ClarityLongsExercised(address indexed caller, uint256 indexed optionTokenId, uint64 optionAmount);

    // Functions
    function wrapLongs(uint64 optionAmount) external;
    function unwrapLongs(uint64 optionAmount) external;
    function exerciseLongs(uint64 optionAmount) external;
}
