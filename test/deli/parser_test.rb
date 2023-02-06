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

    assert_equal('(print (identifier "zing"))', stmts.shift.inspect)
    assert_equal('(print (integer 123))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_assign
    stmts = parse('var bloop = 123; bloop = 234;')

    assert_equal('(var "bloop" (integer 123))', stmts.shift.inspect)
    assert_equal('(assign "bloop" (integer 234))', stmts.shift.inspect)
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

    assert_equal('(while (identifier "a") (group (assign "a" (unary "!" (identifier "a")))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_unary_basic
    stmts = parse('print bla; print 123; print true; print false; print null;')

    assert_equal('(print (identifier "bla"))', stmts.shift.inspect)
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

    assert_equal('(print (binary "==" (identifier "a") (integer 123)))', stmts.shift.inspect)
    assert_equal('(print (binary "!=" (identifier "a") (integer 234)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_comparison
    stmts = parse('print a < 1; print a <= 2; print a > 3; print a >= 4;')

    assert_equal('(print (binary "<" (identifier "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "<=" (identifier "a") (integer 2)))', stmts.shift.inspect)
    assert_equal('(print (binary ">" (identifier "a") (integer 3)))', stmts.shift.inspect)
    assert_equal('(print (binary ">=" (identifier "a") (integer 4)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_term
    stmts = parse('print a + 1; print a - 2;')

    assert_equal('(print (binary "+" (identifier "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "-" (identifier "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_factor
    stmts = parse('print a * 1; print a / 2;')

    assert_equal('(print (binary "*" (identifier "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary "/" (identifier "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_precedence_term_factor
    stmts = parse('print 1 + 2 * 3;')

    assert_equal('(print (binary "+" (integer 1) (binary "*" (integer 2) (integer 3))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  private

  def parse(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    Deli::Parser.new(source_code, tokens).call
  end
end
