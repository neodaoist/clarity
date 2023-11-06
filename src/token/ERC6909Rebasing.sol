// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IERC6909} from "../interface/token/IERC6909.sol";
import {IERC6909MetadataModified} from "../interface/token/IERC6909MetadataModified.sol";
import {IERC6909MetadataURI} from "../interface/token/IERC6909MetadataURI.sol";

/// @notice Minimalist and gas efficient standard ERC6909 implementation.
/// Forked from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC6909.sol)
abstract contract ERC6909Rebasing is
    IERC6909,
    IERC6909MetadataModified,
    IERC6909MetadataURI
{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    // event OperatorSet(address indexed owner, address indexed operator, bool approved);

    // event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    // event Transfer(
    //     address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount
    // );

    /*//////////////////////////////////////////////////////////////
                             ERC6909 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) internal internalTotalSupply; // TODO internalize and virtualize as well

    mapping(address => mapping(address => bool)) public isOperator;

    mapping(address => mapping(uint256 => uint256)) internal internalBalanceOf;

    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;

    /*//////////////////////////////////////////////////////////////
                              ERC6909 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address receiver, uint256 id, uint256 amount)
        public
        virtual
        returns (bool)
    {
        internalBalanceOf[msg.sender][id] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalanceOf[receiver][id] += amount;
        }

        emit Transfer(msg.sender, msg.sender, receiver, id, amount);

        return true;
    }

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
        public
        virtual
        returns (bool)
    {
        if (msg.sender != sender && !isOperator[sender][msg.sender]) {
            uint256 allowed = allowance[sender][msg.sender][id];
            if (allowed != type(uint256).max) {
                allowance[sender][msg.sender][id] = allowed - amount;
            }
        }

        internalBalanceOf[sender][id] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalanceOf[receiver][id] += amount;
        }

        emit Transfer(msg.sender, sender, receiver, id, amount);

        return true;
    }

    function approve(address spender, uint256 id, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender][id] = amount;

        emit Approval(msg.sender, spender, id, amount);

        return true;
    }

    function setOperator(address operator, bool approved) public virtual returns (bool) {
        isOperator[msg.sender][operator] = approved;

        emit OperatorSet(msg.sender, operator, approved);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0xb2e69f8a; // ERC165 Interface ID for ERC6909
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address receiver, uint256 id, uint256 amount) internal virtual {
        internalTotalSupply[id] += amount; // TODO TBD

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalanceOf[receiver][id] += amount;
        }

        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal virtual {
        internalBalanceOf[sender][id] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            internalTotalSupply[id] -= amount; // TODO TBD
        }

        emit Transfer(msg.sender, sender, address(0), id, amount);
    }
}
