// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// TEMP
import {console2} from "forge-std/console2.sol";

// Interfaces
import {IClearingPool} from "./interface/IClearingPool.sol";
import {IOptionMarkets} from "./interface/IOptionMarkets.sol";
import {IPosition} from "./interface/IPosition.sol";
import {IClarityCallback} from "./interface/IClarityCallback.sol";
import {IERC6909MetadataURI} from "./interface/token/IERC6909MetadataURI.sol";

// External Interfaces
import {IERC20Minimal} from "./interface/token/IERC20Minimal.sol";

// Libraries
import {LibMath} from "./library/LibMath.sol";
import {LibMetadata} from "./library/LibMetadata.sol";
import {LibOption} from "./library/LibOption.sol";
import {LibPosition} from "./library/LibPosition.sol";

// External Libraries
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

// Contracts
import {ERC6909Rebasing} from "./token/ERC6909Rebasing.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title Clarity.markets
///
/// @author me.eth
/// @author you.eth
/// @author ?????????
///
/// @notice Clarity is a decentralized counterparty clearinghouse (DCP), for the writing,
/// transfer, and settlement of options and futures contracts on the Ethereum Virtual
/// Machine (EVM). The protocol is open source, open state, and open access. It has zero
/// oracles, zero governance, and zero custody. It is designed to be secure, composable,
/// immutable, ergonomic, and gas minimal.
contract ClarityMarkets is
    IClearingPool,
    IOptionMarkets,
    IPosition,
    IClarityCallback,
    ERC6909Rebasing
{
    /////////

    using LibMath for uint8;
    using LibMath for uint64;
    using LibMath for uint256;

    using LibMetadata for string;
    using LibMetadata for bytes31;

    using LibOption for uint32;
    using LibOption for uint64;
    using LibOption for uint256;
    using LibOption for OptionType;
    using LibOption for ExerciseStyle;

    using LibPosition for uint248;
    using LibPosition for uint256;
    using LibPosition for TokenType;

    using SafeCastLib for uint256;

    ///////// Structs

    /// @dev Storage struct for the core information of an option
    struct OptionStorage {
        // slot 0
        address writeAsset;
        uint64 writeAmount;
        OptionType optionType;
        ExerciseStyle exerciseStyle;
        // slot 1
        address exerciseAsset;
        uint64 exerciseAmount;
        uint32 expiry;
        // slot 2
        OptionState optionState;
    }

    /// @dev Storage struct for the state of an option
    struct OptionState {
        // slot 0
        uint64 amountWritten;
        uint64 amountNettedOff;
        uint64 amountExercised;
    }

    /// @dev Storage struct for the symbol and decimals of an ERC20 asset
    struct AssetMetadataStorage {
        // slot 0
        bytes31 symbol;
        uint8 decimals;
    }

    /// @dev Memory struct to avoid stack too deep, when writing a new option
    struct OptionClearingInfo {
        address writeAsset;
        uint8 writeDecimals;
        uint64 writeAmount;
        address exerciseAsset;
        uint8 exerciseDecimals;
        uint64 exerciseAmount;
    }

    /// @dev Memory struct to avoid stack too deep, when writing a derivative on a new
    /// ERC20 asset
    struct AssetMetadataInfo {
        string baseSymbol;
        uint8 baseDecimals;
        string quoteSymbol;
        uint8 quoteDecimals;
    }

    ///////// Public Constants

    /// @notice The number of decimals for Clarity derivatives tokens
    uint8 public constant CONTRACT_SCALAR = 6;

    /// @notice The minimum supported number of decimals for ERC20 assets
    uint8 public constant MINIMUM_ERC20_DECIMALS = 6;

    /// @notice The maximum supported number of decimals for ERC20 assets
    uint8 public constant MAXIMUM_ERC20_DECIMALS = 18;

    /// @notice The maximum expiry timestamp for a Clarity derivative
    uint32 public constant MAXIMUM_EXPIRY = 4_294_967_295;

    /// @notice The minimum strike price for a Clarity derivative
    uint24 public constant MINIMUM_STRIKE = 1e6;

    /// @notice The maximum strike price for a Clarity derivative
    uint104 public constant MAXIMUM_STRIKE = 18_446_744_073_709_551_615e6;

    /// @notice The maximum amount that can be written for a Clarity derivative
    uint64 public constant MAXIMUM_WRITABLE = 18_446_744_073_709_551_615;

    ///////// Private State

    /// @dev The shortened ticker name for each instrument
    mapping(uint248 => string) private tickers;

    /// @dev The information and state for each option
    mapping(uint248 => OptionStorage) private optionStorage;

    /// @dev The symbol and decimals of each ERC20 asset for which a derivative has been
    /// written
    mapping(address => AssetMetadataStorage) public assetMetadataStorage; // TODO private

    /// @dev The clearing liabilities of each ERC20 asset for which a derivative has been
    /// written
    mapping(address => uint256) private clearingLiabilities;

    ///////// Views

    // Option

    // TODO make this not revert, add info on best practice to check for empty

    // / @notice Returns the token id for a given option, if it has been written already,
    // / otherwise reverts
    // / @param baseAsset The base asset of the option (typically the volatile asset in a
    // / pair)
    // / @param quoteAsset The quote asset of the option (the asset in which the strike
    // / price is denominated)
    // / @param exerciseWindow The timeframe(s) during which this option can be exercised,
    // / inclusive
    // / @param strike The strike price of the option, denominated in the quote asset
    // / @param isCall Whether the option is a call or a put
    // / @return _optionTokenId The token id of the option
    function optionTokenId(
        address baseAsset,
        address quoteAsset,
        uint32[] calldata expiries,
        uint256 strike,
        uint8 optionType,
        uint8 exerciseStyle
    ) external view returns (uint256 _optionTokenId) {
        // Hash the option
        uint248 optionHash;
        if (exerciseStyle == uint8(ExerciseStyle.BERMUDAN)) {
            // TODO
        } else {
            optionHash = LibOption.paramsToHash(
                baseAsset,
                quoteAsset,
                expiries[0],
                strike,
                OptionType(optionType),
                ExerciseStyle(exerciseStyle)
            );
        }

        // Check that the option has been created
        OptionStorage storage optionStored = optionStorage[optionHash];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(optionHash.hashToId());
        }

        _optionTokenId = optionHash.hashToId();
    }

    /// @notice Returns the core information of a given option, if it has been written,
    /// otherwise reverts
    /// @param tokenId The token id of the option (accepts long, short, or assigned short)
    /// @return _option The core option information
    function option(uint256 tokenId) external view returns (Option memory _option) {
        // Check that the option has been created
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        address writeAsset = optionStored.writeAsset;
        if (writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        // Build the user-friendly Option struct
        if (optionStored.optionType == OptionType.CALL) {
            _option = Option({
                baseAsset: writeAsset,
                quoteAsset: optionStored.exerciseAsset,
                strike: optionStored.exerciseAmount.clearingScaledUpToActualStrike(),
                expiry: optionStored.expiry,
                optionType: OptionType.CALL,
                exerciseStyle: optionStored.exerciseStyle
            });
        } else {
            _option = Option({
                baseAsset: optionStored.exerciseAsset,
                quoteAsset: writeAsset,
                strike: optionStored.writeAmount.clearingScaledUpToActualStrike(),
                expiry: optionStored.expiry,
                optionType: OptionType.PUT,
                exerciseStyle: optionStored.exerciseStyle
            });
        }
    }

    // Position

    /// @notice Returns the token type for a given token (either long, short, or assigned
    /// short)
    /// @param tokenId The token id of the token
    /// @return _tokenType The token type of the token
    function tokenType(uint256 tokenId) external view returns (TokenType _tokenType) {
        // Implicitly check that it is a valid position token type --
        // discard the upper 31B (the option hash) to get the lowest
        // 1B, then unsafely cast to PositionTokenType enum type
        _tokenType = TokenType(tokenId & 0xFF); // TODO replace with LibToken

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }
    }

    /// @notice Returns the position of a given token holder for a given option (current
    /// balance of long, short, and assigned short, along with the overall magnitude of
    /// the position based on amount of open longs and open shorts)
    /// @param tokenId The token id of the option (accepts long, short, or assigned short)
    /// @return _position The position of the token holder (long, short, assigned short)
    /// @return magnitude The magnitude of the open longs and shorts
    function position(uint256 tokenId)
        external
        view
        returns (Position memory _position, int160 magnitude)
    {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        // Generate the token ids for the option, short, and assigned short
        uint256 _optionTokenId;
        uint256 shortTokenId;
        uint256 assignedShortTokenId;

        if (tokenId.tokenType() == TokenType.LONG) {
            _optionTokenId = tokenId;
            shortTokenId = tokenId.longToShort();
            assignedShortTokenId = tokenId.longToAssignedShort();
        } else if (tokenId.tokenType() == TokenType.SHORT) {
            _optionTokenId = tokenId.shortToLong();
            shortTokenId = tokenId;
            assignedShortTokenId = tokenId.shortToAssignedShort();
        } else if (tokenId.tokenType() == TokenType.ASSIGNED_SHORT) {
            _optionTokenId = tokenId.assignedShortToLong();
            shortTokenId = tokenId.assignedShortToShort();
            assignedShortTokenId = tokenId;
        } else {
            revert(); // should be unreachable
        }

        // Determine the position
        OptionState storage optionState = optionStored.optionState;
        uint256 longBalance = _balanceOf(msg.sender, _optionTokenId, optionState);
        uint256 shortBalance =
            _balanceOf(msg.sender, _optionTokenId.longToShort(), optionState);
        uint256 assignedShortBalance =
            _balanceOf(msg.sender, _optionTokenId.longToAssignedShort(), optionState);

        _position = Position({
            amountLong: longBalance.safeCastTo64(),
            amountShort: shortBalance.safeCastTo64(),
            amountAssignedShort: assignedShortBalance.safeCastTo64()
        });

        // Calculate the magnitude
        magnitude = int160(
            int256(longBalance) - int256(shortBalance) - int256(assignedShortBalance) // TODO
        );
    }

    /// @notice Returns the amount of options that can be netted off for a given token
    /// holder and option
    /// @param _optionTokenId The token id of the option
    /// @return optionAmount The amount of options that can be netted off
    function positionNettableAmount(uint256 _optionTokenId)
        external
        pure
        returns (uint64 optionAmount)
    {
        revert("not yet impl");
    }

    /// @notice Returns the amount of underlying asset that can be redeemed for a given
    /// token holder and option
    /// @param shortTokenId The token id of the short
    /// @return writeAssetAmount The amount of write asset that can be redeemed
    /// @return writeAssetWhen The timestamp on or after which the write asset can be
    /// redeemed
    /// @return exerciseAssetAmount The amount of exercise asset that can be redeemed
    /// @return exerciseAssetWhen The timestamp on or after which the exercise asset can
    /// be redeemed
    function positionRedeemableAmount(uint256 shortTokenId)
        external
        view
        returns (
            uint64 writeAssetAmount,
            uint32 writeAssetWhen,
            uint64 exerciseAssetAmount,
            uint32 exerciseAssetWhen
        )
    {
        revert("not yet impl");
    }

    // ERC6909 Rebasing

    /// @notice Returns the total supply of a given token id
    /// TODO explain token encoding
    /// TODO explain rebasing
    /// @param tokenId The token id of the token
    /// @return amount The total supply of the token
    function totalSupply(uint256 tokenId) public view returns (uint256 amount) {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        // Calculate the balance
        uint256 amountWritten = optionStored.optionState.amountWritten;
        uint256 amountNettedOff = optionStored.optionState.amountNettedOff;

        // If never any open interest for this created option, or everything written has
        // been netted off, the total supply will be zero
        if (amountWritten == 0 || amountWritten == amountNettedOff) {
            amount = 0;
        } else {
            TokenType _tokenType = tokenId.tokenType();
            uint256 amountExercised = optionStored.optionState.amountExercised;

            // If long or short, total supply is amount written minus amount netted off
            // minus amount exercised
            if (_tokenType == TokenType.LONG || _tokenType == TokenType.SHORT) {
                amount = amountWritten - amountNettedOff - amountExercised;
            } else if (_tokenType == TokenType.ASSIGNED_SHORT) {
                // If assigned short, total supply is amount exercised
                amount = amountExercised;
            } else {
                revert(); // should be unreachable
            }
        }
    }

    /// @notice Returns the balance of a given token id for a given owner
    /// TODO explain rebasing
    /// @param owner The owner of the token
    /// @param tokenId The token id of the token
    /// @return amount The balance of the token for the owner
    function balanceOf(address owner, uint256 tokenId)
        public
        view
        returns (uint256 amount)
    {
        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[tokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        amount = _balanceOf(owner, tokenId, optionStored.optionState);
    }

    /// @dev Returns the balance of a given token id for a given owner, called by
    /// balanceOf(), position(), netOff(), exerciseLongs(), and redeemShorts() -- being
    /// separate from balanceOf() allows gas savings by not repeatedly checking
    /// that the option exists
    /// @param owner The owner of the token
    /// @param tokenId The token id of the token
    /// @param optionState The state of the option
    /// @return amount The balance of the token for the owner
    function _balanceOf(address owner, uint256 tokenId, OptionState storage optionState)
        private
        view
        returns (uint256 amount)
    {
        // Calculate the balance
        uint256 amountWritten = optionState.amountWritten;
        uint256 amountNettedOff = optionState.amountNettedOff;

        // If never any open interest for this created option, or everything written has
        // been netted off, all balances will be zero
        if (amountWritten == 0 || amountWritten == amountNettedOff) {
            amount = 0;
        } else {
            TokenType _tokenType = tokenId.tokenType();
            uint256 amountExercised = optionState.amountExercised;

            // If long, the balance is the actual amount held by owner
            if (_tokenType == TokenType.LONG) {
                amount = internalBalanceOf[owner][tokenId];
            } else if (_tokenType == TokenType.SHORT) {
                // If short, the balance is their proportional share of the unassigned
                // shorts
                amount = (
                    internalBalanceOf[owner][tokenId]
                        * (amountWritten - amountNettedOff - amountExercised)
                ) / (amountWritten - amountNettedOff);
            } else if (_tokenType == TokenType.ASSIGNED_SHORT) {
                // If assigned short, the balance is their proportional share of the
                // assigned shorts
                amount = (
                    internalBalanceOf[owner][tokenId.assignedShortToShort()]
                        * amountExercised
                ) / (amountWritten - amountNettedOff);
            } else {
                revert(); // should be unreachable
            }
        }
    }

    // ERC6909MetadataModified

    /// @notice The name/symbol for each token id
    /// TODO explain ticker scheme
    function names(uint256 tokenId) public view returns (string memory name) {
        name =
            tickers[tokenId.idToHash()].tickerToFullTicker(tokenId.tokenType().toString());
    }

    /// @notice The name/symbol for each token id
    function symbols(uint256 tokenId) public view returns (string memory symbol) {
        symbol =
            tickers[tokenId.idToHash()].tickerToFullTicker(tokenId.tokenType().toString());
    }

    /// @notice The number of decimals for each token id (always equal to CONTRACT_SCALAR)
    function decimals(uint256 /*tokenId*/ ) public pure returns (uint8 amount) {
        amount = CONTRACT_SCALAR;
    }

    // ERC6909MetadataURI

    /// @notice The URI for each token id
    /// TODO explain JSON and SVG generation
    /// @param tokenId The token id of the token
    /// @return uri The URI for the token
    function tokenURI(uint256 tokenId) public view returns (string memory uri) {
        // Check that the option exists
        uint248 optionHash = tokenId.idToHash();
        OptionStorage storage optionStored = optionStorage[optionHash];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        // Build the token URI parameters from option, assets, and ticker
        // (If call, base asset is the write asset and quote asset is the exercise asset;
        // if put, base asset is the exercise asset and quote asset is the write asset)

        AssetMetadataStorage storage baseAssetStored;
        AssetMetadataStorage storage quoteAssetStored;
        uint64 quoteAmount;

        if (optionStored.optionType == OptionType.CALL) {
            baseAssetStored = assetMetadataStorage[optionStored.writeAsset];
            quoteAssetStored = assetMetadataStorage[optionStored.exerciseAsset];
            quoteAmount = optionStored.exerciseAmount;
        } else {
            baseAssetStored = assetMetadataStorage[optionStored.exerciseAsset];
            quoteAssetStored = assetMetadataStorage[optionStored.writeAsset];
            quoteAmount = optionStored.writeAmount;
        }

        uri = LibMetadata.tokenURI(
            LibMetadata.TokenUriParameters({
                ticker: tickers[optionHash],
                instrumentSubtype: optionStored.optionType.toString(),
                tokenType: tokenId.tokenType().toString(),
                baseAssetSymbol: baseAssetStored.symbol.toString(),
                quoteAssetSymbol: quoteAssetStored.symbol.toString(),
                expiry: optionStored.expiry.toString(),
                exerciseStyle: optionStored.exerciseStyle.toString(),
                strike: quoteAmount.clearingScaledDownToHumanReadableStrike(
                    quoteAssetStored.decimals
                    ).toString()
            })
        );
    }

    ///////// Actions

    // ERC6909 Transfer

    /// @notice Transfers a given amount of a given token from the caller to the receiver
    /// TODO explain restrictions
    /// @param receiver The receiver of the token
    /// @param tokenId The token id of the token
    /// @param amount The amount of the token to transfer
    /// @return Whether the transfer succeeded
    function transfer(address receiver, uint256 tokenId, uint256 amount)
        public
        override
        returns (bool)
    {
        ///////// Function Requirements
        _checkTransferFunctionRequirements(tokenId);

        ///////// Continue to Effects and Interactions
        return super.transfer(receiver, tokenId, amount);
    }

    /// @notice Transfers a given amount of a given token from the sender to the receiver
    /// TODO explain restrictions
    /// @param sender The sender of the token
    /// @param receiver The receiver of the token
    /// @param tokenId The token id of the token
    /// @param amount The amount of the token to transfer
    /// @return Whether the transfer succeeded
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    ) public override returns (bool) {
        ///////// Function Requirements
        _checkTransferFunctionRequirements(tokenId);

        ///////// Continue to Effects and Interactions
        return super.transferFrom(sender, receiver, tokenId, amount);
    }

    /// @dev Function requirements for transferring tokens, called by transfer() and
    /// transferFrom()
    function _checkTransferFunctionRequirements(uint256 tokenId) private view {
        // Check that the option exists
        uint248 optionHash = tokenId.idToHash();
        OptionStorage storage optionStored = optionStorage[optionHash];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(tokenId);
        }

        // Check that token is long or short
        TokenType _tokenType = tokenId.tokenType();
        if (_tokenType != TokenType.LONG && _tokenType != TokenType.SHORT) {
            revert CanOnlyTransferLongOrShort();
        }

        // If short, check that the option has been not assigned at all
        if (_tokenType == TokenType.SHORT && optionStored.optionState.amountExercised > 0)
        {
            revert CanOnlyTransferShortIfUnassigned();
        }
    }

    ///////// Option Actions

    // Write

    /// @notice Writes a new call option, minting long and short tokens for the writer
    /// TODO explain reverts and how to write for an option that already exists
    /// @param baseAsset The base asset of the option (typically the volatile asset in a
    /// pair)
    /// @param quoteAsset The quote asset of the option (the asset in which the strike is
    /// denominated)
    /// @param expiry TODO
    /// @param strike The strike price of the option, denominated in the quote asset
    /// @param allowEarlyExercise TODO
    /// @param optionAmount The amount of options to write
    /// @return _optionTokenId The token id of the option
    function writeNewCall(
        address baseAsset,
        address quoteAsset,
        uint32 expiry,
        uint256 strike,
        bool allowEarlyExercise,
        uint64 optionAmount
    ) external returns (uint256 _optionTokenId) {
        _optionTokenId = _writeNew(
            baseAsset,
            quoteAsset,
            expiry,
            strike,
            allowEarlyExercise ? ExerciseStyle.AMERICAN : ExerciseStyle.EUROPEAN,
            optionAmount,
            OptionType.CALL
        );
    }

    /// @notice Writes a new put option, minting long and short tokens for the writer
    /// TODO explain reverts and how to write for an option that already exists
    /// TODO add info on rounding
    /// @param baseAsset The base asset of the option (typically the volatile asset in a
    /// pair)
    /// @param quoteAsset The quote asset of the option (the asset in which the strike is
    /// denominated)
    /// @param expiry TODO
    /// @param strike The strike price of the option, denominated in the quote asset
    /// @param allowEarlyExercise TODO
    /// @param optionAmount The amount of options to write
    /// @return _optionTokenId The token id of the option
    function writeNewPut(
        address baseAsset,
        address quoteAsset,
        uint32 expiry,
        uint256 strike,
        bool allowEarlyExercise,
        uint64 optionAmount
    ) external returns (uint256 _optionTokenId) {
        _optionTokenId = _writeNew(
            baseAsset,
            quoteAsset,
            expiry,
            strike,
            allowEarlyExercise ? ExerciseStyle.AMERICAN : ExerciseStyle.EUROPEAN,
            optionAmount,
            OptionType.PUT
        );
    }

    /// @dev Function requirements, effects, interactions, and protocol invariant for
    /// writing a new option, called by writeNewCall() and writeNewPut()
    function _writeNew(
        address baseAsset,
        address quoteAsset,
        uint32 expiry,
        uint256 strike,
        ExerciseStyle exerciseStyle,
        uint64 optionAmount,
        OptionType _optionType
    ) private returns (uint256 _optionTokenId) {
        ///////// Function Requirements
        // Check that assets are valid
        if (baseAsset == quoteAsset) {
            revert AssetsIdentical(baseAsset, quoteAsset);
        }
        // TODO address the potential danger of unsafe external calls
        AssetMetadataInfo memory assetInfo = AssetMetadataInfo({
            baseSymbol: IERC20Minimal(baseAsset).symbol(),
            baseDecimals: IERC20Minimal(baseAsset).decimals(),
            quoteSymbol: IERC20Minimal(quoteAsset).symbol(),
            quoteDecimals: IERC20Minimal(quoteAsset).decimals()
        });
        if (assetInfo.baseDecimals < MINIMUM_ERC20_DECIMALS) {
            revert AssetDecimalsOutOfRange(baseAsset, assetInfo.baseDecimals);
        }
        if (assetInfo.baseDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert AssetDecimalsOutOfRange(baseAsset, assetInfo.baseDecimals);
        }
        if (assetInfo.quoteDecimals < MINIMUM_ERC20_DECIMALS) {
            revert AssetDecimalsOutOfRange(quoteAsset, assetInfo.quoteDecimals);
        }
        if (assetInfo.quoteDecimals > MAXIMUM_ERC20_DECIMALS) {
            revert AssetDecimalsOutOfRange(quoteAsset, assetInfo.quoteDecimals);
        }

        // Calculate the write and exercise amounts for clearing purposes
        OptionClearingInfo memory clearingInfo; // memory struct to avoid stack too deep
        if (_optionType == OptionType.CALL) {
            clearingInfo = OptionClearingInfo({
                writeAsset: baseAsset,
                writeDecimals: assetInfo.baseDecimals,
                writeAmount: assetInfo.baseDecimals.oneClearingUnit(),
                exerciseAsset: quoteAsset,
                exerciseDecimals: assetInfo.quoteDecimals,
                exerciseAmount: strike.actualScaledDownToClearingStrikeUnit()
            });
        } else {
            clearingInfo = OptionClearingInfo({
                writeAsset: quoteAsset,
                writeDecimals: assetInfo.quoteDecimals,
                writeAmount: strike.actualScaledDownToClearingStrikeUnit(),
                exerciseAsset: baseAsset,
                exerciseDecimals: assetInfo.baseDecimals,
                exerciseAmount: assetInfo.baseDecimals.oneClearingUnit()
            });
        }

        // Generate the option hash and option token id
        uint248 optionHash = LibOption.paramsToHash(
            baseAsset, quoteAsset, expiry, strike, _optionType, exerciseStyle
        );
        _optionTokenId = optionHash.hashToId();

        // Check that the option does not exist already
        if (optionStorage[optionHash].writeAsset != address(0)) {
            revert OptionAlreadyExists(_optionTokenId);
        }

        // Check that the exercise window is valid
        // if (exerciseWindow.length != 2) {
        //     revert ExerciseWindowMispaired();
        // }
        // if (exerciseWindow[0] == exerciseWindow[1]) {
        //     revert ExerciseWindowZeroTime(exerciseWindow[0], exerciseWindow[1]);
        // }
        // if (exerciseWindow[0] > exerciseWindow[1]) {
        //     revert ExerciseWindowMisordered(exerciseWindow[0], exerciseWindow[1]);
        // }
        if (expiry <= block.timestamp) {
            revert ExerciseWindowExpiryPast(expiry);
        }
        // Not possible with strongly typed input args
        if (expiry > MAXIMUM_EXPIRY) {
            revert ExerciseWindowExpiryTooFarInFuture(expiry);
        }

        // Check that strike price is valid
        if (strike < MINIMUM_STRIKE) {
            revert StrikePriceTooSmall(strike);
        }
        if (strike > MAXIMUM_STRIKE) {
            revert StrikePriceTooLarge(strike);
        }

        // Check that option amount does not exceed max writable
        if (optionAmount > MAXIMUM_WRITABLE) {
            revert WriteAmountTooLarge(optionAmount);
        }

        ///////// Effects

        // Store the option
        optionStorage[optionHash] = OptionStorage({
            writeAsset: clearingInfo.writeAsset,
            writeAmount: clearingInfo.writeAmount,
            optionType: _optionType,
            exerciseStyle: exerciseStyle,
            exerciseAsset: clearingInfo.exerciseAsset,
            exerciseAmount: clearingInfo.exerciseAmount,
            expiry: expiry,
            optionState: OptionState({
                amountWritten: optionAmount,
                amountNettedOff: 0,
                amountExercised: 0
            })
        });

        // Store the base ticker
        tickers[optionHash] = LibMetadata.paramsToTicker(
            assetInfo.baseSymbol,
            assetInfo.quoteSymbol,
            expiry.toString(),
            exerciseStyle,
            strike.actualScaledDownToHumanReadableStrike(assetInfo.quoteDecimals).toString(
            ),
            _optionType
        );

        // Scope to avoid stack too deep
        {
            // Store the asset information, if not already stored
            AssetMetadataStorage storage baseAssetStored = assetMetadataStorage[baseAsset];
            if (baseAssetStored.decimals == 0) {
                baseAssetStored.symbol = assetInfo.baseSymbol.toBytes31();
                baseAssetStored.decimals = assetInfo.baseDecimals;
            }
            AssetMetadataStorage storage quoteAssetStored =
                assetMetadataStorage[quoteAsset];
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
            expiry,
            strike,
            _optionType,
            exerciseStyle
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

    /// @dev Some Effects and all Interations for writing a given amount of options,
    /// called by _writeNew() and writeExisting()
    function _writeOptions(
        uint256 _optionTokenId,
        uint64 optionAmount,
        address writeAsset,
        uint64 writeAmount
    ) private {
        ///////// Effects (continued)
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

    /// @notice Writes a given amount for an already existing option
    /// @param _optionTokenId The token id of the option
    /// @param optionAmount The amount of options to write
    function writeExisting(uint256 _optionTokenId, uint64 optionAmount) public override {
        ///////// Function Requirements
        // Check that the option amount is not zero
        if (optionAmount == 0) {
            revert WriteAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(_optionTokenId);
        }

        // Check that the option is not expired
        uint32 expiry = optionStored.expiry;
        if (expiry < block.timestamp) {
            revert OptionExpired(_optionTokenId, expiry);
        }

        // Check that amount is not greater than the remaining writable amount
        // (not DRY with remainingWritableAmount() but is more gas efficient)
        if (optionAmount > (MAXIMUM_WRITABLE - optionStored.optionState.amountWritten)) {
            revert WriteAmountTooLarge(optionAmount);
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

    /// @notice Writes given amounts for multiple already existing options
    /// @param optionTokenIds The token ids of the options
    /// @param optionAmounts The amounts of options to write
    function batchWriteExisting(
        uint256[] calldata optionTokenIds,
        uint64[] calldata optionAmounts
    ) external {
        ///////// Function Requirements
        // Check that the arrays are not empty
        uint256 idsLength = optionTokenIds.length;
        if (idsLength == 0) {
            revert BatchWriteArrayLengthZero();
        }
        // Check that the arrays are the same length
        if (idsLength != optionAmounts.length) {
            revert BatchWriteArrayLengthMismatch();
        }

        ///////// Effects, Interactions, Protocol Invariant
        // Iterate through the arrays, writing on each option
        for (uint256 i = 0; i < idsLength; i++) {
            writeExisting(optionTokenIds[i], optionAmounts[i]);
        }
    }

    // Net Off

    /// @notice Nets off the caller's position for a given option, burning the specified
    /// held amount of long and short tokens and returning the concomitant amount of the
    /// write asset (which for calls, is the base asset, and for puts, is the quote asset)
    /// @param _optionTokenId The token id of the option
    /// @param optionAmount The amount of options to net off
    /// @return writeAssetReturned The amount of write asset returned to the caller
    function netOff(uint256 _optionTokenId, uint64 optionAmount)
        external
        override
        returns (uint128 writeAssetReturned)
    {
        ///////// Function Requirements
        // Check that the exercise amount is not zero
        if (optionAmount == 0) {
            revert NetOffAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        address writeAsset = optionStored.writeAsset;
        if (writeAsset == address(0)) {
            revert OptionDoesNotExist(_optionTokenId);
        }

        // Check that the position token type is a long
        // TODO

        // Check that not expired, otherwise they can just redeem
        // TODO

        // Check that the caller holds sufficient longs and shorts to net off
        OptionState storage optionState = optionStored.optionState;
        if (optionAmount > _balanceOf(msg.sender, _optionTokenId, optionState)) {
            revert InsufficientLongBalance(_optionTokenId, optionAmount);
        }
        if (
            optionAmount
                > _balanceOf(msg.sender, _optionTokenId.longToShort(), optionState)
        ) {
            revert InsufficientShortBalance(_optionTokenId, optionAmount);
        }

        ///////// Effects
        // Update option state
        uint64 amountNettedOff = optionStored.optionState.amountNettedOff;
        optionStored.optionState.amountNettedOff = amountNettedOff + optionAmount;

        // Burn the caller's longs and shorts
        _burn(msg.sender, _optionTokenId, optionAmount);
        _burn(msg.sender, _optionTokenId.longToShort(), optionAmount);

        // Track the clearing liabilities
        writeAssetReturned = uint128(optionStored.writeAmount) * uint128(optionAmount);
        _decrementClearingLiability(writeAsset, writeAssetReturned);

        ///////// Interactions
        // Transfer out the write asset
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, writeAssetReturned);

        // Log net off event
        emit OptionsNettedOff(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        _verifyAfter(writeAsset, optionStored.exerciseAsset);
    }

    // Exercise

    /// @notice Exercises the specified amount of a given option, burning the long
    /// tokens, transferring in the required amount of the exercise asset, and
    /// transferring out the concomitant amount of the write asset
    /// @param _optionTokenId The token id of the option
    /// @param optionAmount The amount of options to exercise
    function exerciseLongs(uint256 _optionTokenId, uint64 optionAmount)
        external
        override
    {
        ///////// Function Requirements
        // Check that the exercise amount is not zero
        if (optionAmount == 0) {
            revert ExerciseAmountZero();
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[_optionTokenId.idToHash()];
        if (optionStored.writeAsset == address(0)) {
            revert OptionDoesNotExist(_optionTokenId);
        }

        // Check that the position token type is a long
        if (_optionTokenId.tokenType() != TokenType.LONG) {
            revert CanOnlyExerciseLongs(_optionTokenId);
        }

        // Check that the option is within the exercise window
        uint32 expiry = optionStored.expiry;
        if (optionStored.exerciseStyle == ExerciseStyle.AMERICAN) {
            // Exercisable up to and including expiry
            if (block.timestamp > expiry) {
                revert OptionNotWithinExerciseWindow(1, expiry);
            }
        } else if (optionStored.exerciseStyle == ExerciseStyle.EUROPEAN) {
            // Exercisable from 1 day before expiry, up to and including expiry
            if (block.timestamp > expiry || block.timestamp < expiry - 1 days) {
                revert OptionNotWithinExerciseWindow(expiry - 1 days, expiry);
            }
        } else {
            revert(); // should be unreachable
        }

        // Check that the caller holds sufficient longs to exercise
        uint256 optionBalance = internalBalanceOf[msg.sender][_optionTokenId];
        if (optionAmount > optionBalance) {
            revert ExerciseAmountExceedsLongBalance(optionAmount, optionBalance);
        }

        ///////// Effects
        // Update the option state
        uint64 amountExercised = optionStored.optionState.amountExercised;
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

        // Transfer out the write asset
        SafeTransferLib.safeTransfer(ERC20(writeAsset), msg.sender, fullAmountForWrite);

        // Log exercise event
        emit OptionsExercised(msg.sender, _optionTokenId, optionAmount);

        ///////// Protocol Invariant
        // Check that the clearing liabilities can be met
        _verifyAfter(writeAsset, exerciseAsset);
    }

    // Redeem

    /// @notice Redeems the caller's shorts for a given option, burning the shorts and
    /// transferring out the write asset for unassigned options and the exercise asset for
    /// assigned options
    /// TODO add info about timing and restrictions
    /// @param shortTokenId The token id of the short token
    function redeemShorts(uint256 shortTokenId)
        external
        override
        returns (uint128 writeAssetRedeemed, uint128 exerciseAssetRedeemed)
    {
        ///////// Function Requirements
        // Check that the token type is a short
        if (shortTokenId.tokenType() != TokenType.SHORT) {
            revert CanOnlyRedeemShorts(shortTokenId);
        }

        // Check that the option exists
        OptionStorage storage optionStored = optionStorage[shortTokenId.idToHash()];
        address writeAsset = optionStored.writeAsset;
        if (writeAsset == address(0)) {
            revert OptionDoesNotExist(shortTokenId);
        }

        // Check that the caller holds shorts for this option
        uint256 nonVirtualShortBalance = internalBalanceOf[msg.sender][shortTokenId];
        if (nonVirtualShortBalance == 0) {
            revert ShortBalanceZero(shortTokenId);
        }

        ///////// Effects
        // Determine the assignment status
        OptionState storage optionState = optionStored.optionState;
        uint256 unassignedShortAmount = _balanceOf(msg.sender, shortTokenId, optionState);
        uint256 assignedShortAmount =
            _balanceOf(msg.sender, shortTokenId.shortToAssignedShort(), optionState);

        // If fully assigned, redeem exercise asset and skip option expiry check
        if (unassignedShortAmount == 0) {
            exerciseAssetRedeemed =
                optionStored.exerciseAmount * uint128(assignedShortAmount);
        } else {
            // Perform additional check that the option is expired
            if (block.timestamp <= optionStored.expiry) {
                revert EarlyRedemptionOnlyIfFullyAssigned();
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
        // Transfer out the write asset and exercise, as needed
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

    ///////// Clearing Pool

    /// @notice Returns the amount of a given asset that the clearinghouse holds which can
    /// be skimmed by a caller, above and beyond the current clearing liabilities
    /// @param asset The ERC20 asset to check
    /// @return amount The amount of the asset that can be skimmed
    function skimmable(address asset) external view returns (uint256 amount) {
        revert("not yet impl");
    }

    /// @notice Skims a given amount of a given asset from the clearinghouse, above and
    /// beyond the current clearing liabilities, transferring this amount to the caller
    /// @param asset The ERC20 asset to skim
    /// @return amount The amount of the asset that was skimmed
    function skim(address asset) external returns (uint256 amount) {
        revert("not yet impl");
    }

    ///////// Clarity Callback

    /// TODO
    function clarityCallback(Callback calldata /*_callback*/ ) external pure {
        revert("not yet impl");
    }

    ///////// FREI-PI

    /// @dev Increments the clearing liability for a ERC20 given asset, called by
    /// _writeOptions() and exerciseLongs()
    /// @param asset The asset to increment the clearing liability for
    /// @param amount The amount to increment the clearing liability by
    function _incrementClearingLiability(address asset, uint256 amount) internal {
        clearingLiabilities[asset] += amount;
    }

    /// @dev Decrements the clearing liability for a given ERC20 asset, called by
    /// netOff(), exerciseLongs() and redeemShorts()
    /// @param asset The asset to decrement the clearing liability for
    /// @param amount The amount to decrement the clearing liability by
    function _decrementClearingLiability(address asset, uint256 amount) internal {
        clearingLiabilities[asset] -= amount;
    }

    /// @dev Verifies that the clearing liabilities can be met for a given ERC20 asset
    /// pair, called by all functions which transfer in or out ERC20 assets --
    /// _writeNew(), writeExisting(), netOff(), exerciseLongs(), and redeemShorts()
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
