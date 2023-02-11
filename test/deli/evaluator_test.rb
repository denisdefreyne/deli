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

    assert_equal('Unknown name: r', error.message)
  end

  def test_assign_invalid
    error = assert_raises(Deli::LocatableError) { evaluate('var r = 1; r() = 100;') }

    assert_equal('Left-hand side cannot be assigned to', error.message)
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

  def test_fun_closure
    evaluate('var amount = 150; fun print_amount() { print amount; } print_amount();')

    assert_equal("150\n", $stdout.string)
  end

  def test_fun_no_params_return
    evaluate('fun hundred() { return 100; } print hundred();')

    assert_equal("100\n", $stdout.string)
  end

  def test_fun_params_and_args
    evaluate('fun show(a) { print a; } show(15);')

    assert_equal("15\n", $stdout.string)
  end

  def test_fun_recursive_a
    evaluate(<<~SRC)
      fun plus(a, b) {
        if a > 0 {
          return plus(a - 1, b + 1);
        } else {
          return b;
        }
      }

      print plus(3, 4);
    SRC

    assert_equal("7\n", $stdout.string)
  end

  def test_fun_recursive_b
    evaluate(<<~SRC)
      fun fib(a) {
        if a < 2 {
          return 1;
        }

        return fib(a - 1) + fib(a - 2);
      }

      print fib(5);
      print fib(6);
      print fib(7);
      print fib(8);
    SRC

    assert_equal("8\n13\n21\n34\n", $stdout.string)
  end

  # def test_fun_closures
  #   evaluate(<<~SRC)
  #     var a = 100;

  #     fun bleep() {
  #       fun print_a() {
  #         print a;
  #       }

  #       print_a();
  #       var a = 200;
  #       print_a();
  #     }

  #     bleep();
  #   SRC

  #   assert_equal("100\n100\n", $stdout.string)
  # end

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

  def test_string_basic
    evaluate('print "Hello, world!";')

    assert_equal("Hello, world!\n", $stdout.string)
  end

  def test_string_escape
    evaluate('print "Hello, \\"world\\"!";')

    assert_equal("Hello, \"world\"!\n", $stdout.string)
  end

  def test_string_interpolate
    evaluate('print "a${12+34}z";')

    assert_equal("a46z\n", $stdout.string)
  end

  def test_string_interpolate_nested
    evaluate('print "a${"${10}"}b";')

    assert_equal("a10b\n", $stdout.string)
  end

  def test_string_concat
    evaluate('print "Hello, " + "world!";')

    assert_equal("Hello, world!\n", $stdout.string)
  end

  # FIXME: This should be its own error
  def test_string_minus
    error = assert_raises(NoMethodError) { evaluate('"hello" - "world";') }

    assert_equal("undefined method `-' for \"hello\":String", error.message)
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
