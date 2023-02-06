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

  def test_unary
    evaluate('var bloop = -10; print bloop;')

    assert_equal("-10\n", $stdout.string)
  end

  def test_binary
    evaluate('var bloop = 10 + 25; print bloop;')

    assert_equal("35\n", $stdout.string)
  end

  private

  def evaluate(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(source_code, tokens).call
    Deli::Evaluator.new(source_code, stmts).call
  end
end
