// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOptionActions {
    function writeCall(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice, // max value of 18446744073709551615000000 = ((2**64-1) *
            // 10**6
        uint64 optionAmount
    ) external returns (uint256 optionTokenId);
    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice, // max value of 18446744073709551615000000 = ((2**64-1) *
            // 10**6
        uint64 optionAmount
    ) external returns (uint256 optionTokenId);
    function write(uint256 optionTokenId, uint64 optionAmount) external;
    function batchWrite(
        uint256[] calldata optionTokenIds,
        uint64[] calldata optionAmounts
    ) external;
    function exercise(uint256 optionTokenId, uint64 optionAmount) external;
    function netOff(uint256 optionTokenId, uint64 optionAmount)
        external
        returns (uint128 writeAssetNettedOff);
    function redeem(uint256 optionTokenId)
        external
        returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed);
}
