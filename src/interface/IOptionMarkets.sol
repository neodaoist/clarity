// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import {IOption} from "./option/IOption.sol";
import {IOptionActions} from "./option/IOptionActions.sol";
import {IOptionEvents} from "./option/IOptionEvents.sol";
import {IOptionErrors} from "./option/IOptionErrors.sol";
import {IOptionState} from "./option/IOptionState.sol";

interface IOptionMarkets is
    IOption,
    IOptionActions,
    IOptionEvents,
    IOptionErrors,
    IOptionState
{}
