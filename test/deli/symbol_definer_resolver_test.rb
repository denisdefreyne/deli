# frozen_string_literal: true

require 'test_helper'

class TestDeliSymbolDefinerResolver < Minitest::Test
  def test_var
    stmts = define_and_resolve('var bloop = 123; print bloop;')

    bloop_sym = stmts[0].scope['bloop']

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.symbol)
  end

  def test_if
    stmts = define_and_resolve('var bloop = 100; if bloop < 10 { print 20; }')

    bloop_sym = stmts[0].scope['bloop']

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].cond_expr.scope['bloop'])
    assert_equal(bloop_sym, stmts[1].cond_expr.left_expr.symbol)
  end

  def test_while
    stmts = define_and_resolve('var x = 3; while x < 17 { x = x + 5; }')

    x_sym = stmts[0].scope['x']

    assert_equal('x', x_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(x_sym, stmts[1].cond_expr.scope['x'])
    assert_equal(x_sym, stmts[1].cond_expr.left_expr.symbol)
    assert_equal(x_sym, stmts[1].body_stmt.stmts[0].expr.left_expr.symbol)
  end

  def test_fun_and_call
    stmts = define_and_resolve('fun bloop() {} bloop();')

    bloop_sym = stmts[0].scope['bloop']

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.scope['bloop'])
    assert_equal(bloop_sym, stmts[1].expr.callee.symbol)
  end

  def test_return
    stmts = define_and_resolve('var beep = 123; fun bloop() { return beep; }')

    beep_sym = stmts[0].scope['beep']

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(beep_sym, stmts[1].body_stmt.stmts[0].scope['beep'])
  end

  def test_true_false_null
    stmts = define_and_resolve('var a = true; var b = false; var c = null;')

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(stmts[0].scope, stmts[2].scope)
  end

  def test_unary
    stmts = define_and_resolve('var beep = true; !beep;')

    beep_sym = stmts[0].scope['beep']

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(beep_sym, stmts[1].expr.scope['beep'])
    assert_equal(beep_sym, stmts[1].expr.expr.symbol)
  end

  def test_assign
    stmts = define_and_resolve('var bloop = 100; bloop = 200;')

    bloop_sym = stmts[0].scope['bloop']

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.left_expr.symbol)
  end

  private

  def define_and_resolve(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(source_code, tokens).call
    Deli::SymbolDefiner.new(source_code, stmts).call
    Deli::SymbolResolver.new(source_code, stmts).call
    stmts
  end
end
