# frozen_string_literal: true

require 'test_helper'

class TestDeliEvaluator < Minitest::Test
  def setup
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @orig_stdout
  end

  def test_var
    evaluate('var bloop = 123; print bloop;')

    assert_equal("123\n", $stdout.string)
  end

  def test_assign
    evaluate('var bloop = 100; bloop = 200; print bloop;')

    assert_equal("200\n", $stdout.string)
  end

  def test_assign_unknown
    error = assert_raises(Deli::LocatableError) { evaluate('r = 100;') }

    assert_equal('Unknown name: r', error.short_message)
  end

  def test_if_without_else_true
    evaluate('if 2 < 3 { print 100; }')

    assert_equal("100\n", $stdout.string)
  end

  def test_if_without_else_false
    evaluate('if 2 > 3 { print 100; }')

    assert_equal('', $stdout.string)
  end

  def test_if_with_else
    evaluate('if 2 < 3 { print 100; } else { print 200; }')

    assert_equal("100\n", $stdout.string)
  end

  def test_if_scope
    evaluate('var a = 100; if 2 < 3 { var a = 200; print a; } print a;')

    assert_equal("200\n100\n", $stdout.string)
  end

  def test_while
    evaluate('var a = 0; while a < 5 { print a; a = a + 1; }')

    assert_equal("0\n1\n2\n3\n4\n", $stdout.string)
  end

  def test_fun_no_params_no_return
    evaluate('fun print_hundred() { print 100; } print_hundred();')

    assert_equal("100\n", $stdout.string)
  end

  def test_unary
    evaluate('var bloop = -10; print bloop;')

    assert_equal("-10\n", $stdout.string)
  end

  def test_binary
    evaluate('var bloop = 10 + 25; print bloop;')

    assert_equal("35\n", $stdout.string)
  end

  def test_unary_and_binary
    evaluate('var bloop = -10 + 25; print bloop;')

    assert_equal("15\n", $stdout.string)
  end

  def test_unary_basic
    evaluate('print true; print false; print null;')

    assert_equal("true\nfalse\nnull\n", $stdout.string)
  end

  def test_unary_operator
    evaluate('print !true; print !false; print !null;')

    assert_equal("false\ntrue\ntrue\n", $stdout.string)
  end

  def test_binary_operator
    evaluate('print 2+3; print 2-3; print 2*3; print 8/3;')

    assert_equal("5\n-1\n6\n2\n", $stdout.string)
  end

  def test_binary_relational_operator
    evaluate('print 2<3; print 2<=3; print 2>3; print 2>=3;')

    assert_equal("true\ntrue\nfalse\nfalse\n", $stdout.string)
  end

  private

  def evaluate(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(source_code, tokens).call
    Deli::Evaluator.new(source_code, stmts).call
  end
end
