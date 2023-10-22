// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909MetadataURI} from "./interface/external/IERC6909MetadataURI.sol";
import {IERC20Minimal} from "./interface/external/IERC20Minimal.sol";

import "./util/LibOptionToken.sol";
import "./util/LibOptionState.sol";
import "./util/LibPosition.sol";
import "solmate/utils/SafeCastLib.sol";

import {ERC6909} from "solmate/tokens/ERC6909.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
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
contract ClarityMarkets is IOptionMarkets, IClarityCallback, ERC6909 {
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

    ///////// Private Constant/Immutable

    uint8 private constant OPTION_CONTRACT_SCALAR = 6;

    ///////// Option Token Views

    function optionTokenId(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        bool isCall
    ) external view returns (uint256 _optionTokenId) {
        // Hash the option
        uint248 optionHash = LibOptionToken.hashOption(
            baseAsset, quoteAsset, exerciseWindows, strikePrice, isCall ? OptionType.CALL : OptionType.PUT
        );

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId];
        address writeAsset = optionStored.writeAsset;

        // Check that the option has been created
        if (writeAsset == address(0)) {
            // TODO revert
        }

        _optionTokenId = optionHash << 8;
    }

    function option(uint256 _optionTokenId) external view returns (Option memory _option) {
        // Check that it is a Long, Short, or Assigned Short token
        // TODO

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId];
        address writeAsset = optionStored.writeAsset;

        // Check that the option has been created
        if (writeAsset == address(0)) {
            // TODO revert
        }

        // Build the user-friendly Option struct
        if (optionStored.optionType == OptionType.CALL) {
            _option.baseAsset = writeAsset;
            _option.quoteAsset = optionStored.exerciseAsset;
            _option.strikePrice = (
                optionStored.exerciseAmount * (10 ** (optionStored.exerciseDecimals - OPTION_CONTRACT_SCALAR))
            );
            _option.optionType = OptionType.CALL;
        } else {
            _option.baseAsset = optionStored.exerciseAsset;
            _option.quoteAsset = writeAsset;
            _option.strikePrice =
                (optionStored.writeAmount * (10 ** (optionStored.writeDecimals - OPTION_CONTRACT_SCALAR)));
            _option.optionType = OptionType.CALL;
        }

        // TODO add ExerciseWindows and ExerciseStyle
    }

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

    ///////// ERC6909MetadataModified

    /// @notice The name for each id
    mapping(uint256 id => string name) public names;

    /// @notice The symbol for each id
    mapping(uint256 id => string symbol) public symbols;

    /// @notice The number of decimals for each id (always OPTION_CONTRACT_SCALAR)
    function decimals(uint256 /*id*/ ) public pure returns (uint8) {
        return OPTION_CONTRACT_SCALAR;
    }

    ///////// ERC6909MetadataURI

    /// @dev Thrown when the id does not exist
    /// @param id The id of the token
    error InvalidId(uint256 id);

    /// @notice The URI for each id
    /// @return The URI of the token
    function tokenURI(uint256) public pure returns (string memory) {
        return "setec astronomy";
    }

    ///////// Option Actions

    function writeCall(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {
        ///////// Function Requirements

        // TODO add ERC20 type cast and remove/combine IERC20Minimal
        // TODO check that assets are valid ERC20s, including decimals >= 6
        // TODO check that exerciseWindows are ascending and non-overlapping
        // TODO check that strikePrice is not too large
        // TODO check for approvals

        ///////// Effects

        // Calculate the write and exercise amounts // TODO resolve danger of external calls
        uint8 writeDecimals = IERC20Minimal(baseAsset).decimals();
        uint8 exerciseDecimals = IERC20Minimal(quoteAsset).decimals();
        uint48 writeAmount = (10 ** (writeDecimals - OPTION_CONTRACT_SCALAR)).safeCastTo48();
        uint48 exerciseAmount =
            (strikePrice / (10 ** (exerciseDecimals - OPTION_CONTRACT_SCALAR))).safeCastTo48();

        // Generate the optionTokenId
        uint248 optionHash =
            LibOptionToken.hashOption(baseAsset, quoteAsset, exerciseWindows, strikePrice, OptionType.CALL);
        _optionTokenId = optionHash << 8;

        // Store the option information
        optionStorage[_optionTokenId] = OptionStorage({
            writeAsset: baseAsset,
            writeAmount: writeAmount,
            writeDecimals: writeDecimals,
            exerciseDecimals: exerciseDecimals,
            optionType: OptionType.CALL,
            exerciseStyle: ExerciseStyle.AMERICAN, // TODO
            exerciseAsset: quoteAsset,
            exerciseAmount: exerciseAmount,
            assignmentSeed: uint32(uint256(keccak256(abi.encodePacked(optionHash, block.timestamp)))),
            exerciseWindows: LibOptionToken.toExerciseWindows(exerciseWindows)[0] // TODO
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
        // Else the option is just created, with none actually written

        // TODO log event

        ///////// Protocol Invariant

        _verifyAfter(baseAsset, quoteAsset);
    }

    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
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
