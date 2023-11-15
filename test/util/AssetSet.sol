// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Test Interfaces
import {IERC20} from "forge-std/interfaces/IERC20.sol";

struct AssetSet {
    IERC20[] assets;
    mapping(IERC20 => bool) saved;
}

library LibAssetSet {
    /////////

    function add(AssetSet storage s, IERC20 option) internal {
        if (!s.saved[option]) {
            s.assets.push(option);
            s.saved[option] = true;
        }
    }

    function contains(AssetSet storage s, IERC20 option) internal view returns (bool) {
        return s.saved[option];
    }

    function count(AssetSet storage s) internal view returns (uint256) {
        return s.assets.length;
    }

    function forEach(AssetSet storage s, function(IERC20) external func) internal {
        for (uint256 i = 0; i < s.assets.length; ++i) {
            func(s.assets[i]);
        }
    }

    function reduce(
        AssetSet storage s,
        uint256 acc,
        function(uint256,IERC20) external returns (uint256) func
    ) internal returns (uint256) {
        for (uint256 i = 0; i < s.assets.length; ++i) {
            acc = func(acc, s.assets[i]);
        }
        return acc;
    }
}
