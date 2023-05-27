# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#    Tests of renderers.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Renderers - printf" begin
    matrix = Any[BigFloat(pi) float(pi) 10.0f0  Float16(1)
                 0x01         0x001     0x00001 0x000000001
                 true         false     true    false
                 "Teste" "Teste\nTeste" "Teste \"quote\" Teste" "Teste\n\"quote\"\nTeste"]

    header = (["C1", "C2", "C3", "C4"],
              ["S1", "S2", "S3", "S4"])

    row_labels = [1, 2, "3", '4']

    # Print
    # --------------------------------------------------------------------------

    expected = """
┌───┬──────┬──────────────────────────────────────────────────────────────────────────────────┬─────────┬─────────────────────┬─────────┐
│ # │ Test │                                                                               C1 │      C2 │                  C3 │      C4 │
│   │      │                                                                               S1 │      S2 │                  S3 │      S4 │
├───┼──────┼──────────────────────────────────────────────────────────────────────────────────┼─────────┼─────────────────────┼─────────┤
│ 1 │    1 │ 3.141592653589793238462643383279502884197169399375105820974944592307816406286198 │ 3.14159 │                10.0 │     1.0 │
│ 2 │    2 │                                                                                1 │       1 │                   1 │       1 │
│ 3 │    3 │                                                                             true │   false │                true │   false │
│ 4 │    4 │                                                                            Teste │   Teste │ Teste "quote" Teste │   Teste │
│   │      │                                                                                  │   Teste │                     │ "quote" │
│   │      │                                                                                  │         │                     │   Teste │
└───┴──────┴──────────────────────────────────────────────────────────────────────────────────┴─────────┴─────────────────────┴─────────┘
"""

    result = pretty_table(
        String,
        matrix;
        header = header,
        linebreaks = true,
        row_labels = row_labels,
        row_label_column_title = "Test",
        row_number_column_title = "#",
        show_row_number = true
    )

    @test expected == result

    expected = """
┌───┬──────┬──────────────────────────────────────────────────────────────────────────────────┬───────────────────┬─────────────────────┬─────────┐
│ # │ Test │                                                                               C1 │                C2 │                  C3 │      C4 │
│   │      │                                                                               S1 │                S2 │                  S3 │      S4 │
├───┼──────┼──────────────────────────────────────────────────────────────────────────────────┼───────────────────┼─────────────────────┼─────────┤
│ 1 │    1 │ 3.141592653589793238462643383279502884197169399375105820974944592307816406286198 │ 3.141592653589793 │                10.0 │     1.0 │
│ 2 │    2 │                                                                                1 │                 1 │                   1 │       1 │
│ 3 │    3 │                                                                             true │             false │                true │   false │
│ 4 │    4 │                                                                            Teste │             Teste │ Teste "quote" Teste │   Teste │
│   │      │                                                                                  │             Teste │                     │ "quote" │
│   │      │                                                                                  │                   │                     │   Teste │
└───┴──────┴──────────────────────────────────────────────────────────────────────────────────┴───────────────────┴─────────────────────┴─────────┘
"""

    result = pretty_table(
        String,
        matrix;
        header = header,
        compact_printing = false,
        linebreaks = true,
        row_labels = row_labels,
        row_label_column_title = "Test",
        row_number_column_title = "#",
        show_row_number = true
    )

    @test expected == result

    # Limit printing
    # --------------------------------------------------------------------------

    matrix = [
        [collect(1:1:30)] [collect(1:1:21)]
        [collect(1:1:20)] [collect(1:1:2)]
    ]

    expected = """
┌────────────────────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────┐
│                                                                     Col. 1 │                                                                     Col. 2 │
├────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┤
│ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10  …  21, 22, 23, 24, 25, 26, 27, 28, 29, 30] │ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10  …  12, 13, 14, 15, 16, 17, 18, 19, 20, 21] │
│    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] │                                                                     [1, 2] │
└────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────┘
"""

    result = pretty_table(String, matrix)
    @test expected == result

    expected = """
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────┐
│                                                                                                          Col. 1 │                                                                      Col. 2 │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] │ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21] │
│                                         [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] │                                                                      [1, 2] │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────┘
"""

    result = pretty_table(String, matrix,
                          limit_printing = false)
    @test expected == result
end

