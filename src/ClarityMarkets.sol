// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {console2} from "forge-std/console2.sol"; // TEMP

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
/// transfer, and settlement of options and futures contracts on the Ethereum blockchain.
/// The protocol is open source, open state, and open access. It has zero oracles, zero
/// governance, and zero custody. It is designed to be secure, composable, immutable,
/// ergonomic, and gas minimal.
contract ClarityMarkets is IOptionMarkets, IClarityCallback, IERC6909MetadataURI, ERC6909 {
    /////////

    using LibOptionToken for Option;
    using LibOptionState for OptionState;
    using LibPosition for Position;
    using SafeCastLib for uint256;

    ///////// Private Structs

    struct ClearingAssetInfo {
        address writeAsset;
        uint8 writeDecimals;
        uint64 writeAmount;
        address exerciseAsset;
        uint8 exerciseDecimals;
        uint64 exerciseAmount;
    }

    ///////// Private Enums

    enum AssignmentWheelTurnOutcome {
        INSUFFICIENT,
        EXACTLY_SUFFICIENT,
        MORE_THAN_SUFFICIENT
    }

    ///////// Public Constant/Immutable

    uint8 public constant OPTION_CONTRACT_SCALAR = 6;
    uint8 public constant MAXIMUM_ERC20_DECIMALS = 18;
    uint104 public constant MAXIMUM_STRIKE_PRICE = 18446744073709551615000000; // ((2**64-1) * 10**6

    ///////// Private State

    mapping(uint256 => OptionStorage) private optionStorage;

    mapping(address => uint256) private assetLiabilities;

    mapping(uint256 => Ticket[]) private openTickets;

    ///////// Option Token Views

    function optionTokenId(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindows,
        uint256 strikePrice,
        bool isCall
    ) external view returns (uint256 _optionTokenId) {
        // TODO initial checks

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
        // Check that it is a long
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
            _option.strikePrice = (optionStored.exerciseAmount * (10 ** OPTION_CONTRACT_SCALAR));
            _option.optionType = OptionType.CALL;
        } else {
            _option.baseAsset = optionStored.exerciseAsset;
            _option.quoteAsset = writeAsset;
            _option.strikePrice = (optionStored.writeAmount * (10 ** OPTION_CONTRACT_SCALAR));
            _option.optionType = OptionType.PUT;
        }
        _option.exerciseWindow = optionStored.exerciseWindow;
        _option.exerciseStyle = optionStored.exerciseStyle;
    }

    function optionType(uint256 _optionTokenId) external view returns (OptionType _optionType) {
        // TODO initial checks

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            // TODO revert
        }

        _optionType = optionStored.optionType;
    }

    function exerciseStyle(uint256 _optionTokenId) external view returns (ExerciseStyle _exerciseStyle) {
        // TODO initial checks

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            // TODO revert
        }

        _exerciseStyle = optionStored.exerciseStyle;
    }

    ///////// Option State Views

    function optionState(uint256 _optionTokenId) external view returns (OptionState memory state) {
        // Check that it is a long
        // TODO

        state = OptionState({
            amountWritten: totalSupply[_optionTokenId].safeCastTo80(),
            amountExercised: totalSupply[_optionTokenId + 2].safeCastTo80(),
            amountNettedOff: 0, // TBD
            numOpenTickets: openTickets[_optionTokenId].length.safeCastTo16()
        });
    }

    function openInterest(uint256 _optionTokenId) external view returns (uint80 amount) {
        // Check that it is a long
        // TODO

        amount = totalSupply[_optionTokenId].safeCastTo80();
    }

    function writeableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

    function reedemableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

    ///////// Option Position Views

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

    function positionNettableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

    function positionRedeemableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

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
        _optionTokenId =
            _write(baseAsset, quoteAsset, exerciseWindow, strikePrice, optionAmount, OptionType.CALL);
    }

    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint80 optionAmount
    ) external returns (uint256 _optionTokenId) {
        _optionTokenId =
            _write(baseAsset, quoteAsset, exerciseWindow, strikePrice, optionAmount, OptionType.PUT);
    }

    function _write(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint80 optionAmount,
        OptionType _optionType
    ) private returns (uint256 _optionTokenId) {
        ///////// Function Requirements
        // Check that assets are valid
        if (baseAsset == quoteAsset) {
            revert OptionErrors.AssetsIdentical(baseAsset, quoteAsset);
        }
        // TODO address the danger of external call
        // TODO decide how to combine/remove IERC20Minimal and ERC20 type cast
        uint8 baseDecimals = IERC20Minimal(baseAsset).decimals();
        uint8 quoteDecimals = IERC20Minimal(quoteAsset).decimals();
        if (baseDecimals < OPTION_CONTRACT_SCALAR || baseDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(baseAsset, baseDecimals);
        }
        if (quoteDecimals < OPTION_CONTRACT_SCALAR || quoteDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(quoteAsset, quoteDecimals);
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
        // Calculate the write and exercise amounts for clearing purposes
        ClearingAssetInfo memory assetInfo; // memory struct to avoid stack too deep
        if (_optionType == OptionType.CALL) {
            assetInfo = ClearingAssetInfo({
                writeAsset: baseAsset,
                writeDecimals: baseDecimals,
                writeAmount: (10 ** (baseDecimals - OPTION_CONTRACT_SCALAR)).safeCastTo64(), // implicit 1 unit
                exerciseAsset: quoteAsset,
                exerciseDecimals: quoteDecimals,
                exerciseAmount: (strikePrice / (10 ** OPTION_CONTRACT_SCALAR)).safeCastTo64()
            });
        } else {
            assetInfo = ClearingAssetInfo({
                writeAsset: quoteAsset,
                writeDecimals: quoteDecimals,
                writeAmount: (strikePrice / (10 ** OPTION_CONTRACT_SCALAR)).safeCastTo64(), // implicit 1 unit
                exerciseAsset: baseAsset,
                exerciseDecimals: baseDecimals,
                exerciseAmount: (10 ** (baseDecimals - OPTION_CONTRACT_SCALAR)).safeCastTo64()
            });
        }

        // Determine the exercise style
        ExerciseStyle exStyle = LibOptionToken.determineExerciseStyle(exerciseWindow);

        // Generate the optionTokenId
        uint248 optionHash =
            LibOptionToken.hashOption(baseAsset, quoteAsset, exerciseWindow, strikePrice, _optionType);
        _optionTokenId = optionHash << 8;

        // Store the option information
        optionStorage[_optionTokenId] = OptionStorage({
            writeAsset: assetInfo.writeAsset,
            writeAmount: assetInfo.writeAmount,
            writeDecimals: assetInfo.writeDecimals,
            exerciseDecimals: assetInfo.exerciseDecimals,
            optionType: _optionType,
            exerciseStyle: exStyle,
            exerciseAsset: assetInfo.exerciseAsset,
            exerciseAmount: assetInfo.exerciseAmount,
            assignmentSeed: uint32(uint256(keccak256(abi.encodePacked(optionHash, block.timestamp)))),
            exerciseWindow: LibOptionToken.toExerciseWindow(exerciseWindow)
        });

        if (optionAmount > 0) {
            // Mint the longs and shorts
            _mint(msg.sender, _optionTokenId, optionAmount);
            _mint(msg.sender, _optionTokenId + 1, optionAmount);

            // Track the ticket
            openTickets[_optionTokenId].push(Ticket({writer: msg.sender, shortAmount: optionAmount}));

            // Track the asset liability
            uint256 fullAmountForWrite = uint256(assetInfo.writeAmount) * optionAmount;
            _incrementAssetLiability(assetInfo.writeAsset, fullAmountForWrite);

            ///////// Interactions
            // Transfer in the write asset
            SafeTransferLib.safeTransferFrom(
                ERC20(assetInfo.writeAsset), msg.sender, address(this), fullAmountForWrite
            );
        }
        // Else the option is just created, with no options actually written and therefore no long/short tokens minted

        // Log events
        emit OptionCreated(
            _optionTokenId,
            baseAsset,
            quoteAsset,
            exerciseWindow[0],
            exerciseWindow[1],
            strikePrice,
            OptionType.CALL
        );
        if (optionAmount > 0) {
            // repeating this conditional logic, so that OptionCreated emits before OptionsWritten
            emit OptionsWritten(msg.sender, _optionTokenId, optionAmount);
        }

        ///////// Protocol Invariant
        // Check that the asset liabilities can be met
        _verifyAfter(assetInfo.writeAsset, assetInfo.exerciseAsset);
    }

    function write(uint256 _optionTokenId, uint80 optionAmount) public override {
        ///////// Function Requirements
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Check that the option is not expired
        uint32 expiryTimestamp = optionStored.exerciseWindow.expiryTimestamp;
        if (expiryTimestamp < block.timestamp) {
            revert OptionErrors.OptionExpired(_optionTokenId, expiryTimestamp);
        }

        // Check that the option is not exercised
        if (optionAmount == 0) {
            revert OptionErrors.WriteAmountZero();
        }

        // TODO check that amount is not greater than writeableAmount

        ///////// Effects // TODO refactor to DRY up Write effects and interactions
        // Mint the longs and shorts
        _mint(msg.sender, _optionTokenId, optionAmount);
        _mint(msg.sender, _optionTokenId + 1, optionAmount);

        // Track the ticket
        openTickets[_optionTokenId].push(Ticket({writer: msg.sender, shortAmount: optionAmount}));

        // Track the asset liability
        address writeAsset = optionStored.writeAsset;
        uint256 fullAmountForWrite = uint256(optionStored.writeAmount) * optionAmount;
        _incrementAssetLiability(writeAsset, fullAmountForWrite);

        ///////// Interactions
        // Transfer in the write asset
        SafeTransferLib.safeTransferFrom(ERC20(writeAsset), msg.sender, address(this), fullAmountForWrite);

        // Log events
        emit OptionsWritten(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        // Check that the asset liabilities can be met
        _verifyAfter(writeAsset, optionStored.exerciseAsset);
    }

    function batchWrite(uint256[] calldata optionTokenIds, uint80[] calldata optionAmounts) external {
        ///////// Function Requirements
        uint256 idsLength = optionTokenIds.length;
        // Check that the arrays are not empty
        if (idsLength == 0) {
            revert OptionErrors.BatchWriteArrayLengthZero();
        }
        // Check that the arrays are the same length
        if (idsLength != optionAmounts.length) {
            revert OptionErrors.BatchWriteArrayLengthMismatch();
        }

        ///////// Effects, Interactions, Protocol Invariant
        // Iterate through the arrays, writing on each option
        for (uint256 i = 0; i < idsLength;) {
            write(optionTokenIds[i], optionAmounts[i]);

            // An array can't have a total length larger than the max uint256 value
            unchecked {
                ++i;
            }
        }
    }

    function exercise(uint256 _optionTokenId, uint80 optionAmount) external override {
        ///////// Function Requirements
        // Check that the exercise amount is not zero
        if (optionAmount == 0) {
            revert OptionErrors.ExerciseAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Scope to avoid stack too deep
        {
            // Check that the option is within an exercise window
            uint32 exerciseTimestamp = optionStored.exerciseWindow.exerciseTimestamp;
            uint32 expiryTimestamp = optionStored.exerciseWindow.expiryTimestamp;
            if (block.timestamp < exerciseTimestamp || block.timestamp > expiryTimestamp) {
                revert OptionErrors.OptionNotWithinExerciseWindow(exerciseTimestamp, expiryTimestamp);
            }

            // Check that the caller holds sufficient longs to exercise
            uint256 optionBalance = balanceOf[msg.sender][_optionTokenId];
            if (optionAmount > optionBalance) {
                revert OptionErrors.ExerciseAmountExceedsLongBalance(optionAmount, optionBalance);
            }
        }

        ///////// Effects
        // Setup the assignment wheel // TEMP naive implementation
        uint80 amountNeedingAssignment = optionAmount;
        address writeAsset = optionStored.writeAsset;
        address exerciseAsset = optionStored.exerciseAsset;
        Ticket[] storage tickets = openTickets[_optionTokenId];
        uint32 assignmentSeed = optionStored.assignmentSeed;
        uint256 assignmentIndex = assignmentSeed % tickets.length;

        // Turn the wheel -- iterate pseudorandomly thru open tickets until the option amount is fully assigned
        while (amountNeedingAssignment > 0) {
            // Get the ticket
            AssignmentWheelTurnOutcome turnOutcome;
            Ticket storage ticket = tickets[assignmentIndex];
            address writer = ticket.writer;
            uint80 shortAmount = ticket.shortAmount;

            // TEMP
            // console2.log("--------- Top of assignment wheel turn");
            // console2.log("assignmentIndex                  ", assignmentIndex);
            // console2.log("optionAmount to be assigned      ", amountNeedingAssignment);
            // console2.log("shortAmount available in ticket  ", shortAmount);

            // Check if this ticket has sufficient shorts to cover the option amount needing assignment
            if (shortAmount > amountNeedingAssignment) {
                // This ticket is more than sufficient to cover
                turnOutcome = AssignmentWheelTurnOutcome.MORE_THAN_SUFFICIENT;

                // Decrement the amount of outstanding shorts on this ticket, but keep it open
                tickets[assignmentIndex].shortAmount -= shortAmount;
                shortAmount = amountNeedingAssignment;
            } else if (shortAmount == amountNeedingAssignment) {
                // This ticket is exactly sufficient to cover
                turnOutcome = AssignmentWheelTurnOutcome.EXACTLY_SUFFICIENT;

                // Remove the ticket from open tickets
                if (tickets.length == 1) {
                    tickets.pop();
                } else {
                    Ticket storage lastTicket = tickets[tickets.length - 1];
                    tickets[assignmentIndex] = lastTicket;
                    tickets.pop();
                }
            } else {
                // This ticket is insufficient to cover
                turnOutcome = AssignmentWheelTurnOutcome.INSUFFICIENT;

                // Remove the ticket from open tickets
                Ticket storage lastTicket = tickets[tickets.length - 1];
                tickets[assignmentIndex] = lastTicket;
                tickets.pop();
            }

            // Burn the writer's shorts and mint them assigned shorts
            _burn(writer, _optionTokenId + 1, shortAmount);
            _mint(writer, _optionTokenId + 2, shortAmount);

            // Log assignment event
            emit ShortsAssigned(writer, _optionTokenId, shortAmount);

            // If a sufficient amount of shorts have been assigned, the assignment process is complete
            if (turnOutcome != AssignmentWheelTurnOutcome.INSUFFICIENT) {
                break;
            }

            // Else, decrement the option amount still needing to be assigned and turn the wheel again
            amountNeedingAssignment -= shortAmount;
            assignmentIndex = assignmentSeed % tickets.length;
        }

        // Burn the holder's longs
        _burn(msg.sender, _optionTokenId, optionAmount);

        // Track the asset liabilities
        uint256 fullAmountForExercise = uint256(optionStored.exerciseAmount) * optionAmount;
        uint256 fullAmountForWrite = uint256(optionStored.writeAmount) * optionAmount;
        _incrementAssetLiability(exerciseAsset, fullAmountForExercise);
        _decrementAssetLiability(writeAsset, fullAmountForWrite);

        ///////// Interactions
        // Transfer in the exercise asset
        SafeTransferLib.safeTransferFrom(
            ERC20(exerciseAsset), msg.sender, address(this), fullAmountForExercise
        );

        // Transfer out the write asset
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, fullAmountForWrite);

        // Log exercise event
        emit OptionsExercised(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        // Check that the asset liabilities can be met
        _verifyAfter(writeAsset, exerciseAsset);
    }

    function netOff(uint256 _optionTokenId, uint80 optionsAmount)
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
