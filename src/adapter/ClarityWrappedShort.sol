// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "../interface/option/IOption.sol";
import {IOptionErrors} from "../interface/option/IOptionErrors.sol";
import {IWrappedOption} from "../interface/adapter/IWrappedOption.sol";
import {IClarityWrappedShort} from "../interface/adapter/IClarityWrappedShort.sol";

// Libraries
import {LibPosition} from "../library/LibPosition.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ClarityWrappedShort is IWrappedOption, IClarityWrappedShort, ERC20 {
    /////////

    using LibPosition for uint256;

    /////////

    ClarityMarkets public immutable clarity;

    uint256 public immutable optionTokenId;

    uint256 public immutable shortTokenId;

    /////////

    uint8 private constant DECIMALS = 6;

    constructor(ClarityMarkets _clarity, uint256 _shortTokenId, string memory _name)
        ERC20(_name, _name, DECIMALS)
    {
        // Set state
        clarity = _clarity;
        optionTokenId = _shortTokenId.shortToLong();
        shortTokenId = _shortTokenId;

        // Log event
        emit ClarityWrappedShortDeployed(_shortTokenId, address(this));
    }

    /////////

    function option() external view returns (IOption.Option memory) {
        return clarity.option(optionTokenId);
    }

    function wrapShorts(uint64 /*shortAmount*/ ) external pure {
        revert("not yet impl");
    }

    function unwrapShorts(uint64 /*shortAmount*/ ) external pure {
        revert("not yet impl");
    }

    function redeemShorts(uint64 /*shortAmount*/ ) external pure {
        revert("not yet impl");
    }
}
