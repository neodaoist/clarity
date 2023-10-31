// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract RebasingTest is BaseClarityMarketsTest {
    /////////

    /////////
    // function balanceOf(address owner, uint256 tokenId) public view returns (uint256 amount)

    // TODO

    // Sad Paths

    function testRevert_balanceOf_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE), address(LUSDLIKE), americanExWeeklies[0], 1750e18, IOptionToken.OptionType.CALL
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 shortId = LibToken.longToShort(longId);
        uint256 assignedShortId = LibToken.longToAssignedShort(longId);

        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, longId));

        vm.prank(writer);
        clarity.balanceOf(writer, longId);

        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, shortId));

        vm.prank(writer);
        clarity.balanceOf(writer, shortId);

        vm.expectRevert(abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, assignedShortId));

        vm.prank(writer);
        clarity.balanceOf(writer, assignedShortId);
    }
}
