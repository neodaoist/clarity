// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IOptionActions {
    function writeNewCall(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint64 optionAmount
    ) external returns (uint256 optionTokenId);
    function writeNewPut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint64 optionAmount
    ) external returns (uint256 optionTokenId);
    function writeExisting(uint256 optionTokenId, uint64 optionAmount) external;
    function batchWriteExisting(
        uint256[] calldata optionTokenIds,
        uint64[] calldata optionAmounts
    ) external;
    function exercise(uint256 optionTokenId, uint64 optionAmount) external;
    function netOff(uint256 optionTokenId, uint64 optionAmount)
        external
        returns (uint128 writeAssetReturned);
    function redeem(uint256 optionTokenId)
        external
        returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed);
}
