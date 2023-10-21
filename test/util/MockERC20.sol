// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    /////////

    constructor(string memory name, string memory symbol, uint8 decimals)
        ERC20(name, symbol, decimals)
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
