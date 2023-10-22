// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./option/IOptionToken.sol";
import "./option/IOptionState.sol";
import "./option/IOptionActions.sol";
import "./option/IOptionEvents.sol";
import "./option/IOptionPosition.sol";

interface IOptionMarkets is IOptionToken, IOptionState, IOptionActions, IOptionEvents, IOptionPosition {}
