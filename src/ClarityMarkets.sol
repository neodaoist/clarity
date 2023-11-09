// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// TEMP
import {console2} from "forge-std/console2.sol";

// Interfaces
import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909MetadataURI} from "./interface/token/IERC6909MetadataURI.sol";
import {IERC20Minimal} from "./interface/token/IERC20Minimal.sol";

// Libraries
import {LibMetadata} from "./library/LibMetadata.sol";
import {LibPrice} from "./library/LibPrice.sol";
import {LibTime} from "./library/LibTime.sol";
import {LibToken} from "./library/LibToken.sol";
import {OptionErrors} from "./library/OptionErrors.sol";

// External Libraries
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

// Contracts
import {ERC6909Rebasing} from "./token/ERC6909Rebasing.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title clarity.markets
///
/// @author me.eth
/// @author you.eth
/// @author ?????????
///
/// @notice Clarity is a decentralized counterparty clearinghouse (DCP), for the writing,
/// transfer, and settlement of options and futures contracts on the Ethereum Virtual Machine
/// (EVM). The protocol is open source, open state, and open access. It has zero oracles, zero
/// governance, and zero custody. It is designed to be secure, composable, immutable, ergonomic,
/// and gas minimal.
contract ClarityMarkets is IOptionMarkets, IClarityCallback, ERC6909Rebasing {
    /////////

    using LibMetadata for string;
    using LibMetadata for bytes31;
    using LibPrice for uint8;
    using LibPrice for uint64;
    using LibPrice for uint256;
    using LibTime for uint32[];
    using LibTime for ExerciseStyle;
    using LibToken for uint248;
    using LibToken for uint256;
    using SafeCastLib for uint256;

    ///////// Private Structs

    // storage struct
    struct OptionStorage {
        // slot 0
        address writeAsset;
        uint64 writeAmount;
        // uint8 writeDecimals;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
        // slot 1
        address exerciseAsset;
        uint64 exerciseAmount;
        // uint8 exerciseDecimals;
        // slot 2
        OptionState optionState;
        ExerciseWindow exerciseWindow;
    }

    // storage struct
    struct OptionState {
        // slot 0
        uint64 amountWritten;
        uint64 amountNettedOff;
        uint64 amountExercised;
    }

    // storage struct
    struct AssetStorage {
        // slot 0
        bytes31 symbol;
        uint8 decimals;
    }

    // memory struct
    struct OptionClearingInfo {
        address writeAsset;
        uint8 writeDecimals;
        uint64 writeAmount;
        address exerciseAsset;
        uint8 exerciseDecimals;
        uint64 exerciseAmount;
    }

    // memory struct
    struct AssetMetadataInfo {
        string baseSymbol;
        uint8 baseDecimals;
        string quoteSymbol;
        uint8 quoteDecimals;
    }

    ///////// Public Constant/Immutable

    uint8 public constant OPTION_CONTRACT_SCALAR = 6;

    uint8 public constant MAXIMUM_ERC20_DECIMALS = 18;

    uint24 public constant MINIMUM_STRIKE_PRICE = 1e6;

    // max strike price = ((2**64 - 1) * 10**6
    uint104 public constant MAXIMUM_STRIKE_PRICE = 18_446_744_073_709_551_615e6;

    // max writable on any option contract ≈ 2**64 / 10**6 ≈ 1.8 trillion contracts
    uint64 public constant MAXIMUM_WRITABLE = 1_800_000_000_000e6;

    ///////// Private State

    /// @notice The ticker name for each instrument
    mapping(uint256 => string) private tickers;

    mapping(address => AssetStorage) public assetStorage;

    mapping(uint248 => OptionStorage) private optionStorage;

    mapping(address => uint256) private clearingLiabilities;

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
            baseAsset,
            quoteAsset,
            exerciseWindows,
            strikePrice,
            isCall ? OptionType.CALL : OptionType.PUT
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

    function option(uint256 _optionTokenId)
        external
        view
        returns (Option memory _option)
    {
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
            _option.strikePrice = optionStored.exerciseAmount.scaledUpFromClearingUnit();
            _option.optionType = OptionType.CALL;
        } else {
            _option.baseAsset = optionStored.exerciseAsset;
            _option.quoteAsset = writeAsset;
            _option.strikePrice = optionStored.writeAmount.scaledUpFromClearingUnit();
            _option.optionType = OptionType.PUT;
        }
        _option.exerciseWindow = optionStored.exerciseWindow;
        _option.exerciseStyle = optionStored.exerciseStyle;
    }

    function tokenType(uint256 tokenId) external view returns (TokenType _tokenType) {
        // Implicitly check that it is a valid position token type --
        // discard the upper 31B (the option hash) to get the lowest
        // 1B, then unsafely cast to PositionTokenType enum type
        _tokenType = TokenType(tokenId & 0xFF); // TODO replace with LibToken

        // TODO DRY up via refactoring into internal check function
        // Get the option from storage
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];

        // Check that the option has been created
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }
    }

    ///////// Option State Views

    function openInterest(uint256 _optionTokenId) external view returns (uint64 amount) {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Check that it is a long
        // TODO

        amount = optionStored.optionState.amountWritten
            - optionStored.optionState.amountNettedOff
            - optionStored.optionState.amountExercised;
    }

    function remainingWriteableAmount(uint256 _optionTokenId)
        external
        view
        returns (uint64 amount)
    {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(_optionTokenId);
        }

        // Check that it is a long
        // TODO

        amount = MAXIMUM_WRITABLE - optionStored.optionState.amountWritten;
    }

    ///////// Rebasing Token Views

    // TODO consider
    // if (block.timestamp > optionStored.exerciseWindow.expiryTimestamp) long/short amount = 0;

    function totalSupply(uint256 tokenId) public view returns (uint256 amount) {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }

        // Calculate the balance
        uint256 amountWritten = optionStored.optionState.amountWritten;
        uint256 amountNettedOff = optionStored.optionState.amountNettedOff;

        // If never any open interest for this created option, or everything written has been
        // netted off, the total supply will be zero
        if (amountWritten == 0 || amountWritten == amountNettedOff) {
            amount = 0;
        } else {
            TokenType _tokenType = tokenId.tokenType();
            uint256 amountExercised = optionStored.optionState.amountExercised;

            // If long or short, total supply is amount written minus amount netted off minus amount exercised
            if (_tokenType == TokenType.LONG || _tokenType == TokenType.SHORT) {
                amount = amountWritten - amountNettedOff - amountExercised;
            } else if (_tokenType == TokenType.ASSIGNED_SHORT) {
                // If assigned short, total supply is amount exercised
                amount = amountExercised;
            } else {
                revert OptionErrors.InvalidTokenType(tokenId); // should be unreachable
            }
        }
    }

    function balanceOf(address owner, uint256 tokenId)
        public
        view
        returns (uint256 amount)
    {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }

        // Calculate the balance
        uint256 amountWritten = optionStored.optionState.amountWritten;
        uint256 amountNettedOff = optionStored.optionState.amountNettedOff;

        // If never any open interest for this created option, or everything written has been
        // netted off, all balances will be zero
        if (amountWritten == 0 || amountWritten == amountNettedOff) {
            amount = 0;
        } else {
            TokenType _tokenType = tokenId.tokenType();
            uint256 amountExercised = optionStored.optionState.amountExercised;

            // If long, the balance is the actual amount held by owner
            if (_tokenType == TokenType.LONG) {
                amount = internalBalanceOf[owner][tokenId];
            } else if (_tokenType == TokenType.SHORT) {
                // If short, the balance is their proportional share of the unassigned shorts
                amount = (
                    internalBalanceOf[owner][tokenId]
                        * (amountWritten - amountNettedOff - amountExercised)
                ) / (amountWritten - amountNettedOff);
            } else if (_tokenType == TokenType.ASSIGNED_SHORT) {
                // If assigned short, the balance is their proportional share of the assigned shorts
                amount = (
                    internalBalanceOf[owner][tokenId.assignedShortToShort()]
                        * amountExercised
                ) / (amountWritten - amountNettedOff);
            } else {
                revert OptionErrors.InvalidTokenType(tokenId); // should be unreachable
            }
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
        uint256 assignedShortBalance =
            balanceOf(msg.sender, _optionTokenId.longToAssignedShort());

        _position = Position({
            amountLong: longBalance.safeCastTo64(),
            amountShort: shortBalance.safeCastTo64(),
            amountAssignedShort: assignedShortBalance.safeCastTo64()
        });

        // Calculate the magnitude
        magnitude = int160(
            int256(longBalance) - int256(shortBalance) - int256(assignedShortBalance)
        );
    }

    function positionNettableAmount(uint256 _optionTokenId)
        external
        view
        returns (uint64 optionAmount)
    {}

    function positionRedeemableAmount(uint256 _optionTokenId)
        external
        view
        returns (
            uint64 writeAssetAmount,
            uint32 writeAssetWhen,
            uint64 exerciseAssetAmount,
            uint32 exerciseAssetWhen
        )
    {}

    ///////// ERC6909MetadataModified

    /// @notice The name/symbol for each id
    function names(uint256 id) public view returns (string memory name) {
        name = tickers[id].tickerToSymbol(id.tokenType());
    }

    /// @notice The name/symbol for each id
    function symbols(uint256 id) public view returns (string memory symbol) {
        symbol = tickers[id].tickerToSymbol(id.tokenType());
    }

    /// @notice The number of decimals for each id (always OPTION_CONTRACT_SCALAR)
    function decimals(uint256 /*id*/ ) public pure returns (uint8 amount) {
        amount = OPTION_CONTRACT_SCALAR;
    }

    ///////// ERC6909MetadataURI

    function tokenURI(uint256 tokenId) public view returns (string memory uri) {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(tokenId);
        }

        // Build token URI parameters from option and assets
        AssetStorage storage writeAssetStored = assetStorage[optionStored.writeAsset];
        AssetStorage storage exerciseAssetStored =
            assetStorage[optionStored.exerciseAsset];

        if (optionStored.optionType == OptionType.CALL) {
            // If call, base asset is the write asset and quote asset is the exercise asset
            uri = LibMetadata.tokenURI(
                LibMetadata.TokenUriParameters({
                    ticker: "clr-WETH-FRAX-20OCT23-1750-C",
                    instrumentType: "Option",
                    instrumentSubtype: "Call",
                    tokenType: tokenId.toTokenTypeString(),
                    baseAssetSymbol: writeAssetStored.symbol.toString(),
                    quoteAssetSymbol: exerciseAssetStored.symbol.toString(),
                    expiry: optionStored.exerciseWindow.expiryTimestamp,
                    exerciseStyle: optionStored.exerciseStyle.toString(),
                    strikePrice: optionStored.exerciseAmount.fromClearingUnitToHumanReadable(
                        exerciseAssetStored.decimals
                        )
                })
            );
        } else {
            // If put, base asset is the exercise asset and quote asset is the write asset
            uri = LibMetadata.tokenURI(
                LibMetadata.TokenUriParameters({
                    ticker: "clr-WETH-FRAX-20OCT23-1750-P",
                    instrumentType: "Option",
                    instrumentSubtype: "Put",
                    tokenType: tokenId.toTokenTypeString(),
                    baseAssetSymbol: exerciseAssetStored.symbol.toString(),
                    quoteAssetSymbol: writeAssetStored.symbol.toString(),
                    expiry: optionStored.exerciseWindow.expiryTimestamp,
                    exerciseStyle: optionStored.exerciseStyle.toString(),
                    strikePrice: optionStored.writeAmount.fromClearingUnitToHumanReadable(
                        writeAssetStored.decimals
                        )
                })
            );
        }
    }

    ///////// Option Actions

    // Write

    function writeCall(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint64 optionAmount
    ) external returns (uint256 _optionTokenId) {
        _optionTokenId = _writeNew(
            baseAsset,
            quoteAsset,
            exerciseWindow,
            strikePrice,
            optionAmount,
            OptionType.CALL
        );
    }

    function writePut(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint64 optionAmount
    ) external returns (uint256 _optionTokenId) {
        _optionTokenId = _writeNew(
            baseAsset,
            quoteAsset,
            exerciseWindow,
            strikePrice,
            optionAmount,
            OptionType.PUT
        );
    }

    function _writeNew(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata exerciseWindow,
        uint256 strikePrice,
        uint64 optionAmount,
        OptionType _optionType
    ) private returns (uint256 _optionTokenId) {
        ///////// Function Requirements
        // Check that assets are valid
        if (baseAsset == quoteAsset) {
            revert OptionErrors.AssetsIdentical(baseAsset, quoteAsset);
        }
        // TODO address the potential danger of unsafe external calls
        AssetMetadataInfo memory assetInfo = AssetMetadataInfo({
            baseSymbol: IERC20Minimal(baseAsset).symbol(),
            baseDecimals: IERC20Minimal(baseAsset).decimals(),
            quoteSymbol: IERC20Minimal(quoteAsset).symbol(),
            quoteDecimals: IERC20Minimal(quoteAsset).decimals()
        });
        if (assetInfo.baseDecimals < OPTION_CONTRACT_SCALAR) {
            revert OptionErrors.AssetDecimalsOutOfRange(baseAsset, assetInfo.baseDecimals);
        }
        if (assetInfo.baseDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(baseAsset, assetInfo.baseDecimals);
        }
        if (assetInfo.quoteDecimals < OPTION_CONTRACT_SCALAR) {
            revert OptionErrors.AssetDecimalsOutOfRange(
                quoteAsset, assetInfo.quoteDecimals
            );
        }
        if (assetInfo.quoteDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert OptionErrors.AssetDecimalsOutOfRange(
                quoteAsset, assetInfo.quoteDecimals
            );
        }

        // Check that the exercise window is valid
        if (exerciseWindow.length != 2) {
            revert OptionErrors.ExerciseWindowMispaired();
        }
        if (exerciseWindow[0] == exerciseWindow[1]) {
            revert OptionErrors.ExerciseWindowZeroTime(
                exerciseWindow[0], exerciseWindow[1]
            );
        }
        if (exerciseWindow[0] > exerciseWindow[1]) {
            revert OptionErrors.ExerciseWindowMisordered(
                exerciseWindow[0], exerciseWindow[1]
            );
        }
        if (exerciseWindow[1] <= block.timestamp) {
            revert OptionErrors.ExerciseWindowExpiryPast(exerciseWindow[1]);
        }

        // Check that strike price is valid
        if (strikePrice < MINIMUM_STRIKE_PRICE) {
            revert OptionErrors.StrikePriceTooSmall(strikePrice);
        }
        if (strikePrice > MAXIMUM_STRIKE_PRICE) {
            revert OptionErrors.StrikePriceTooLarge(strikePrice);
        }

        // Check that option amount does not exceed max writable
        if (optionAmount > MAXIMUM_WRITABLE) {
            revert OptionErrors.WriteAmountTooLarge(optionAmount);
        }

        ///////// Effects

        // Scale down the strike price
        uint64 scaledStrikePrice = strikePrice.scaledDownToClearingUnit();

        // Calculate the write and exercise amounts for clearing purposes
        OptionClearingInfo memory clearingInfo; // memory struct to help avoid stack too deep
        if (_optionType == OptionType.CALL) {
            clearingInfo = OptionClearingInfo({
                writeAsset: baseAsset,
                writeDecimals: assetInfo.baseDecimals,
                writeAmount: assetInfo.baseDecimals.oneUnit(), // implicit 1 clearing unit
                exerciseAsset: quoteAsset,
                exerciseDecimals: assetInfo.quoteDecimals,
                exerciseAmount: scaledStrikePrice
            });
        } else {
            clearingInfo = OptionClearingInfo({
                writeAsset: quoteAsset,
                writeDecimals: assetInfo.quoteDecimals,
                writeAmount: scaledStrikePrice,
                exerciseAsset: baseAsset,
                exerciseDecimals: assetInfo.baseDecimals,
                exerciseAmount: assetInfo.baseDecimals.oneUnit() // implicit 1 clearing unit
            });
        }

        // Determine the exercise style
        ExerciseStyle exerciseStyle = exerciseWindow.determineExerciseStyle();

        // Generate the option hash and option token id
        uint248 optionHash = LibToken.paramsToHash(
            baseAsset, quoteAsset, exerciseWindow, strikePrice, _optionType
        );
        _optionTokenId = optionHash.hashToId();

        // Store the option
        optionStorage[optionHash] = OptionStorage({
            writeAsset: clearingInfo.writeAsset,
            writeAmount: clearingInfo.writeAmount,
            // writeDecimals: clearingInfo.writeDecimals,
            optionType: _optionType,
            exerciseStyle: exerciseStyle,
            exerciseAsset: clearingInfo.exerciseAsset,
            exerciseAmount: clearingInfo.exerciseAmount,
            // exerciseDecimals: clearingInfo.exerciseDecimals,
            optionState: OptionState({
                amountWritten: optionAmount,
                amountNettedOff: 0,
                amountExercised: 0
            }),
            exerciseWindow: exerciseWindow.toExerciseWindow()
        });

        // Store the option ticker
        tickers[_optionTokenId] = LibMetadata.paramsToTicker(
            assetInfo.baseSymbol,
            assetInfo.quoteSymbol,
            exerciseWindow[1],
            exerciseStyle,
            strikePrice.scaledDownToHumanReadable(assetInfo.quoteDecimals),
            _optionType
        );

        // Scope to avoid stack too deep
        {
            // Store the asset information, if not already stored
            AssetStorage storage baseAssetStored = assetStorage[baseAsset];
            if (baseAssetStored.decimals == 0) {
                baseAssetStored.symbol = assetInfo.baseSymbol.toBytes31();
                baseAssetStored.decimals = assetInfo.baseDecimals;
            }
            AssetStorage storage quoteAssetStored = assetStorage[quoteAsset];
            if (quoteAssetStored.decimals == 0) {
                quoteAssetStored.symbol = assetInfo.quoteSymbol.toBytes31();
                quoteAssetStored.decimals = assetInfo.quoteDecimals;
            }
        }

        // Log event (ideally this would be emitted in the Interactions section,
        // but emitting here affords DRYer business logic for write)
        emit OptionCreated(
            _optionTokenId,
            baseAsset,
            quoteAsset,
            exerciseWindow[0],
            exerciseWindow[1],
            strikePrice,
            OptionType.CALL
        );

        // If the option amount is non-zero, actually write some options
        if (optionAmount > 0) {
            _writeOptions(
                _optionTokenId,
                optionAmount,
                clearingInfo.writeAsset,
                clearingInfo.writeAmount
            );
        }
        // Else the option is just created, with no options actually written and
        // therefore no long or short tokens minted

        ///////// Protocol Invariant
        // Check that the clearing liabilities can be met
        _verifyAfter(clearingInfo.writeAsset, clearingInfo.exerciseAsset);
    }

    function _writeOptions(
        uint256 _optionTokenId,
        uint64 optionAmount,
        address writeAsset,
        uint64 writeAmount
    ) private {
        // Mint the longs and shorts
        _mint(msg.sender, _optionTokenId, optionAmount);
        _mint(msg.sender, _optionTokenId.longToShort(), optionAmount);

        // Track the asset liability
        uint256 fullAmountForWrite = uint256(writeAmount) * optionAmount;
        _incrementClearingLiability(writeAsset, fullAmountForWrite);

        ///////// Interactions
        // Transfer in the write asset
        SafeTransferLib.safeTransferFrom(
            ERC20(writeAsset), msg.sender, address(this), fullAmountForWrite
        );

        // Log event
        emit OptionsWritten(msg.sender, _optionTokenId, optionAmount);
    }

    function write(uint256 _optionTokenId, uint64 optionAmount) public override {
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

        // Check that amount is not greater than the remaining writable amount
        // (not DRY with remainingWritableAmount() but is more gas efficient)
        if (optionAmount > (MAXIMUM_WRITABLE - optionStored.optionState.amountWritten)) {
            revert OptionErrors.WriteAmountTooLarge(optionAmount);
        }

        ///////// Effects
        // Update the option state
        uint64 amountWritten = optionStored.optionState.amountWritten; // gas optimization
        optionStored.optionState.amountWritten = amountWritten + optionAmount;

        // Write the options
        address writeAsset = optionStored.writeAsset;
        _writeOptions(_optionTokenId, optionAmount, writeAsset, optionStored.writeAmount);

        ///////// Protocol Invariant
        // Check that the clearing liabilities can be met
        _verifyAfter(writeAsset, optionStored.exerciseAsset);
    }

    function batchWrite(
        uint256[] calldata optionTokenIds,
        uint64[] calldata optionAmounts
    ) external {
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
        for (uint256 i = 0; i < idsLength; i++) {
            write(optionTokenIds[i], optionAmounts[i]);
        }
    }

    // Net Off

    function netOff(uint256 _optionTokenId, uint64 optionAmount)
        external
        override
        returns (uint128 writeAssetNettedOff)
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
        uint64 amountNettedOff = optionStored.optionState.amountNettedOff; // gas optimization
        optionStored.optionState.amountNettedOff = amountNettedOff + optionAmount;

        // Burn the caller's longs and shorts
        _burn(msg.sender, _optionTokenId, optionAmount);
        _burn(msg.sender, _optionTokenId.longToShort(), optionAmount);

        // Track the clearing liabilities
        writeAssetNettedOff = uint128(optionStored.writeAmount) * uint128(optionAmount);
        _decrementClearingLiability(writeAsset, writeAssetNettedOff);

        ///////// Interactions
        // Transfer out the write asset // TODO add 1 wei gas optimization
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, writeAssetNettedOff);

        // Log net off event
        emit OptionsNettedOff(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        _verifyAfter(writeAsset, optionStored.exerciseAsset);
    }

    // Exercise

    function exercise(uint256 _optionTokenId, uint64 optionAmount) external override {
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
            if (block.timestamp < exerciseTimestamp || block.timestamp > expiryTimestamp)
            {
                revert OptionErrors.OptionNotWithinExerciseWindow(
                    exerciseTimestamp, expiryTimestamp
                );
            }

            // Check that the caller holds sufficient longs to exercise
            uint256 optionBalance = balanceOf(msg.sender, _optionTokenId);
            if (optionAmount > optionBalance) {
                revert OptionErrors.ExerciseAmountExceedsLongBalance(
                    optionAmount, optionBalance
                );
            }
        }

        ///////// Effects
        // Update the option state
        uint64 amountExercised = optionStored.optionState.amountExercised; // gas optimization
        optionStored.optionState.amountExercised = amountExercised + optionAmount;

        // Burn the holder's longs
        _burn(msg.sender, _optionTokenId, optionAmount);

        // Track the clearing liabilities
        address writeAsset = optionStored.writeAsset;
        address exerciseAsset = optionStored.exerciseAsset;
        uint256 fullAmountForExercise =
            uint256(optionStored.exerciseAmount) * optionAmount;
        uint256 fullAmountForWrite = uint256(optionStored.writeAmount) * optionAmount;
        _incrementClearingLiability(exerciseAsset, fullAmountForExercise);
        _decrementClearingLiability(writeAsset, fullAmountForWrite);

        ///////// Interactions
        // Transfer in the exercise asset
        SafeTransferLib.safeTransferFrom(
            ERC20(exerciseAsset), msg.sender, address(this), fullAmountForExercise
        );

        // Transfer out the write asset // TODO add 1 wei gas optimization
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, fullAmountForWrite);

        // Log exercise event
        emit OptionsExercised(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        // Check that the clearing liabilities can be met
        _verifyAfter(writeAsset, exerciseAsset);
    }

    // Redeem

    function redeem(uint256 shortTokenId)
        external
        override
        returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed)
    {
        ///////// Function Requirements
        // Check that the token type is a short
        if (shortTokenId.tokenType() != TokenType.SHORT) {
            revert OptionErrors.CanOnlyRedeemShort(shortTokenId);
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[shortTokenId.idToHash()];
        address writeAsset = optionStored.writeAsset;
        if (writeAsset == address(0)) {
            revert OptionErrors.OptionDoesNotExist(shortTokenId);
        }

        // Check that the caller holds shorts for this option
        uint256 nonVirtualShortBalance = internalBalanceOf[msg.sender][shortTokenId];
        if (nonVirtualShortBalance == 0) {
            revert OptionErrors.ShortBalanceZero(shortTokenId);
        }

        ///////// Effects
        // Determine the assignment status
        uint256 unassignedShortAmount = balanceOf(msg.sender, shortTokenId);
        uint256 assignedShortAmount =
            balanceOf(msg.sender, shortTokenId.shortToAssignedShort());

        // If fully assigned, redeem exercise asset and skip option expiry check
        if (unassignedShortAmount == 0) {
            exerciseAssetRedeemed =
                optionStored.exerciseAmount * uint128(assignedShortAmount);
        } else {
            // Perform additional check that the option is expired
            if (block.timestamp <= optionStored.exerciseWindow.expiryTimestamp) {
                revert OptionErrors.EarlyRedemptionOnlyIfFullyAssigned();
            }

            // Calculate the asset redemption amounts, based on assignment status
            // and caller's short balances
            writeAssetRedeemed = optionStored.writeAmount * uint128(unassignedShortAmount);
            exerciseAssetRedeemed =
                optionStored.exerciseAmount * uint128(assignedShortAmount);
        }

        // Burn all the caller's (non-virtual-rebasing) shorts
        _burn(msg.sender, shortTokenId, nonVirtualShortBalance);

        // Track the clearing liabilities
        address exerciseAsset = optionStored.exerciseAsset;
        if (writeAssetRedeemed > 0) {
            _decrementClearingLiability(writeAsset, writeAssetRedeemed);
        }
        if (exerciseAssetRedeemed > 0) {
            _decrementClearingLiability(exerciseAsset, exerciseAssetRedeemed);
        }

        ///////// Interactions
        // Transfer out the write asset and exercise, as needed // TODO add 1 wei gas optimization
        if (writeAssetRedeemed > 0) {
            SafeTransferLib.safeTransfer(
                ERC20(writeAsset), msg.sender, writeAssetRedeemed
            );
        }
        if (exerciseAssetRedeemed > 0) {
            SafeTransferLib.safeTransfer(
                ERC20(exerciseAsset), msg.sender, exerciseAssetRedeemed
            );
        }

        // Log event
        emit ShortsRedeemed(msg.sender, shortTokenId);

        ///////// Protocol Invariant
        _verifyAfter(writeAsset, exerciseAsset);
    }

    /////////

    // TODO add skim() as a Pool action, maybe not an Option action

    ///////// Callback

    function clarityCallback(Callback calldata _callback) external {}

    ///////// FREI-PI

    function _incrementClearingLiability(address asset, uint256 amount) internal {
        clearingLiabilities[asset] += amount;
    }

    function _decrementClearingLiability(address asset, uint256 amount) internal {
        clearingLiabilities[asset] -= amount;
    }

    function _verifyAfter(address writeAsset, address exerciseAsset) internal view {
        assert(
            IERC20Minimal(writeAsset).balanceOf(address(this))
                >= clearingLiabilities[writeAsset]
        );
        assert(
            IERC20Minimal(exerciseAsset).balanceOf(address(this))
                >= clearingLiabilities[exerciseAsset]
        );
    }
}
