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

  def test_unary
    stmts = parse('print -4; print --++8;')

    assert_equal('(print (unary - (integer 4)))', stmts.shift.inspect)
    assert_equal('(print (unary - (unary - (unary + (unary + (integer 8))))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary
    stmts = parse('print 1 + 2;')

    assert_equal('(print (binary + (integer 1) (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  private

  def parse(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    Deli::Parser.new(source_code, tokens).call
  end
end
