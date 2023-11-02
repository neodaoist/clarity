// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOptionToken} from "../interface/option/IOptionToken.sol";
import {IWrappedOption} from "../interface/adapter/IWrappedOption.sol";
import {IClarityWrappedShort} from "../interface/adapter/IClarityWrappedShort.sol";

// Contracts
import {ClarityMarkets} from "../ClarityMarkets.sol";
import {OptionErrors} from "../library/OptionErrors.sol";

// External Contracts
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ClarityWrappedShort is IWrappedOption, IClarityWrappedShort, ERC20 {
    /////////

    ClarityMarkets public immutable clarity;

    uint256 public immutable optionTokenId;

    uint8 private constant DECIMALS = 6;

    constructor(ClarityMarkets _clarity, uint256 _optionTokenId, string memory _name)
        ERC20(_name, _name, DECIMALS)
    {
        // Set state
        clarity = _clarity;
        optionTokenId = _optionTokenId;

        // Log event
        emit ClarityWrappedShortDeployed(_optionTokenId, address(this));
    }

    /////////

    function option() external view returns (IOptionToken.Option memory) {
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
