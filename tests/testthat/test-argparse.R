# Copyright (c) 2012-2018 Trevor L Davis <trevor.l.davis@gmail.com>
#
#  This file is free software: you may copy, redistribute and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 2 of the License, or (at your
#  option) any later version.
#
#  This file is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This file incorporates work from the argparse module in Python 2.7.3.
#
#     Copyright (c) 1990-2012 Python Software Foundation; All Rights Reserved
#
# See (inst/)COPYRIGHTS or http://docs.python.org/2/license.html for the full
# Python (GPL-compatible) license stack.
context("Unit tests")

options(python_cmd = .find_python_cmd(NULL))
context("print_help")
test_that("print_help works as expected", {
    parser <- ArgumentParser(description = "Process some integers.")
    expect_output(parser$print_help(), "usage:")
    expect_output(parser$print_help(), "optional arguments:")
    expect_output(parser$print_help(), "Process some integers.")
    expect_output(parser$print_usage(), "usage:")

    # Request/bug by PlasmaBinturong
    parser$add_argument("integers", metavar = "N", type = "integer", nargs = "+",
                       help = "an integer for the accumulator")
    expect_error(capture.output(parser$parse_args(), "parse error"))

    if (!interactive()) skip("interactive() == FALSE")
    expect_error(capture.output(parser$parse_args("-h")), "help requested")
})

context("convert_agument")
test_that("convert_argument works as expected", {
    expect_equal(convert_argument("foobar"), "'foobar'")
    expect_equal(convert_argument(14.9), "14.9")
    expect_equal(convert_argument(c(12.1, 14.9)), "(12.1, 14.9)")
    expect_equal(convert_argument(c("a", "b")), "('a', 'b')")
})

context("convert_..._to_arguments")
test_that("convert_..._to_arguments works as expected", {
    # test in mode "add_argument"
    c.2a <- function(...) convert_..._to_arguments("add_argument", ...)
    waz <- "wazzup"
    expect_equal(c.2a(foo = "bar", hello = "world"), "foo='bar', hello='world'")
    expect_equal(c.2a(foo = "bar", waz), "foo='bar', 'wazzup'")
    expect_equal(c.2a(type = "character"), "type=str")
    expect_equal(c.2a(default = TRUE), "default=True")
    expect_equal(c.2a(default = 3.4), "default=3.4")
    expect_equal(c.2a(default = "foo"), "default='foo'")
    # test in mode "ArgumentParser"
    c.2a <- function(...) convert_..._to_arguments("ArgumentParser", ...)
    expect_match(c.2a(argument_default = FALSE), "argument_default=False")
    expect_match(c.2a(argument_default = 30), "argument_default=30")
    expect_match(c.2a(argument_default = "foobar"), "argument_default='foobar'")
    expect_match(c.2a(foo = "bar"), "^prog='PROGRAM'|^prog='test-argparse.R'")
    expect_match(c.2a(formatter_class = "argparse.ArgumentDefaultsHelpFormatter"),
                 "formatter_class=argparse.ArgumentDefaultsHelpFormatter")
})

context("add_argument")
test_that("add_argument works as expected", {
    parser <- ArgumentParser()
    parser$add_argument("integers", metavar = "N", type = "integer", nargs = "+",
                       help = "an integer for the accumulator")
    parser$add_argument("--sum", dest = "accumulate", action = "store_const",
                       const = "sum", default = "max",
                       help = "sum the integers (default: find the max)")
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    f <- get(arguments$accumulate)
    expect_output(parser$print_help(), "sum the integers")
    expect_equal(arguments$accumulate, "sum")
    expect_equal(arguments$integers, c(1, 2))
    expect_equal(f(arguments$integers), 3)
    expect_error(parser$add_argument("--foo", type = "boolean"))

    # Bug found by Martin Diehl
    parser$add_argument("--label", type = "character", nargs = 2,
        dest = "label", action = "store", default = c("a", "b"), help = "label for X and Y axis")
    suppressWarnings(parser$add_argument("--bool", type = "logical", nargs = 2,
        dest = "bool", action = "store", default = c(FALSE, TRUE)))
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    expect_equal(arguments$label, c("a", "b"))
    expect_equal(arguments$bool, c(FALSE, TRUE))

    # Frustration of Martí Duran Ferrer
    expect_warning(parser$add_argument("--bool", type = "logical", action = "store"))

    # Bug/Feature request found by Hyunsoo Kim
    p <- ArgumentParser()
    p$add_argument("--test", default = NULL)
    expect_equal(p$parse_args()$test, NULL)

    # Feature request of Paul Newell
    parser <- ArgumentParser()
    parser$add_argument("extent", nargs = 4, type = "double", metavar = c("e1", "e2", "e3", "e4"))
    expect_output(parser$print_usage(), "usage: PROGRAM \\[-h\\] e1 e2 e3 e4")

    # Bug report by Claire D. McWhite
    parser <- ArgumentParser()
    parser$add_argument("-o", "--output_filename", required = FALSE, default = "outfile.txt")
    expect_equal(parser$parse_args()$output_filename, "outfile.txt")

    parser <- ArgumentParser()
    parser$add_argument("-o", "--output_filename", required = TRUE, default = "outfile.txt")
    expect_error(parser$parse_args())
})

