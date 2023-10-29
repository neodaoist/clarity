// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {console2} from "forge-std/console2.sol"; // TEMP

import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909MetadataURI} from "./interface/external/IERC6909MetadataURI.sol";
import {IERC20Minimal} from "./interface/external/IERC20Minimal.sol";

import {LibToken} from "./library/LibToken.sol";
import {LibTime} from "./library/LibTime.sol";
import {OptionErrors} from "./library/OptionErrors.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {ERC6909Rebasing} from "./external/ERC6909Rebasing.sol";
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
contract ClarityMarkets is IOptionMarkets, IClarityCallback, IERC6909MetadataURI, ERC6909Rebasing {
    /////////

    using LibToken for uint256;
    using LibToken for uint248;
    using SafeCastLib for uint256;

    ///////// Private Structs

    struct OptionStorage {
        address writeAsset;
        uint64 writeAmount;
        uint8 writeDecimals;
        uint8 exerciseDecimals;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
        address exerciseAsset;
        uint64 exerciseAmount;
        uint32 assignmentSeed;
        ExerciseWindow exerciseWindow; // TODO add Bermudan support
        OptionState optionState;
    }

    struct OptionState {
        uint80 amountWritten;
        uint80 amountExercised;
        uint80 amountNettedOff;
    }

    struct ClearingAssetInfo {
        address writeAsset;
        uint8 writeDecimals;
        uint64 writeAmount;
        address exerciseAsset;
        uint8 exerciseDecimals;
        uint64 exerciseAmount;
    }

    ///////// Public Constant/Immutable

    uint8 public constant OPTION_CONTRACT_SCALAR = 6;
    uint8 public constant MAXIMUM_ERC20_DECIMALS = 18;
    uint104 public constant MAXIMUM_STRIKE_PRICE = 18446744073709551615000000; // ((2**64-1) * 10**6

    ///////// Private State

    mapping(uint248 => OptionStorage) private optionStorage;

    mapping(address => uint256) private assetLiabilities;

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
        uint248 optionHash = LibToken.paramsToHash(
            baseAsset, quoteAsset, exerciseWindows, strikePrice, isCall ? OptionType.CALL : OptionType.PUT
        );

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[optionHash];
        address writeAsset = optionStored.writeAsset;

        // Check that the option has been created
        if (writeAsset == address(0)) {
            // TODO revert
        }

        _optionTokenId = optionHash.hashToId();
    }

    function option(uint256 _optionTokenId) external view returns (Option memory _option) {
        // Check that it is a long
        // TODO

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
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
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            // TODO revert
        }

        _optionType = optionStored.optionType;
    }

    function exerciseStyle(uint256 _optionTokenId) external view returns (ExerciseStyle _exerciseStyle) {
        // TODO initial checks

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            // TODO revert
        }

        _exerciseStyle = optionStored.exerciseStyle;
    }

    function tokenType(uint256 tokenId) external view returns (TokenType _tokenType) {
        // Implicitly check that it is a valid position token type --
        // discard the upper 31B (the option hash) to get the lowest
        // 1B, then unsafely cast to PositionTokenType enum type
        _tokenType = TokenType(tokenId & 0xFF);

        // TODO DRY up via refactoring into internal check function
        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }
    }

    ///////// Option State Views

    function openInterest(uint256 _optionTokenId) external view returns (uint80 amount) {
        // Check that it is a long
        // TODO

        amount = totalSupply[_optionTokenId].safeCastTo80();
    }

    function writeableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

    function reedemableAmount(uint256 _optionTokenId) external view returns (uint80 amount) {}

    ///////// Rebasing Token Balance Views

    function balanceOf(address owner, uint256 tokenId) public view returns (uint256) {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }

        // Calculate the balance
        TokenType _tokenType = tokenId.tokenType();
        uint256 amountWritten = optionStored.optionState.amountWritten;
        uint256 amountExercised = optionStored.optionState.amountExercised;

        // If never any open interest for this created option, all balances will be zero
        if (amountWritten == 0 && amountExercised == 0) {
            return 0;
        }

        // If long, the balance is the actual amount held by owner
        if (_tokenType == TokenType.LONG) {
            return internalBalanceOf[owner][tokenId];
        } else if (_tokenType == TokenType.SHORT) {
            // If short, the balance is their proportional share of the unassigned shorts
            return (internalBalanceOf[owner][tokenId] * (amountWritten - amountExercised)) / amountWritten;
        } else if (_tokenType == TokenType.ASSIGNED_SHORT) {
            // If assigned short, the balance is their proportional share of the assigned shorts
            return
                (internalBalanceOf[owner][tokenId.assignedShortToShort()] * amountExercised) / amountWritten;
        } else {
            revert OptionErrors.InvalidPositionTokenType(tokenId);
        }
    }

    ///////// Option Position Views

    function position(uint256 _optionTokenId)
        external
        view
        returns (Position memory _position, int160 magnitude)
    {
        // Check that it is a long
        // TODO

        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            // TODO revert
        }

        // Get the position
        uint256 longBalance = balanceOf(msg.sender, _optionTokenId);
        uint256 shortBalance = balanceOf(msg.sender, _optionTokenId.longToShort());
        uint256 assignedShortBalance = balanceOf(msg.sender, _optionTokenId.longToAssignedShort());

        _position = Position({
            amountLong: longBalance.safeCastTo80(),
            amountShort: shortBalance.safeCastTo80(),
            amountAssignedShort: assignedShortBalance.safeCastTo80()
        });

        // Calculate the magnitude
        magnitude = int160(int256(longBalance) - int256(shortBalance) - int256(assignedShortBalance));
    }

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

    // TODO refactor to DRY up write business logic

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
        ExerciseStyle exStyle = LibTime.determineExerciseStyle(exerciseWindow);

        // Generate the optionTokenId
        uint248 optionHash =
            LibToken.paramsToHash(baseAsset, quoteAsset, exerciseWindow, strikePrice, _optionType);
        _optionTokenId = optionHash.hashToId();

        // Store the option information
        optionStorage[_optionTokenId.idToHash()] = OptionStorage({
            writeAsset: assetInfo.writeAsset,
            writeAmount: assetInfo.writeAmount,
            writeDecimals: assetInfo.writeDecimals,
            exerciseDecimals: assetInfo.exerciseDecimals,
            optionType: _optionType,
            exerciseStyle: exStyle,
            exerciseAsset: assetInfo.exerciseAsset,
            exerciseAmount: assetInfo.exerciseAmount,
            assignmentSeed: uint32(bytes4(keccak256(abi.encodePacked(optionHash, block.timestamp)))),
            exerciseWindow: LibTime.toExerciseWindow(exerciseWindow),
            optionState: OptionState({amountWritten: optionAmount, amountExercised: 0, amountNettedOff: 0})
        });

        if (optionAmount > 0) {
            // Mint the longs and shorts
            _mint(msg.sender, _optionTokenId, optionAmount);
            _mint(msg.sender, _optionTokenId.longToShort(), optionAmount);

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
        // Check that the option amount is not zero
        if (optionAmount == 0) {
            revert OptionErrors.WriteAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Check that the option is not expired
        uint32 expiryTimestamp = optionStored.exerciseWindow.expiryTimestamp;
        if (expiryTimestamp < block.timestamp) {
            revert OptionErrors.OptionExpired(_optionTokenId, expiryTimestamp);
        }

        // TODO check that amount is not greater than writeableAmount

        ///////// Effects
        // Update the option state
        optionStored.optionState.amountWritten += optionAmount;

        // Mint the longs and shorts
        _mint(msg.sender, _optionTokenId, optionAmount);
        _mint(msg.sender, _optionTokenId.longToShort(), optionAmount);

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
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        //  Check that the position token type is a long
        // TODO

        // Scope to avoid stack too deep
        {
            // Check that the option is within an exercise window
            uint32 exerciseTimestamp = optionStored.exerciseWindow.exerciseTimestamp;
            uint32 expiryTimestamp = optionStored.exerciseWindow.expiryTimestamp;
            if (block.timestamp < exerciseTimestamp || block.timestamp > expiryTimestamp) {
                revert OptionErrors.OptionNotWithinExerciseWindow(exerciseTimestamp, expiryTimestamp);
            }

            // Check that the caller holds sufficient longs to exercise
            uint256 optionBalance = balanceOf(msg.sender, _optionTokenId);
            if (optionAmount > optionBalance) {
                revert OptionErrors.ExerciseAmountExceedsLongBalance(optionAmount, optionBalance);
            }
        }

        ///////// Effects
        // Update the option state
        optionStored.optionState.amountExercised += optionAmount;

        // // Setup the assignment wheel // TEMP naive implementation
        // uint80 amountNeedingAssignment = optionAmount;
        address writeAsset = optionStored.writeAsset;
        address exerciseAsset = optionStored.exerciseAsset;
        // Ticket[] storage tickets = openTickets[_optionTokenId];
        // uint32 assignmentSeed = optionStored.assignmentSeed;
        // uint256 assignmentIndex = assignmentSeed % tickets.length;

        // // Turn the wheel -- iterate pseudorandomly thru open tickets until the option amount is fully assigned
        // while (amountNeedingAssignment > 0) {
        //     // Get the ticket
        //     AssignmentWheelTurnOutcome turnOutcome;
        //     Ticket storage ticket = tickets[assignmentIndex];
        //     address writer = ticket.writer;
        //     uint80 shortAmount = ticket.shortAmount;

        //     // TEMP
        //     // console2.log("--------- Top of assignment wheel turn");
        //     // console2.log("assignmentIndex                  ", assignmentIndex);
        //     // console2.log("optionAmount to be assigned      ", amountNeedingAssignment);
        //     // console2.log("shortAmount available in ticket  ", shortAmount);

        //     // Check if this ticket has sufficient shorts to cover the option amount needing assignment
        //     if (shortAmount > amountNeedingAssignment) {
        //         // This ticket is more than sufficient to cover
        //         turnOutcome = AssignmentWheelTurnOutcome.MORE_THAN_SUFFICIENT;

        //         // Decrement the amount of outstanding shorts on this ticket, but keep it open
        //         tickets[assignmentIndex].shortAmount -= shortAmount;
        //         shortAmount = amountNeedingAssignment;
        //     } else if (shortAmount == amountNeedingAssignment) {
        //         // This ticket is exactly sufficient to cover
        //         turnOutcome = AssignmentWheelTurnOutcome.EXACTLY_SUFFICIENT;

        //         // Remove the ticket from open tickets
        //         if (tickets.length == 1) {
        //             tickets.pop();
        //         } else {
        //             Ticket storage lastTicket = tickets[tickets.length - 1];
        //             tickets[assignmentIndex] = lastTicket;
        //             tickets.pop();
        //         }
        //     } else {
        //         // This ticket is insufficient to cover
        //         turnOutcome = AssignmentWheelTurnOutcome.INSUFFICIENT;

        //         // Remove the ticket from open tickets
        //         Ticket storage lastTicket = tickets[tickets.length - 1];
        //         tickets[assignmentIndex] = lastTicket;
        //         tickets.pop();
        //     }

        //     // Burn the writer's shorts and mint them assigned shorts
        //     _burn(writer, _optionTokenId.longToShort(), shortAmount);
        //     _mint(writer, _optionTokenId.longToAssignedShort(), shortAmount);

        //     // Log assignment event
        //     emit ShortsAssigned(writer, _optionTokenId, shortAmount);

        //     // If a sufficient amount of shorts have been assigned, the assignment process is complete
        //     if (turnOutcome != AssignmentWheelTurnOutcome.INSUFFICIENT) {
        //         break;
        //     }

        //     // Else, decrement the option amount still needing to be assigned and turn the wheel again
        //     amountNeedingAssignment -= shortAmount;
        //     assignmentIndex = assignmentSeed % tickets.length;
        // }

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

    function netOff(uint256 _optionTokenId, uint80 optionAmount)
        external
        override
        returns (uint256 writeAssetNettedOff)
    {
        ///////// Function Requirements
        // Check that the exercise amount is not zero
        if (optionAmount == 0) {
            revert OptionErrors.ExerciseAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        address writeAsset = optionStored.writeAsset;
        if (writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Check that the position token type is a long
        // TODO

        // Check that the caller holds sufficient longs and shorts to net off
        if (optionAmount > balanceOf(msg.sender, _optionTokenId)) {
            revert OptionErrors.InsufficientLongBalance(_optionTokenId, optionAmount);
        }
        if (optionAmount > balanceOf(msg.sender, _optionTokenId.longToShort())) {
            revert OptionErrors.InsufficientShortBalance(_optionTokenId, optionAmount);
        }

        ///////// Effects
        // Update option state
        optionStored.optionState.amountNettedOff += optionAmount;

        // Burn the caller's longs and shorts
        _burn(msg.sender, _optionTokenId, optionAmount);
        _burn(msg.sender, _optionTokenId.longToShort(), optionAmount);

        // Track the asset liabilities
        writeAssetNettedOff = optionStored.writeAmount * optionAmount;
        _decrementAssetLiability(writeAsset, writeAssetNettedOff);

        ///////// Interactions
        // Transfer out the write asset
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, writeAssetNettedOff);

        // Log net off event
        emit OptionsNettedOff(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        _verifyAfter(writeAsset, optionStored.exerciseAsset);
    }

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
