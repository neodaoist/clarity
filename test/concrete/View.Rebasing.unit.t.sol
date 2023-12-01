// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test Fixture
import "../BaseUnitTestSuite.t.sol";

contract RebasingTest is BaseUnitTestSuite {
    /////////

    using LibPosition for uint256;
    using LibPosition for uint248;

    uint64 internal constant SOME_WRITTEN = 10.000001e6;
    uint64 internal constant MANY_WRITTEN = 6_000_000e6;
    uint64 internal constant MAX_WRITTEN = 1_800_000_000_000e6; // max writable on any
        // option contract

    uint64[] internal writeGivens;

    function setUp() public override {
        super.setUp();

        // for this test suite, deal infinite ERC20 to writer
        deal(address(WETHLIKE), writer, type(uint256).max);
        deal(address(FRAXLIKE), writer, type(uint256).max);

        // setup write givens for use in Scenarios A-J
        writeGivens.push(SOME_WRITTEN);
        writeGivens.push(MANY_WRITTEN);
        writeGivens.push(MAX_WRITTEN);
    }

    ///////// Rebasing Scenarios
    //
    // Scenarios testing various writing, netting off, and exercising combinations:
    //
    // Let W(o) be the amount written, N(o) the amount netted, and X(o) the amount
    // exercised. For each valid combination of none, some, most, and all, we assert
    // the correctness of totalSupply() at the option level, and balanceOf() at the
    // position level. The scenarios are lettered A-J, and for each scenario we test
    // each of the some/many/max W(o) amounts. In the e2e and invariant tests, we
    // will assert the correctness of the rebasing functionality with multiple
    // writers/holders and multiple transfer scenarios.
    //
    //          | N(o) -------------------------|
    // | X(o)---| None  | Some  | Most  |  All  |
    // |   None |   A   |   B   |   C   |   D   |
    // |   Some |   E   |   F   |   G   |   -   |
    // |   Most |   H   |   I   |   -   |   -   |
    // |    All |   J   |   -   |   -   |   -   |
    //

    /////////
    // function totalSupply(uint256 tokenId) public view returns (uint256 amount);

    function test_totalSupply_whenNoneWritten() public {
        // Given
        vm.prank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // When
        // totalSupply()

        // Then
        assertTotalSupplies(optionTokenId, 0, 0, 0, "given none written");
    }

    function test_totalSupply_whenSomeWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: SOME_WRITTEN
        });
        vm.stopPrank();

        // When
        // totalSupply()

        assertTotalSupplies(
            optionTokenId, SOME_WRITTEN, SOME_WRITTEN, 0, "given some written"
        );
    }

    function test_totalSupply_whenManyWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: MANY_WRITTEN
        });
        vm.stopPrank();

        // When
        // totalSupply()

        // Then
        assertTotalSupplies(
            optionTokenId, MANY_WRITTEN, MANY_WRITTEN, 0, "given many written"
        );
    }

    function test_totalSupply_whenMaxWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: MAX_WRITTEN
        });
        vm.stopPrank();

        // When
        // totalSupply()

        // Then
        assertTotalSupplies(
            optionTokenId, MAX_WRITTEN, MAX_WRITTEN, 0, "given max written"
        );
    }

    // Scenario A is duplicative of the above 4 tests, but keeping those for clarity ;)
    // and illustrative purposes

    function test_totalSupply_A_givenAnyWritten_andNoneNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten,
                amountWritten,
                0,
                "A: none netted, none exercised"
            );
        }
    }

    function test_totalSupply_B_givenAnyWritten_andSomeNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNetted,
                amountWritten - amountNetted,
                0,
                "B: some netted, none exercised"
            );
        }
    }

    function test_totalSupply_C_givenAnyWritten_andMostNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNetted,
                amountWritten - amountNetted,
                0,
                "C: most netted, none exercised"
            );
        }
    }

    function test_totalSupply_D_givenAnyWritten_andAllNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountWritten);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(optionTokenId, 0, 0, 0, "D: all netted, none exercised");
        }
    }

    function test_totalSupply_E_givenAnyWritten_andNoneNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountExercised,
                amountWritten - amountExercised,
                amountExercised,
                "E: none netted, some exercised"
            );
        }
    }

    function test_totalSupply_F_givenAnyWritten_andSomeNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "F: some netted, some exercised"
            );
        }
    }

    function test_totalSupply_G_givenAnyWritten_andMostNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = (amountWritten * 4) / 5;
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "G: most netted, some exercised"
            );
        }
    }

    function test_totalSupply_H_givenAnyWritten_andNoneNetted_andMostExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountExercised = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountExercised,
                amountWritten - amountExercised,
                amountExercised,
                "H: none netted, most exercised"
            );
        }
    }

    function test_totalSupply_I_givenAnyWritten_andSomeNetted_andMostExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;
            uint64 amountExercised = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "I: some netted, most exercised"
            );
        }
    }

    function test_totalSupply_J_givenAnyWritten_andNoneNetted_andAllExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountWritten);
            vm.stopPrank();

            // When
            // totalSupply()

            // Then
            assertTotalSupplies(
                optionTokenId, 0, 0, amountWritten, "J: none netted, all exercised"
            );
        }
    }

    // Sad Paths

    function testRevert_totalSupply_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1750e18,
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );
        uint256 longTokenId = instrumentHash.hashToId();
        uint256 shortTokenId = longTokenId.longToShort();
        uint256 assignedShortTokenId = longTokenId.longToAssignedShort();

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, longTokenId)
        );

        vm.prank(writer);
        clarity.totalSupply(longTokenId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, shortTokenId
            )
        );

        vm.prank(writer);
        clarity.totalSupply(shortTokenId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, assignedShortTokenId
            )
        );

        vm.prank(writer);
        clarity.totalSupply(assignedShortTokenId);
    }

    /////////
    // function balanceOf(address owner, uint256 tokenId) public view returns (uint256
    // amount);

    function test_balanceOf_whenNoneWritten() public {
        // Given
        vm.prank(writer);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: 0
        });

        // When
        // balanceOf(writer, tokenId)

        // Then
        assertOptionBalances(writer, optionTokenId, 0, 0, 0, "given none written");
    }

    function test_balanceOf_whenSomeWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: SOME_WRITTEN
        });
        vm.stopPrank();

        // When
        // balanceOf(writer, tokenId)

        assertOptionBalances(
            writer, optionTokenId, SOME_WRITTEN, SOME_WRITTEN, 0, "given some written"
        );
    }

    function test_balanceOf_whenManyWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: MANY_WRITTEN
        });
        vm.stopPrank();

        // When
        // balanceOf(writer, tokenId)

        // Then
        assertOptionBalances(
            writer, optionTokenId, MANY_WRITTEN, MANY_WRITTEN, 0, "given many written"
        );
    }

    function test_balanceOf_whenMaxWritten() public {
        // Given
        vm.startPrank(writer);
        WETHLIKE.approve(address(clarity), type(uint256).max);
        uint256 optionTokenId = clarity.writeNewCall({
            baseAsset: address(WETHLIKE),
            quoteAsset: address(FRAXLIKE),
            expiry: FRI1,
            strike: 1900e18,
            allowEarlyExercise: true,
            optionAmount: MAX_WRITTEN
        });
        vm.stopPrank();

        // When
        // balanceOf(writer, tokenId)

        // Then
        assertOptionBalances(
            writer, optionTokenId, MAX_WRITTEN, MAX_WRITTEN, 0, "given max written"
        );
    }

    // Scenario A is duplicative of the above 4 tests, but keeping those for clarity ;)
    // and illustrative purposes

    function test_balanceOf_A_givenAnyWritten_andNoneNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten,
                amountWritten,
                0,
                "A: none netted, none exercised"
            );
        }
    }

    function test_balanceOf_B_givenAnyWritten_andSomeNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountNetted,
                amountWritten - amountNetted,
                0,
                "B: some netted, none exercised"
            );
        }
    }

    function test_balanceOf_C_givenAnyWritten_andMostNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountNetted,
                amountWritten - amountNetted,
                0,
                "C: most netted, none exercised"
            );
        }
    }

    function test_balanceOf_D_givenAnyWritten_andAllNetted_andNoneExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountWritten);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer, optionTokenId, 0, 0, 0, "D: all netted, none exercised"
            );
        }
    }

    function test_balanceOf_E_givenAnyWritten_andNoneNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountExercised,
                amountWritten - amountExercised,
                amountExercised,
                "E: none netted, some exercised"
            );
        }
    }

    function test_balanceOf_F_givenAnyWritten_andSomeNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "F: some netted, some exercised"
            );
        }
    }

    function test_balanceOf_G_givenAnyWritten_andMostNetted_andSomeExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = (amountWritten * 4) / 5;
            uint64 amountExercised = amountWritten / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "G: most netted, some exercised"
            );
        }
    }

    function test_balanceOf_H_givenAnyWritten_andNoneNetted_andMostExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountExercised = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountExercised,
                amountWritten - amountExercised,
                amountExercised,
                "H: none netted, most exercised"
            );
        }
    }

    function test_balanceOf_I_givenAnyWritten_andSomeNetted_andMostExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];
            uint64 amountNetted = amountWritten / 5;
            uint64 amountExercised = (amountWritten * 4) / 5;

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            clarity.netOffsetting(optionTokenId, amountNetted);

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountExercised);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                amountWritten - amountNetted - amountExercised,
                amountWritten - amountNetted - amountExercised,
                amountExercised,
                "I: some netted, most exercised"
            );
        }
    }

    function test_balanceOf_J_givenAnyWritten_andNoneNetted_andAllExercised() public {
        for (uint256 i = 0; i < writeGivens.length; i++) {
            // Given
            uint64 amountWritten = writeGivens[i];

            vm.startPrank(writer);
            WETHLIKE.approve(address(clarity), type(uint256).max);
            uint256 optionTokenId = clarity.writeNewCall({
                baseAsset: address(WETHLIKE),
                quoteAsset: address(FRAXLIKE),
                expiry: FRI1,
                strike: (1900 + i) * 1e18, // unique option for each test
                allowEarlyExercise: true,
                optionAmount: amountWritten
            });

            vm.warp(FRI1 - 1 seconds);

            FRAXLIKE.approve(address(clarity), type(uint256).max);
            clarity.exerciseOption(optionTokenId, amountWritten);
            vm.stopPrank();

            // When
            // balanceOf(writer, tokenId)

            // Then
            assertOptionBalances(
                writer,
                optionTokenId,
                0,
                0,
                amountWritten,
                "J: none netted, all exercised"
            );
        }
    }

    // Sad Paths

    function testRevert_balanceOf_whenOptionDoesNotExist() public {
        uint248 instrumentHash = LibOption.paramsToHash(
            address(WETHLIKE),
            address(LUSDLIKE),
            FRI1,
            1750e18,
            IOption.OptionType.CALL,
            IOption.ExerciseStyle.AMERICAN
        );
        uint256 longTokenId = instrumentHash.hashToId();
        uint256 shortTokenId = longTokenId.longToShort();
        uint256 assignedShortTokenId = longTokenId.longToAssignedShort();

        vm.expectRevert(
            abi.encodeWithSelector(IOptionErrors.OptionDoesNotExist.selector, longTokenId)
        );

        vm.prank(writer);
        clarity.balanceOf(writer, longTokenId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, shortTokenId
            )
        );

        vm.prank(writer);
        clarity.balanceOf(writer, shortTokenId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOptionErrors.OptionDoesNotExist.selector, assignedShortTokenId
            )
        );

        vm.prank(writer);
        clarity.balanceOf(writer, assignedShortTokenId);
    }
}
