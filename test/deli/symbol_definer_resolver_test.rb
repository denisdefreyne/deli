# frozen_string_literal: true

require 'test_helper'

class TestDeliSymbolDefinerResolver < Minitest::Test
  def test_var
    stmts = runx('var bloop = 123; print bloop;')

    bloop_sym = stmts[0].scope['bloop']

    assert_equal('bloop', bloop_sym.name)
    assert_equal(bloop_sym, stmts[1].expr.symbol)
  end

  private

  def runx(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(source_code, tokens).call
    Deli::SymbolDefiner.new(source_code, stmts).call
    Deli::SymbolResolver.new(source_code, stmts).call
    stmts
  end
end
