// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909Extended} from "./interface/IERC6909Extended.sol";
import {IERC20Minimal} from "./interface/external/IERC20Minimal.sol";

import "./util/LibOptionToken.sol";
import "./util/LibOptionState.sol";
import "./util/LibPosition.sol";
import "solmate/utils/SafeCastLib.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC6909} from "solmate/tokens/ERC6909.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

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

    mapping(uint256 => OptionStorage) private optionStorage;

    mapping(address => uint256) private assetLiabilities;

    ///////// Private Constant/Immutable State

    uint8 private constant OPTION_CONTRACT_SCALAR = 6;

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

    function position(uint256 _optionTokenId)
        external
        view
        returns (Position memory _position, int160 magnitude)
    {}

    function positionTokenType(uint256 tokenId)
        external
        view
        returns (PositionTokenType _positionTokenType)
    {}

    ///////// Option State Views

    function openInterest(uint256 _optionTokenId) external view returns (uint80 optionAmount) {}

    function writeableAmount(uint256 _optionTokenId) external view returns (uint80 __writeableAmount) {}

    function exercisableAmount(uint256 _optionTokenId) external view returns (uint80 assignableAmount) {}

    function writerNettableAmount(uint256 _optionTokenId) external view returns (uint80 nettableAmount) {}

    function writerRedeemableAmount(uint256 _optionTokenId) external view returns (uint80 redeemableAmount) {}

    ///////// Option Actions

    function writeCall(
        address baseAsset,
        address quoteAsset,
        uint40 exerciseWindows,
        uint256 strike,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {
        ///////// Function Requirements

        // TODO add ERC20 type cast and remove/combine IERC20Minimal
        // TODO check that assets are valid ERC20s, including decimals >= 6
        // TODO check that strike is not too large
        // TODO check for approvals

        ///////// Effects

        // Calculate the write and exercise amounts
        uint56 writeAmount =
            (10 ** (IERC20Minimal(baseAsset).decimals() - OPTION_CONTRACT_SCALAR)).safeCastTo56();
        uint56 exerciseAmount =
            (strike / (10 ** (IERC20Minimal(quoteAsset).decimals() - OPTION_CONTRACT_SCALAR))).safeCastTo56();

        // Generate the optionTokenId
        uint248 optionHash = uint248(
            uint256(
                keccak256(
                    abi.encodePacked(baseAsset, writeAmount, quoteAsset, exerciseAmount, exerciseWindows)
                )
            )
        );
        _optionTokenId = optionHash << 8;

        // Store the option information
        optionStorage[_optionTokenId] = OptionStorage({
            writeAsset: baseAsset,
            writeAmount: writeAmount,
            isCall: true,
            assignmentSeed: uint32(uint256(keccak256(abi.encodePacked(optionHash, block.timestamp)))),
            exerciseAsset: quoteAsset,
            exerciseAmount: exerciseAmount,
            exerciseWindows: exerciseWindows
        });

        if (optionAmount > 0) {
            // Mint the longs and shorts
            _mint(msg.sender, _optionTokenId, optionAmount);
            _mint(msg.sender, _optionTokenId + 1, optionAmount);

            // Track the asset liability
            _incrementAssetLiability(baseAsset, writeAmount * optionAmount);

            ///////// Interactions

            // Transfer in the write asset
            SafeTransferLib.safeTransferFrom(
                ERC20(baseAsset), msg.sender, address(this), writeAmount * optionAmount
            );
        }
        // Else otherwise the option is just created, with none written

        // TODO log event

        ///////// Protocol Invariant

        _verifyAfter(baseAsset, quoteAsset);
    }

    function writePut(
        address baseAsset,
        address quoteAsset,
        uint40 exerciseWindows,
        uint256 strike,
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

    ///////// FREI-PI

    function _incrementAssetLiability(address asset, uint256 amount) internal {
        assetLiabilities[asset] += amount;
    }

    function _decrementAssetLiability(address asset, uint256 amount) internal {
        assetLiabilities[asset] -= amount;
    }

    function _verifyAfter(address writeAsset, address exerciseAsset) internal view {
        assert(IERC20Minimal(writeAsset).balanceOf(address(this)) >= assetLiabilities[writeAsset]);
        assert(IERC20Minimal(exerciseAsset).balanceOf(address(this)) >= assetLiabilities[exerciseAsset]);
    }

    /////////

    function _assignShorts(uint256 _optionTokenId, uint80 amountToAssign) private {}

    /////////

    function _writeableAmount(uint256 _optionTokenId) private view returns (uint80 __writeableAmount) {}

    function _exercisableAmount(uint256 _optionTokenId) private view returns (uint80 assignableAmount) {}

    function _writerNettableAmount(uint256 _optionTokenId) private view returns (uint80 nettableAmount) {}

    function _writerRedeemableAmount(uint256 _optionTokenId) private view returns (uint80 redeemableAmount) {}
}
