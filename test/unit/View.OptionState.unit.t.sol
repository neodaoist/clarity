// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../src/interface/option/IOptionState.sol";

import "../BaseClarityMarkets.t.sol";

contract OptionStateViewsTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function optionState(uint256 optionTokenId) external view returns (OptionState memory optionState);

    function test_optionState_whenWritten() public withSimpleBackground(1707e18) {
        IOptionState.OptionState memory state = clarity.optionState(oti1);

        assertEq(state.amountWritten, 2.5e6, "amount written");
        assertEq(state.amountExercised, 0, "amount exercised");
        assertEq(state.amountNettedOff, 0, "amount netted off");
        assertEq(state.numOpenTickets, 3, "num open tickets");
    }

    function test_optionState_whenExercised() public withSimpleBackground(1707e18) {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        IOptionState.OptionState memory state = clarity.optionState(oti1);

        assertEq(state.amountWritten, 2.3e6, "amount written");
        assertEq(state.amountExercised, 0.2e6, "amount exercised");
        assertEq(state.amountNettedOff, 0, "amount netted off");
        assertEq(state.numOpenTickets, 2, "num open tickets");
    }

    // TODO whenNettedOff
    // TODO whenRedeemed
    // TODO reverts

    /////////
    // function openInterest(uint256 optionTokenId) external view returns (uint80 amount);

    function test_openInterest_whenWritten() public withSimpleBackground(1707e18) {
        assertEq(clarity.openInterest(oti1), 2.5e6, "open interest");
    }

    function test_openInterest_whenExercised() public withSimpleBackground(1707e18) {
        vm.startPrank(holder);
        LUSDLIKE.approve(address(clarity), scaleUpAssetAmount(LUSDLIKE, STARTING_BALANCE));
        clarity.exercise(oti1, 0.2e6);
        vm.stopPrank();

        assertEq(clarity.openInterest(oti1), 2.3e6, "open interest");
    }

    /////////
    // function writeableAmount(uint256 optionTokenId) external view returns (uint80 amount);

    // TODO

    /////////
    // function reedemableAmount(uint256 optionTokenId) external view returns (uint80 amount);

    // TODO
}
