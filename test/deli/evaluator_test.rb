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

  def test_fun_arg_mismatch
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      fun z(a) {
        return 123;
      }

      z();
    CODE

    assert_equal('Argument count mismatch: expected 1 argument(s), but 0 given', error.message)
  end

  def test_fun_arg_mismatch_builtin
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      import core;

      core::toUpper();
    CODE

    assert_equal('Argument count mismatch: expected 1 argument(s), but 0 given', error.message)
  end

  def test_fun_non_callable
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      var z = 123;
      z();
    CODE

    assert_equal('Cannot call Integer: not a callable', error.message)
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

  def test_struct_empty
    evaluate(<<~CODE)
      struct Person {}
      var denis = new Person();
      print denis;
    CODE

    assert_equal("a Person()\n", $stdout.string)
  end

  def test_struct_kwargs
    evaluate(<<~CODE)
      struct Person {
        firstName,
        lastName,
      }

      var denis = new Person(firstName="Denis", lastName="Defreyne");
      print denis;
    CODE

    assert_equal("a Person(firstName=\"Denis\", lastName=\"Defreyne\")\n", $stdout.string)
  end

  def test_struct_kwargs_missing
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      struct Person {
        firstName,
        lastName,
      }

      var denis = new Person(firstName="Denis");
      print denis;
    CODE

    assert_equal('Required prop not specified: lastName', error.message)
  end

  def test_struct_kwargs_superfluous
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      struct Person {
        name,
      }

      var denis = new Person(name="Denis", job="Entreprenernneneurr");
      print denis;
    CODE

    assert_equal('Unknown prop specified: job', error.message)
  end

  def test_dot_instance_ok
    evaluate(<<~CODE)
      struct Person {
        name,
      }

      var denis = new Person(name="Denis");
      print denis.name;
    CODE

    assert_equal("Denis\n", $stdout.string)
  end

  def test_dot_instance_no_such_prop
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      struct Person {
        name,
      }

      var denis = new Person(name="Denis");
      print denis.fav_hobby;
    CODE

    assert_equal('No such property: fav_hobby', error.message)
  end

  def test_dot_non_instance
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      var denis = 100;
      print denis.name;
    CODE

    assert_equal('Cannot get property of something that is not a struct instance', error.message)
  end

  def test_dot_instance_assign
    evaluate(<<~CODE)
      struct Person {
        name,
      }

      var denis = new Person(name="Denis Defreyne");
      print denis.name;
      denis.name = "Denis Villeneuve";
      print denis.name;
    CODE

    assert_equal("Denis Defreyne\nDenis Villeneuve\n", $stdout.string)
  end

  def test_dot_method
    evaluate(<<~CODE)
      struct Person {
        name,

        fun who() {
          return this.name;
        }
      }

      var denis = new Person(name="Denis Defreyne");
      print denis.who();
    CODE

    assert_equal("Denis Defreyne\n", $stdout.string)
  end

  def test_import_core
    evaluate(<<~CODE)
      import core;

      print core::toUpper("Denis");
    CODE

    assert_equal("DENIS\n", $stdout.string)
  end

  def test_namespace_nonexistant
    error = assert_raises(Deli::LocatableError) { evaluate(<<~CODE) }
      import core;

      print core::abcdefg();
    CODE

    assert_equal('Namespace “core” does not export “abcdefg”', error.message)
  end

  def test_list
    evaluate(<<~CODE)
      print [1, 2, [3, 4]];
    CODE

    assert_equal("[1, 2, [3, 4]]\n", $stdout.string)
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
