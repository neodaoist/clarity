// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./interface/IOptionMarkets.sol";
import "./interface/IClarityCallback.sol";
import "./interface/IERC6909Extended.sol";

import "./util/LibOptionToken.sol";
import "./util/LibOptionState.sol";
import "./util/LibPosition.sol";
import "solmate/utils/SafeCastLib.sol";

import "solmate/tokens/ERC6909.sol";

/// @title clarity.markets
///
/// @author me.eth
/// @author you.eth
/// @author ?????????
///
/// @notice Clarity is a decentralized counterparty clearinghouse (DCP), for the writing,
/// transfer, and settlement of options and futures on the Ethereum blockchain. The protocol
/// is open source, open state, and open access. It has zero fees, zero oracles, and zero
/// governance. It is designed to be secure, composable, immutable, ergonomic, and gas minimal.
contract ClarityMarkets is IOptionMarkets, IClarityCallback, IERC6909Extended, ERC6909 {
    /////////

    using LibOptionToken for Option;
    using LibOptionState for OptionState;
    using LibPosition for Position;
    using SafeCastLib for uint256;

    ///////// Public State

    mapping(uint256 => uint256[]) public shortOwnersOf;

    ///////// Private State

    mapping(uint256 => IOptionState.OptionState) private optionStates;

    mapping(address => uint256) private assetLiabilities;

    ///////// Option Token Views

    function optionTokenId(
        address writeAsset,
        uint56 writeAmount,
        bool isCall,
        address exerciseAsset,
        uint56 exerciseAmount,
        uint40 exerciseWindows
    ) external pure returns (uint256 _optionTokenId) {}

    function option(uint256 _optionTokenId) external pure returns (Option memory _option) {}

    ///////// Position Views

    function position(uint256 _optionTokenId) external view returns (Position memory _position, int160 magnitude) {}

    function positionTokenType(uint256 tokenId) external view returns (PositionTokenType _positionTokenType) {}

    ///////// Option State Views

    function openInterest(uint256 _optionTokenId) external view returns (uint80 optionAmount) {}

    function writeableAmount(uint256 _optionTokenId) external view returns (uint80 __writeableAmount) {}

    function exercisableAmount(uint256 _optionTokenId) external view returns (uint80 assignableAmount) {}

    function writerNettableAmount(uint256 _optionTokenId) external view returns (uint80 nettableAmount) {}

    function writerRedeemableAmount(uint256 _optionTokenId) external view returns (uint80 redeemableAmount) {}

    ///////// Option Actions

    function writeCall(
        address baseAsset,
        uint56 baseAmount,
        address quoteAsset,
        uint56 quoteAmount,
        uint40 exerciseWindows,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {}

    function writePut(
        address baseAsset,
        uint56 baseAmount,
        address quoteAsset,
        uint56 quoteAmount,
        uint40 exerciseWindows,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {}

    function write(uint256 _optionTokenId, uint80 optionsAmount) external override {}

    function batchWrite(uint256[] calldata optionTokenIds, uint80[] calldata optionAmounts) external {}

    function exercise(uint256 _optionTokenId, uint80 optionsAmount) external override {}

    function netoff(uint256 _optionTokenId, uint80 optionsAmount)
        external
        override
        returns (uint176 writeAssetNettedOff)
    {}

    function redeem(uint256 _optionTokenId)
        external
        override
        returns (uint176 writeAssetRedeemed, uint176 exerciseAssetRedeemed)
    {}

    /////////

    // TODO add skim() as a Pool action, maybe not an Option action

    /////////

    // TODO add Metadata extension:
    // name()
    // symbol()
    // decimals()

    // TODO add Metadata URI extension:
    // tokenURI()

    /////////

    function clarityCallback(Callback calldata _callback) external {}

    /////////

    function _assignShorts(uint256 _optionTokenId, uint80 amountToAssign) private {}

    /////////

    function _writeableAmount(uint256 _optionTokenId) private view returns (uint80 __writeableAmount) {}

    function _exercisableAmount(uint256 _optionTokenId) private view returns (uint80 assignableAmount) {}

    function _writerNettableAmount(uint256 _optionTokenId) private view returns (uint80 nettableAmount) {}

    function _writerRedeemableAmount(uint256 _optionTokenId) private view returns (uint80 redeemableAmount) {}
}
