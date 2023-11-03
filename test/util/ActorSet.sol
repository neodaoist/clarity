// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct ActorSet {
    address[] actors;
    mapping(address => bool) saved;
}

library LibActorSet {
    /////////

    function add(ActorSet storage s, address actor) internal {
        if (!s.saved[actor]) {
            s.actors.push(actor);
            s.saved[actor] = true;
        }
    }

    function contains(ActorSet storage s, address actor) internal view returns (bool) {
        return s.saved[actor];
    }

    function count(ActorSet storage s) internal view returns (uint256) {
        return s.actors.length;
    }

    function forEach(ActorSet storage s, function(address) external func) internal {
        for (uint256 i = 0; i < s.actors.length; ++i) {
            func(s.actors[i]);
        }
    }

    function reduce(
        ActorSet storage s,
        uint256 acc,
        function(uint256,address) external returns (uint256) func
    ) internal returns (uint256) {
        for (uint256 i = 0; i < s.actors.length; ++i) {
            acc = func(acc, s.actors[i]);
        }
        return acc;
    }
}
