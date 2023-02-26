# frozen_string_literal: true

require 'test_helper'

class TestDeliStdlib < Minitest::Test
  def setup
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @orig_stdout
  end

  def test_core_to_upper
    evaluate(<<~CODE)
      import core;

      print core::toUpper("Denis");
    CODE

    assert_equal("DENIS\n", $stdout.string)
  end

  def test_core_exit
    assert_raises(SystemExit) do
      evaluate(<<~CODE)
        import core;

        print core::exit(1);
      CODE
    end
  end

  private

  def evaluate(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(tokens).call
    Deli::SymbolDefiner.new(stmts).call
    Deli::SymbolResolver.new(stmts).call
    Deli::Evaluator.new(stmts).call
  end
end
