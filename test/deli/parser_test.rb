# frozen_string_literal: true

require 'test_helper'

class TestDeliParser < Minitest::Test
  def test_var
    stmts = parse('var bloop = 123;')

    assert_equal('(var "bloop" (integer 123))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_print
    stmts = parse('print zing; print 123;')

    assert_equal('(print (ident "zing"))', stmts.shift.inspect)
    assert_equal('(print (integer 123))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_assign
    stmts = parse('var bloop = 123; bloop = 234;')

    assert_equal('(var "bloop" (integer 123))', stmts.shift.inspect)
    assert_equal('(expr (assign (ident "bloop") (integer 234)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_if_without_else
    stmts = parse('if 2 < 3 { print 100; }')

    assert_equal('(if (binary "<" (integer 2) (integer 3)) (group (print (integer 100))) nil)', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_if_with_else
    stmts = parse('if 2 < 3 { print 100; } else { print 200; }')

    assert_equal('(if (binary "<" (integer 2) (integer 3)) (group (print (integer 100))) (group (print (integer 200))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_while
    stmts = parse('while a { a = !a; }')

    assert_equal('(while (ident "a") (group (expr (assign (ident "a") (unary "!" (ident "a"))))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_no_params_no_return
    stmts = parse('fun print_hundred() { print 100; }')

    assert_equal('(fun "print_hundred" (group (print (integer 100))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_one_param
    stmts = parse('fun foo(a) {}')

    assert_equal('(fun "foo" (param "a") (group))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_two_params
    stmts = parse('fun foo(a, b) {}')

    assert_equal('(fun "foo" (param "a") (param "b") (group))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_bad_a
    error = assert_raises(Deli::LocatableError) { parse('fun foo(,) {}') }

    assert_equal('parse error: expected identifier (IDENT), but got “,” (COMMA)', error.message)
  end

  def test_fun_def_bad_b
    error = assert_raises(Deli::LocatableError) { parse('fun foo(a,) {}') }

    assert_equal('parse error: expected identifier (IDENT), but got “)” (RPAREN)', error.message)
  end

  def test_fun_call_no_params_no_return
    stmts = parse('print_hundred();')

    assert_equal('(expr (call (ident "print_hundred")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_one_param
    stmts = parse('thing(1);')

    assert_equal('(expr (call (ident "thing") (integer 1)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_two_params
    stmts = parse('thing(1, 2);')

    assert_equal('(expr (call (ident "thing") (integer 1) (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_broken_a
    error = assert_raises(Deli::LocatableError) { parse('thing(,)') }

    assert_equal('parse error: unexpected “,” (COMMA)', error.message)
  end

  def test_fun_call_broken_b
    error = assert_raises(Deli::LocatableError) { parse('thing(1,)') }

    assert_equal('parse error: unexpected “)” (RPAREN)', error.message)
  end

  def test_fun_return
    stmts = parse('fun hundred() { return 100; }')

    assert_equal('(fun "hundred" (group (return (integer 100))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_unary_basic
    stmts = parse('print bla; print 123; print true; print false; print null;')

    assert_equal('(print (ident "bla"))', stmts.shift.inspect)
    assert_equal('(print (integer 123))', stmts.shift.inspect)
    assert_equal('(print (true))', stmts.shift.inspect)
    assert_equal('(print (false))', stmts.shift.inspect)
    assert_equal('(print (null))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_unary_operators
    stmts = parse('print -4; print --++8; print !false;')

    assert_equal('(print (unary "-" (integer 4)))', stmts.shift.inspect)
    assert_equal('(print (unary "-" (unary "-" (unary "+" (unary "+" (integer 8))))))', stmts.shift.inspect)
    assert_equal('(print (unary "!" (false)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_equality
    stmts = parse('print a == 123; print a != 234;')

    assert_equal('(print (binary "==" (ident "a") (integer 123)))', stmts.shift.inspect)
    assert_equal('(print (binary "!=" (ident "a") (integer 234)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_comparison
    stmts = parse('print a < 1; print a <= 2; print a > 3; print a >= 4;')

    assert_equal('(print (binary "<" (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "<=" (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_equal('(print (binary ">" (ident "a") (integer 3)))', stmts.shift.inspect)
    assert_equal('(print (binary ">=" (ident "a") (integer 4)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_term
    stmts = parse('print a + 1; print a - 2;')

    assert_equal('(print (binary "+" (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "-" (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_factor
    stmts = parse('print a * 1; print a / 2;')

    assert_equal('(print (binary "*" (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "/" (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_precedence_term_factor
    stmts = parse('print 1 + 2 * 3;')

    assert_equal('(print (binary "+" (integer 1) (binary "*" (integer 2) (integer 3))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string
    stmts = parse('print "Hello, world!";')

    assert_equal('(print (string (string_part_lit "Hello, world!")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string_escape
    stmts = parse('print "Hello\\"world!";')

    assert_equal('(print (string (string_part_lit "Hello") (string_part_lit "\\"") (string_part_lit "world!")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_error_unknown_infix
    error = assert_raises(Deli::LocatableError) { parse('var x = a var b') }

    assert_equal('parse error: expected “;” (SEMICOLON), but got “var” (KW_VAR)', error.message)
  end

  def test_error_unsupported_infix
    error = assert_raises(Deli::LocatableError) { parse('var x = a ! b') }

    assert_equal('parse error: “!” (BANG) cannot be used as an infix operator', error.message)
  end

  def test_error_unknown_prefix
    error = assert_raises(Deli::LocatableError) { parse('var x = var b') }

    assert_equal('parse error: unexpected “var” (KW_VAR)', error.message)
  end

  def test_error_unsupported_prefix
    error = assert_raises(Deli::LocatableError) { parse('var x = < 1') }

    assert_equal('parse error: unexpected “<” (LT)', error.message)
  end

  def test_error_end_of_input_a
    error = assert_raises(Deli::LocatableError) { parse('var x = 123') }

    assert_equal('parse error: expected “;” (SEMICOLON), but got end of input (EOF)', error.message)
  end

  def test_error_end_of_input_b
    error = assert_raises(Deli::LocatableError) { parse('var x =') }

    assert_equal('parse error: unexpected end of input (EOF)', error.message)
  end

  private

  def parse(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    Deli::Parser.new(tokens).call
  end
end
