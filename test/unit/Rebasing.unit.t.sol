// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Test Harness
import "../BaseClarityMarkets.t.sol";

contract RebasingTest is BaseClarityMarketsTest {
    /////////

    uint64 internal constant SOME_WRITTEN = 10.000001e6;
    uint64 internal constant MANY_WRITTEN = 6_000_000e6;
    uint64 internal constant MAX_WRITTEN = 1_800_000_000_000e6; // max OI of 18 trillion contracts

    uint64[] internal writeGivens;

    function setUp() public override {
        super.setUp();

        // for this test suite, deal infinite WETHLIKE to writer
        deal(address(WETHLIKE), writer, type(uint256).max);

        // setup write givens for use in Scenarios A-J
        writeGivens.push(SOME_WRITTEN);
        writeGivens.push(MANY_WRITTEN);
        writeGivens.push(MAX_WRITTEN);
    }

    ///////// Rebasing Scenarios
    //
    // Scenarios testing various writing, netting off, and exercising combinations:
    //
    // Let W(o) be the amount written, N(o) the amount netted off, and X(o) the amount
    // exercised. For each of valid combination of none, some, most, and all, we assert
    // the correctnessof totalSupply() at the option level, and balanceOf() at the
    // position level. The scenarios are lettered A-J, and for each scenario we test
    // the relevant none/some/many/max W(o) amounts. In the e2e and invariant tests,
    // we will assert  he correctness of the rebasing functionality with multiple
    // addresses and various transfer scenarios.
    //
    //          | N(o) -------------------------|
    // | X(o)---|   0   | Some  | Most  |  All  |
    // |      0 |   A   |   B   |   C   |   D   |
    // |   Some |   E   |   F   |   G   |   -   |
    // |   Most |   H   |   I   |   -   |   -   |
    // |    All |   J   |   -   |   -   |   -   |
    //

    /////////
    // function totalSupply(uint256 tokenId) public view returns (uint256 amount);

    function test_totalSupply_whenNoneWritten() public {
        // When
        vm.prank(writer);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1900e18,
            optionAmount: 0
        });

        // Then
        assertTotalSupplies(optionTokenId, 0, 0, 0, "given none written");
    }

    function test_totalSupply_whenSomeWritten() public {
        // When
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1900e18,
            optionAmount: SOME_WRITTEN
        });
        vm.stopPrank();

        assertTotalSupplies(
            optionTokenId, SOME_WRITTEN, SOME_WRITTEN, 0, "given some written"
        );
    }

    function test_totalSupply_whenManyWritten() public {
        // When
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1900e18,
            optionAmount: MANY_WRITTEN
        });
        vm.stopPrank();

        // Then
        assertTotalSupplies(
            optionTokenId, MANY_WRITTEN, MANY_WRITTEN, 0, "given many written"
        );
    }

    function test_totalSupply_whenMaxWritten() public {
        // When
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            exerciseWindow: americanExWeeklies[0],
            strikePrice: 1900e18,
            optionAmount: MAX_WRITTEN
        });
        vm.stopPrank();

        // Then
        assertTotalSupplies(
            optionTokenId, MAX_WRITTEN, MAX_WRITTEN, 0, "given max written"
        );
    }

    function test_totalSupply_A_givenAnyWritten_andNoneNettedOff_andNoneExercised()
        public
    {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                exerciseWindow: americanExWeeklies[0],
                strikePrice: 1900e18,
                optionAmount: amountWritten
            });
            vm.stopPrank();

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten,
                amountWritten,
                0,
                "A: none netted off, none exercised"
            );
        }
    }

    function test_totalSupply_B_givenAnyWritten_andSomeNettedOff_andNoneExercised()
        public
    {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNettedOff = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                exerciseWindow: americanExWeeklies[0],
                strikePrice: (1900 + i) * 1e18, // unique option for each test
                optionAmount: amountWritten
            });

            // When
            clarity.netOff(optionTokenId, amountNettedOff);
            vm.stopPrank();

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNettedOff,
                amountWritten - amountNettedOff,
                0,
                "B: some netted off, none exercised"
            );
        }
    }

    function test_totalSupply_C_givenAnyWritten_andMostNettedOff_andNoneExercised()
        public
    {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNettedOff = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                exerciseWindow: americanExWeeklies[0],
                strikePrice: 1900e18,
                optionAmount: amountWritten
            });

            // When
            clarity.netOff(optionTokenId, amountNettedOff);
            vm.stopPrank();

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten,
                amountNettedOff,
                0,
                "C: most netted off, none exercised"
            );
        }
    }

    function test_totalSupply_D_givenAnyWritten_andAllNettedOff_andNoneExercised()
        public
    {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                exerciseWindow: americanExWeeklies[0],
                strikePrice: 1900e18,
                optionAmount: amountWritten
            });

            // When
            clarity.netOff(optionTokenId, amountWritten);
            vm.stopPrank();

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten,
                amountWritten,
                0,
                "D: all netted off, none exercised"
            );
        }
    }

    function test_totalSupply_E_givenAnyWritten_andNoneNettedOff_andSomeExercised()
        public
    {}

    function test_totalSupply_F_givenAnyWritten_andSomeNettedOff_andSomeExercised()
        public
    {}

    function test_totalSupply_G_givenAnyWritten_andMostNettedOff_andSomeExercised()
        public
    {}

    function test_totalSupply_H_givenAnyWritten_andNoneNettedOff_andMostExercised()
        public
    {}

    function test_totalSupply_I_givenAnyWritten_andSomeNettedOff_andMostExercised()
        public
    {}

    function test_totalSupply_J_givenAnyWritten_andNoneNettedOff_andAllExercised()
        public
    {}

    /////////
    // function balanceOf(address owner, uint256 tokenId) public view returns (uint256 amount);

    // TODO

    // Sad Paths

    function testRevert_balanceOf_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibToken.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            americanExWeeklies[0],
            1750e18,
            IOptionToken.OptionType.CALL
        );
        uint256 longId = LibToken.hashToId(instrumentHash);
        uint256 shortId = LibToken.longToShort(longId);
        uint256 assignedShortId = LibToken.longToAssignedShort(longId);

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, longId)
        );

        vm.prank(writer);
        clarity.balanceOf(writer, longId);

        vm.expectRevert(
            abi.encodeWithSelector(OptionErrors.OptionDoesNotExist.selector, shortId)
        );

        vm.prank(writer);
        clarity.balanceOf(writer, shortId);

        vm.expectRevert(
            abi.encodeWithSelector(
                OptionErrors.OptionDoesNotExist.selector, assignedShortId
            )
        );

        vm.prank(writer);
        clarity.balanceOf(writer, assignedShortId);
    }
}