@testset "Renderers - show" begin
    matrix = Any[
        BigFloat(pi) float(pi) 10.0f0  Float16(1)
        0x01         0x001     0x00001 0x000000001
        true         false     true    false
        "Teste" "Teste\nTeste" "Teste \"quote\" Teste" "Teste\n\"quote\"\nTeste"
    ]

    header = (
        ["C1", "C2", "C3", "C4"],
        ["S1", "S2", "S3", "S4"]
    )

    row_labels = [1, 2, "3", '4']

    # Show
    # --------------------------------------------------------------------------

    expected = """
┌───┬──────┬─────────┬─────────┬─────────────────────────┬────────────────────┐
│ # │ Test │      C1 │      C2 │                      C3 │                 C4 │
│   │      │      S1 │      S2 │                      S3 │                 S4 │
├───┼──────┼─────────┼─────────┼─────────────────────────┼────────────────────┤
│ 1 │    1 │ 3.14159 │ 3.14159 │                    10.0 │                1.0 │
│ 2 │    2 │    0x01 │  0x0001 │              0x00000001 │ 0x0000000000000001 │
│ 3 │    3 │    true │   false │                    true │              false │
│ 4 │    4 │ "Teste" │ "Teste" │ "Teste \\"quote\\" Teste" │            "Teste" │
│   │      │         │ "Teste" │                         │        "\\"quote\\"" │
│   │      │         │         │                         │            "Teste" │
└───┴──────┴─────────┴─────────┴─────────────────────────┴────────────────────┘
"""

    result = pretty_table(
        String,
        matrix;
        header = header,
        linebreaks = true,
        renderer = :show,
        row_labels = row_labels,
        row_label_column_title = "Test",
        row_number_column_title = "#",
        show_row_number = true
    )

    @test expected == result

    expected = """
┌───┬──────┬──────────────────────────────────────────────────────────────────────────────────┬───────────────────┬─────────────────────────┬────────────────────┐
│ # │ Test │                                                                               C1 │                C2 │                      C3 │                 C4 │
│   │      │                                                                               S1 │                S2 │                      S3 │                 S4 │
├───┼──────┼──────────────────────────────────────────────────────────────────────────────────┼───────────────────┼─────────────────────────┼────────────────────┤
│ 1 │    1 │ 3.141592653589793238462643383279502884197169399375105820974944592307816406286198 │ 3.141592653589793 │                  10.0f0 │       Float16(1.0) │
│ 2 │    2 │                                                                             0x01 │            0x0001 │              0x00000001 │ 0x0000000000000001 │
│ 3 │    3 │                                                                             true │             false │                    true │              false │
│ 4 │    4 │                                                                          "Teste" │           "Teste" │ "Teste \\"quote\\" Teste" │            "Teste" │
│   │      │                                                                                  │           "Teste" │                         │        "\\"quote\\"" │
│   │      │                                                                                  │                   │                         │            "Teste" │
└───┴──────┴──────────────────────────────────────────────────────────────────────────────────┴───────────────────┴─────────────────────────┴────────────────────┘
"""

    result = pretty_table(
        String,
        matrix;
        header = header,
        compact_printing = false,
        linebreaks = true,
        renderer = :show,
        row_labels = row_labels,
        row_label_column_title = "Test",
        row_number_column_title = "#",
        show_row_number = true
    )

    @test expected == result

    # Test the behavior if a formatter returns a string but the original data is
    # not a string. In this case, the renderer `show` must not add surrounding
    # quotes.
    matrix = ['1' "2" 3 s"123"]

    f = (v,i,j)->begin
        if j == 1
            return "😀😀😀"
        elseif j == 2
            return "😁😁"
        elseif j == 3
            return 'a'
        else
            return v
        end
    end

    expected = """
┌────────┬────────┬────────┬────────┐
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
├────────┼────────┼────────┼────────┤
│ 😀😀😀 │ "😁😁" │    'a' │ s"123" │
└────────┴────────┴────────┴────────┘
"""

    result = pretty_table(
        String,
        matrix;
        formatters = f,
        renderer = :show
    )

    @test result == expected

    # Limit printing
    # --------------------------------------------------------------------------

    matrix = [
        [collect(1:1:30)] [collect(1:1:21)]
        [collect(1:1:20)] [collect(1:1:2)]
    ]

    expected = """
┌────────────────────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────┐
│                                                                     Col. 1 │                                                                     Col. 2 │
├────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┤
│ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10  …  21, 22, 23, 24, 25, 26, 27, 28, 29, 30] │ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10  …  12, 13, 14, 15, 16, 17, 18, 19, 20, 21] │
│    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] │                                                                     [1, 2] │
└────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────┘
"""

    result = pretty_table(String, matrix; renderer = :show)
    @test expected == result

    expected = """
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────┐
│                                                                                                          Col. 1 │                                                                      Col. 2 │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤
│ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] │ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21] │
│                                         [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] │                                                                      [1, 2] │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────┘
"""

    result = pretty_table(
        String,
        matrix;
        limit_printing = false,
        renderer = :show
    )
    @test expected == result
end
