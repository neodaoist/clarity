// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct OptionSet {
    uint256[] options;
    mapping(uint256 => bool) saved;
}

library LibOptionSet {
    /////////

    function add(OptionSet storage s, uint256 option) internal {
        if (!s.saved[option]) {
            s.options.push(option);
            s.saved[option] = true;
        }
    }

    function contains(OptionSet storage s, uint256 option) internal view returns (bool) {
        return s.saved[option];
    }

    function count(OptionSet storage s) internal view returns (uint256) {
        return s.options.length;
    }

    function forEach(OptionSet storage s, function(uint256) external func) internal {
        for (uint256 i = 0; i < s.options.length; ++i) {
            func(s.options[i]);
        }
    }

    function reduce(
        OptionSet storage s,
        uint256 acc,
        function(uint256,uint256) external returns (uint256) func
    ) internal returns (uint256) {
        for (uint256 i = 0; i < s.options.length; ++i) {
            acc = func(acc, s.options[i]);
        }
        return acc;
    }
}
