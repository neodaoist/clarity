// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// External Libraries
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

// TODO add unit tests
// TODO refactor, clarity names, messy, not DRY
library LibPrice {
    /////////

    using SafeCastLib for uint256;

    uint8 public constant OPTION_CONTRACT_SCALAR = 6;

    /////////

    function oneUnit(uint8 baseAssetDecimals) internal pure returns (uint64 unit) {
        unit = (10 ** (baseAssetDecimals - OPTION_CONTRACT_SCALAR)).safeCastTo64();
    }

    function scaledDownToClearingUnit(uint256 strikePrice)
        internal
        pure
        returns (uint64 scaled)
    {
        scaled = (strikePrice / (10 ** OPTION_CONTRACT_SCALAR)).safeCastTo64();
    }

    function scaledUpFromClearingUnit(uint64 strikePrice)
        internal
        pure
        returns (uint256 scaled)
    {
        scaled = strikePrice * (10 ** OPTION_CONTRACT_SCALAR);
    }

    function scaledDownToHumanReadable(uint256 strikePrice, uint8 quoteAssetDecimals)
        internal
        pure
        returns (uint64 scaled)
    {
        scaled = (strikePrice / (10 ** quoteAssetDecimals)).safeCastTo64();
    }

    function fromClearingUnitToHumanReadable(uint64 strikePrice, uint8 quoteAssetDecimals)
        internal
        pure
        returns (uint64 scaled)
    {
        scaled = (strikePrice / (10 ** (quoteAssetDecimals - OPTION_CONTRACT_SCALAR)))
            .safeCastTo64();
    }
}