context("version")
test_that("version flags works as expected", {
    # Feature request of Dario Beraldi
    parser <- ArgumentParser()
    parser$add_argument("-v", "--version", action = "version", version = "1.0.1")
    if (interactive()) {
        expect_error(parser$parse_args("-v"), "version requested:\n1.0.1")
        expect_error(parser$parse_args("--version"), "version requested:\n1.0.1")
    }

    # empty list
    parser <- ArgumentParser()
    el <- parser$parse_args()
    expect_true(is.list(el))
    expect_equal(length(el), 0)
})

context("ArgumentParser")
test_that("ArgumentParser works as expected", {
    parser <- ArgumentParser(prog = "foobar", usage = "%(prog)s arg1 arg2")
    parser$add_argument("--hello", dest = "saying", action = "store_const",
            const = "hello", default = "bye",
            help = "%(prog)s's saying (default: %(default)s)")
    expect_output(parser$print_help(), "foobar arg1 arg2")
    expect_output(parser$print_help(), "foobar's saying \\(default: bye\\)")
    expect_error(ArgumentParser(python_cmd = "foobar"))
    skip_if_not(interactive(), "Skip passing -h if not interactive()")
    # Bug report by George Chlipala
    expect_error(ArgumentParser()$parse_args("-h"), "help requested")
    expect_error(ArgumentParser(add_help = TRUE)$parse_args("-h"), "help requested")
    expect_error(ArgumentParser(add_help = FALSE)$parse_args("-h"), "unrecognized arguments")
})
test_that("parse_args works as expected", {
    parser <- ArgumentParser(prog = "foobar", usage = "%(prog)s arg1 arg2")
    parser$add_argument("--hello", dest = "saying", action = "store", default = "foo",
            choices = c("foo", "bar"),
            help = "%(prog)s's saying (default: %(default)s)")
    expect_equal(parser$parse_args("--hello=bar"), list(saying = "bar"))
    expect_error(parser$parse_args("--hello=what"))

    # Unhelpful error message found by Martí Duran Ferrer
    parser <- ArgumentParser()
    parser$add_argument("M", required = TRUE, help = "Test")
    expect_error(parser$parse_args(), "python error")

    # Unhelpful error message found by Alex Reinhart
    parser <- ArgumentParser("positional_argument")
    expect_error(parser$parse_args(), "Positional argument following keyword argument.")

    # bug reported by Dominik Mueller
    p <- argparse::ArgumentParser()
    p$add_argument("--int", type = "integer")
    p$add_argument("--double", type = "double")
    p$add_argument("--character", type = "character")

    input <- "1"
    args <- p$parse_args(c("--int", input,
                           "--double", input,
                           "--character", input))
    expect_equal(class(args$int), "integer")
    expect_equal(class(args$double), "numeric")
    expect_equal(class(args$character), "character")
    expect_equal(args$int, as.integer(1.0))
    expect_equal(args$double, 1.0)
    expect_equal(args$character, "1")

    # Bug found by Taylor Pospisil
    skip_on_cran() # Once gave an error on win-builder
    parser <- ArgumentParser()
    parser$add_argument("--lotsofstuff", type = "character", nargs = "+")
    args <- parser$parse_args(c("--lotsofstuff", rep("stuff", 1000)))
    expect_equal(args$lotsofstuff, rep("stuff", 1000))
})

