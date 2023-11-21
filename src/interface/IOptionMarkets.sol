// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Interfaces
import {IOption} from "./option/IOption.sol";
import {IOptionViews} from "./option/IOptionViews.sol";
import {IOptionActions} from "./option/IOptionActions.sol";
import {IOptionEvents} from "./option/IOptionEvents.sol";
import {IOptionErrors} from "./option/IOptionErrors.sol";

interface IOptionMarkets is
    IOption,
    IOptionViews,
    IOptionActions,
    IOptionEvents,
    IOptionErrors
{}
