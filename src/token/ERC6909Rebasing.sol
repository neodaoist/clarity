// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Interfaces
import {IERC6909} from "../interface/token/IERC6909.sol";
import {IERC6909MetadataModified} from "../interface/token/IERC6909MetadataModified.sol";
import {IERC6909MetadataURI} from "../interface/token/IERC6909MetadataURI.sol";

/// @notice Minimalist and gas efficient standard ERC6909 implementation.
/// Forked from Solmate
/// (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC6909.sol)
/// and
/// jtriley's reference implementation (https://github.com/jtriley-eth/ERC-6909)
abstract contract ERC6909Rebasing is
    IERC6909,
    IERC6909MetadataModified,
    IERC6909MetadataURI
{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The event emitted when a transfer occurs.
    /// @param caller The caller of the transfer.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Transfer(
        address caller,
        address indexed sender,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount
    );

    /// @notice The event emitted when an operator is set.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /// @notice The event emitted when an approval occurs.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                             ERC6909 STORAGE
    //////////////////////////////////////////////////////////////*/

    // NOTE typically totalSupply storage is here, but Clarity implements
    // a fully virtual totalSupply()

    mapping(address => mapping(address => bool)) public isOperator;

    // NOTE Clarity implements a partially virtual balanceOf() -- see more in
    // ClarityMarkets.sol#totalSupply() and ClarityMarkets.sol#balanceOf(address)

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
        // NOTE typically totalSupply accounting is here, but Clarity implements
        // a fully virtual totalSupply()

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalanceOf[receiver][id] += amount;
        }

        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal virtual {
        internalBalanceOf[sender][id] -= amount;

        // NOTE typically totalSupply accounting is here, but Clarity implements
        // a fully virtual totalSupply()

        emit Transfer(msg.sender, sender, address(0), id, amount);
    }
}
