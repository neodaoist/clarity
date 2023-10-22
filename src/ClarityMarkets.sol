// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909MetadataURI} from "./interface/external/IERC6909MetadataURI.sol";
import {IERC20Minimal} from "./interface/external/IERC20Minimal.sol";

import {LibOptionToken} from "./library/LibOptionToken.sol";
import {LibOptionState} from "./library/LibOptionState.sol";
import {LibPosition} from "./library/LibPosition.sol";
import {OptionErrors} from "./library/OptionErrors.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

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
/// is open source, open state, and open access. It has zero oracles, zero governance, and
/// zero custody. It is designed to be secure, composable, immutable, ergonomic, and gas minimal.
contract ClarityMarkets is IOptionMarkets, IClarityCallback, ERC6909 {
    /////////

    using LibOptionToken for Option;
    using LibOptionState for OptionState;
    using LibPosition for Position;
    using SafeCastLib for uint256;

    ///////// Public State

    mapping(uint256 => uint256[]) public shortOwnersOf;

    ///////// public Constant/Immutable

    uint8 public constant OPTION_CONTRACT_SCALAR = 6;
    uint8 public constant MAXIMUM_ERC20_DECIMALS = 18;
    uint104 public constant MAXIMUM_STRIKE_PRICE = 18446744073709551615000000000000; // ((2**64-1) * 10**(18-6)

    ///////// Private State

    mapping(uint256 => OptionStorage) private optionStorage;

    mapping(address => uint256) private assetLiabilities;

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
            _option.optionType = OptionType.PUT;
        }
        _option.exerciseWindow = optionStored.exerciseWindow;
        _option.exerciseStyle = optionStored.exerciseStyle;
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
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {
        ///////// Function Requirements
        // Check that assets are valid
        if (baseAsset == quoteAsset) {
            revert OptionErrors.AssetsIdentical(baseAsset, quoteAsset);
        }
        // TODO address the danger of external call
        // TODO decide how to combine/remove IERC20Minimal and ERC20 type cast
        uint8 writeDecimals = IERC20Minimal(baseAsset).decimals();
        uint8 exerciseDecimals = IERC20Minimal(quoteAsset).decimals(); // TODO ditto
        if (writeDecimals < OPTION_CONTRACT_SCALAR || writeDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(baseAsset, writeDecimals);
        }
        if (exerciseDecimals < OPTION_CONTRACT_SCALAR || exerciseDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(quoteAsset, exerciseDecimals);
        }

        // Check that the exercise window is valid
        if (exerciseWindow.length != 2) {
            revert OptionErrors.ExerciseWindowMispaired();
        }
        if (exerciseWindow[0] == exerciseWindow[1]) {
            revert OptionErrors.ExerciseWindowZeroTime(exerciseWindow[0], exerciseWindow[1]);
        }
        if (exerciseWindow[0] > exerciseWindow[1]) {
            revert OptionErrors.ExerciseWindowMisordered(exerciseWindow[0], exerciseWindow[1]);
        }
        if (exerciseWindow[1] <= block.timestamp) {
            revert OptionErrors.ExerciseWindowExpiryPast(exerciseWindow[1]);
        }

        // Check that strike price is valid
        if (strikePrice > MAXIMUM_STRIKE_PRICE) {
            revert OptionErrors.StrikePriceTooLarge(strikePrice);
        }

        ///////// Effects
        // Calculate the write and exercise amounts
        uint64 writeAmount = (10 ** (writeDecimals - OPTION_CONTRACT_SCALAR)).safeCastTo64();
        uint64 exerciseAmount =
            (strikePrice / (10 ** (exerciseDecimals - OPTION_CONTRACT_SCALAR))).safeCastTo64();

        // Determine the exercise style
        ExerciseStyle exerciseStyle = LibOptionToken.determineExerciseStyle(exerciseWindow);

        // Generate the optionTokenId
        uint248 optionHash =
            LibOptionToken.hashOption(baseAsset, quoteAsset, exerciseWindow, strikePrice, OptionType.CALL);
        _optionTokenId = optionHash << 8;

        // Store the option information
        optionStorage[_optionTokenId] = OptionStorage({
            writeAsset: baseAsset,
            writeAmount: writeAmount,
            writeDecimals: writeDecimals,
            exerciseDecimals: exerciseDecimals,
            optionType: OptionType.CALL,
            exerciseStyle: exerciseStyle,
            exerciseAsset: quoteAsset,
            exerciseAmount: exerciseAmount,
            assignmentSeed: uint32(uint256(keccak256(abi.encodePacked(optionHash, block.timestamp)))),
            exerciseWindow: LibOptionToken.toExerciseWindow(exerciseWindow)
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
        // Else the option is just created, with no options actually written and therefore no token mints

        // Log events
        emit CreateOption(
            _optionTokenId,
            baseAsset,
            quoteAsset,
            exerciseWindow[0],
            exerciseWindow[1],
            strikePrice,
            OptionType.CALL
        );
        if (optionAmount > 0) {
            // TODO combine biz logic
            emit WriteOptions(msg.sender, _optionTokenId, optionAmount);
        }

        ///////// Protocol Invariant
        // Check that the asset liabilities can be met
        _verifyAfter(baseAsset, quoteAsset);
    }

    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
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