# Bug found by Erick Rocha Fonseca
context("Unicode arguments/options")
test_that("Unicode support works if Python and OS sufficient", {
    skip_on_os("windows") # Didn't work on win-builder
    skip_on_cran() # Didn't work on Debian Clang
    did_find_python3 <- findpython::can_find_python_cmd(minimum_version = "3.0",
                                    required_modules = c("argparse", "json|simplejson"),
                                    silent = TRUE)
    if (!did_find_python3) skip("Need at least Python 3.0 for Unicode support")
    p <- ArgumentParser(python_cmd = attr(did_find_python3, "python_cmd"))
    p$add_argument("name")
    expect_equal(p$parse_args("\u8292\u679C"), list(name = "\u8292\u679C")) # 芒果
})
test_that("Unicode attempt throws error if Python or OS not sufficient", {
    skip_on_os("windows") # Didn't work on AppVeyor
    skip_on_cran() # Didn't work on Debian Clang
    did_find_python2 <- findpython::can_find_python_cmd(maximum_version = "2.7",
                                    required_modules = c("argparse", "json|simplejson"),
                                    silent = TRUE)
    if (!did_find_python2) skip("Need Python 2 to guarantee throws Unicode error")
    p <- ArgumentParser(python_cmd = attr(did_find_python2, "python_cmd"))
    p$add_argument("name")
    expect_error(p$parse_args("\u8292\u679C"), "Non-ASCII character detected.") # 芒果

})

# Mutually exclusive groups is a feature request by Vince Reuter
context("Mutually exclusive groups")
test_that("mutually exclusive groups works as expected", {
    parser <- ArgumentParser(prog = "PROG")
    group <- parser$add_mutually_exclusive_group()
    group$add_argument("--foo", action = "store_true")
    group$add_argument("--bar", action = "store_false")
    arguments <- parser$parse_args("--foo")
    expect_true(arguments$bar)
    expect_true(arguments$foo)
    arguments <- parser$parse_args("--bar")
    expect_false(arguments$bar)
    expect_false(arguments$foo)
    expect_error(parser$parse_args(c("--foo", "--bar")), "argument --bar: not allowed with argument --foo")

    parser <- ArgumentParser(prog = "PROG")
    group <- parser$add_mutually_exclusive_group(required = TRUE)
    group$add_argument("--foo", action = "store_true")
    group$add_argument("--bar", action = "store_false")
    expect_error(parser$parse_args(character()), " one of the arguments --foo --bar is required")
})

# argument groups is a feature request by Dario Beraldi
context("Add argument group")
test_that("add argument group works as expected", {
    parser <- ArgumentParser(prog = "PROG", add_help = FALSE)
    group1 <- parser$add_argument_group("group1", "group1 description")
    group1$add_argument("foo", help = "foo help")
    group2 <- parser$add_argument_group("group2", "group2 description")
    group2$add_argument("--bar", help = "bar help")
    expect_output(parser$print_help(), "group1 description")
    expect_output(parser$print_help(), "group2 description")
})

# subparser support is a feature request by Zebulun Arendsee
context("Supparser support")
test_that("sub parsers work as expected", {
    # create the top-level parser
    parser <- ArgumentParser(prog = "PROG")
    parser$add_argument("--foo", action = "store_true", help = "foo help")
    subparsers <- parser$add_subparsers(help = "sub-command help")

    # create the parser for the "a" command
    parser_a <- subparsers$add_parser("a", help = "a help")
    parser_a$add_argument("bar", type = "integer", help = "bar help")

    # create the parser for the "b" command
    parser_b <- subparsers$add_parser("b", help = "b help")
    parser_b$add_argument("--baz", choices = "XYZ", help = "baz help")

    # parse some argument lists
    arguments <- parser$parse_args(c("a", "12"))
    expect_equal(arguments$bar, 12)
    expect_equal(arguments$foo, FALSE)
    arguments <- parser$parse_args(c("--foo", "b", "--baz", "Z"))
    expect_equal(arguments$baz, "Z")
    expect_equal(arguments$foo, TRUE)
    expect_output(parser$print_help(), "sub-command help")
    expect_output(parser_a$print_help(), "usage: PROG a")
    expect_output(parser_b$print_help(), "usage: PROG b")
})
