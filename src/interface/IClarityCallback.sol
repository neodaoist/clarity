// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IClarityCallback {
    /////////

    struct Callback {
        bool success;
    }

    /////////

    function clarityCallback(Callback calldata _callback) external;
}
