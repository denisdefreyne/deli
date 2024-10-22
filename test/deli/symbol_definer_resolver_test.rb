# frozen_string_literal: true

require 'test_helper'

class TestDeliSymbolDefinerResolver < Minitest::Test
  def test_var
    stmts = define_and_resolve('var bloop = 123; print bloop;')

    bloop_sym = stmts[0].scope.resolve('bloop', span)

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.symbol)
  end

  def test_if
    stmts = define_and_resolve('var bloop = 100; if bloop < 10 { print 20; }')

    bloop_sym = stmts[0].scope.resolve('bloop', span)

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].cond_expr.scope.resolve('bloop', span))
    assert_equal(bloop_sym, stmts[1].cond_expr.left_expr.symbol)
  end

  def test_while
    stmts = define_and_resolve('var x = 3; while x < 17 { x = x + 5; }')

    x_sym = stmts[0].scope.resolve('x', span)

    assert_equal('x', x_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(x_sym, stmts[1].cond_expr.scope.resolve('x', span))
    assert_equal(x_sym, stmts[1].cond_expr.left_expr.symbol)
    assert_equal(x_sym, stmts[1].body_stmt.stmts[0].expr.left_expr.symbol)
  end

  def test_fun_and_call
    stmts = define_and_resolve('fun bloop() {} bloop();')

    bloop_sym = stmts[0].scope.resolve('bloop', span)

    assert_equal('bloop', bloop_sym.name)
    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.scope.resolve('bloop', span))
    assert_equal(bloop_sym, stmts[1].expr.callee.symbol)
  end

  def test_return
    stmts = define_and_resolve('var beep = 123; fun bloop() { return beep; }')

    beep_sym = stmts[0].scope.resolve('beep', span)

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(beep_sym, stmts[1].body_stmt.stmts[0].scope.resolve('beep', span))
  end

  def test_true_false_null
    stmts = define_and_resolve('var a = true; var b = false; var c = null;')

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(stmts[0].scope, stmts[2].scope)
  end

  def test_unary
    stmts = define_and_resolve('var beep = true; !beep;')

    beep_sym = stmts[0].scope.resolve('beep', span)

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(beep_sym, stmts[1].expr.scope.resolve('beep', span))
    assert_equal(beep_sym, stmts[1].expr.expr.symbol)
  end

  def test_assign
    stmts = define_and_resolve('var bloop = 100; bloop = 200;')

    bloop_sym = stmts[0].scope.resolve('bloop', span)

    assert_equal(stmts[0].scope, stmts[1].scope)
    assert_equal(bloop_sym, stmts[1].expr.left_expr.symbol)
  end

  def test_struct_empty
    stmts = define_and_resolve('struct Person {}')

    person_sym = stmts[0].scope.resolve('Person', span)

    assert_equal(person_sym, stmts[0].symbol)
  end

  def test_struct_nonempty
    stmts = define_and_resolve('struct Person { firstName, lastName }')

    person_sym = stmts[0].scope.resolve('Person', span)

    assert_equal(person_sym, stmts[0].symbol)
  end

  def test_struct_instantiation
    stmts = define_and_resolve(<<~CODE)
      struct Person {
        firstName,
        lastName
      }

      var denis = new Person(firstName="Denis", lastName="Defreyne");
    CODE

    person_sym = stmts[0].scope.resolve('Person', span)

    assert_equal(person_sym, stmts[0].symbol)
    assert_equal(person_sym, stmts[1].expr.symbol)
  end

  def test_self
    stmts = define_and_resolve(<<~CODE)
      struct Person {
        fun x() {}
      }
    CODE

    method = stmts[0].methods[0]

    person_sym = stmts[0].scope.resolve('Person', span)
    assert_equal(person_sym, stmts[0].symbol)

    this = method.scope.resolve('this', span)
    refute_nil(this)
  end

  private

  def span
    Deli::Span.new('abc.deli', 12, 4)
  end

  def define_and_resolve(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    stmts = Deli::Parser.new(tokens).call
    Deli::SymbolDefiner.new(stmts).call
    Deli::SymbolResolver.new(stmts).call
    stmts
  end
end
