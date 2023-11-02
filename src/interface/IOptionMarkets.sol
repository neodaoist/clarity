// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOptionToken} from "./option/IOptionToken.sol";
import {IOptionState} from "./option/IOptionState.sol";
import {IOptionActions} from "./option/IOptionActions.sol";
import {IOptionEvents} from "./option/IOptionEvents.sol";
import {IOptionPosition} from "./option/IOptionPosition.sol";

interface IOptionMarkets is
    IOptionToken,
    IOptionState,
    IOptionActions,
    IOptionEvents,
    IOptionPosition
{}
