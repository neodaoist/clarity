// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Libraries
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

// TODO add unit tests
// TODO refactor to clarify names, messy, not DRY
library LibMath {
    /////////

    using SafeCastLib for uint256;

    /////////

    uint8 internal constant CONTRACT_SCALAR = 6;

    ///////// Clearing Unit Conversion

    function oneClearingUnit(uint8 baseAssetDecimals)
        internal
        pure
        returns (uint64 unit)
    {
        unit = (10 ** (baseAssetDecimals - CONTRACT_SCALAR)).safeCastTo64();
    }

    ///////// Strike Price Conversions

    function actualScaledDownToClearingStrikeUnit(uint256 strikePrice)
        internal
        pure
        returns (uint64 scaled)
    {
        scaled = (strikePrice / (10 ** CONTRACT_SCALAR)).safeCastTo64();
    }

    function clearingScaledUpToActualStrike(uint64 strikePrice)
        internal
        pure
        returns (uint256 scaled)
    {
        scaled = strikePrice * (10 ** CONTRACT_SCALAR);
    }

    function actualScaledDownToHumanReadableStrike(
        uint256 strikePrice,
        uint8 quoteAssetDecimals
    ) internal pure returns (uint64 scaled) {
        scaled = (strikePrice / (10 ** quoteAssetDecimals)).safeCastTo64();
    }

    function clearingScaledDownToHumanReadableStrike(
        uint64 strikePrice,
        uint8 quoteAssetDecimals
    ) internal pure returns (uint64 scaled) {
        scaled =
            (strikePrice / (10 ** (quoteAssetDecimals - CONTRACT_SCALAR))).safeCastTo64();
    }
}
