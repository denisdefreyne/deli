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

    assert_equal('(print (ident "zing"))', stmts.shift.inspect)
    assert_equal('(print (integer 123))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_assign
    stmts = parse('var bloop = 123; bloop = 234;')

    assert_equal('(var "bloop" (integer 123))', stmts.shift.inspect)
    assert_equal('(expr (assign (ident "bloop") (integer 234)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_if_without_else
    stmts = parse('if 2 < 3 { print 100; }')

    assert_equal('(if (binary LT (integer 2) (integer 3)) (group (print (integer 100))) nil)', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_if_with_else
    stmts = parse('if 2 < 3 { print 100; } else { print 200; }')

    assert_equal('(if (binary LT (integer 2) (integer 3)) (group (print (integer 100))) (group (print (integer 200))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_while
    stmts = parse('while a { a = !a; }')

    assert_equal('(while (ident "a") (group (expr (assign (ident "a") (unary BANG (ident "a"))))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_no_params_no_return
    stmts = parse('fun print_hundred() { print 100; }')

    assert_equal('(fun "print_hundred" (group (print (integer 100))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_one_param
    stmts = parse('fun foo(a) {}')

    assert_equal('(fun "foo" (param "a") (group))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_two_params
    stmts = parse('fun foo(a, b) {}')

    assert_equal('(fun "foo" (param "a") (param "b") (group))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_def_bad_a
    error = assert_raises(Deli::LocatableError) { parse('fun foo(,) {}') }

    assert_equal('parse error: expected identifier (IDENT), but got “,” (COMMA)', error.message)
  end

  def test_fun_def_trailing_comma
    stmts = parse('fun foo(a,) {}')

    assert_equal('(fun "foo" (param "a") (group))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_no_params_no_return
    stmts = parse('print_hundred();')

    assert_equal('(expr (call (ident "print_hundred")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_one_param
    stmts = parse('thing(1);')

    assert_equal('(expr (call (ident "thing") (integer 1)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_two_params
    stmts = parse('thing(1, 2);')

    assert_equal('(expr (call (ident "thing") (integer 1) (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_call_broken_a
    error = assert_raises(Deli::LocatableError) { parse('thing(,)') }

    assert_equal('parse error: unexpected “,” (COMMA)', error.message)
  end

  def test_fun_call_trailing_comma
    stmts = parse('thing(1,);')

    assert_equal('(expr (call (ident "thing") (integer 1)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_fun_return
    stmts = parse('fun hundred() { return 100; }')

    assert_equal('(fun "hundred" (group (return (integer 100))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_empty
    stmts = parse('struct Person {}')

    assert_equal('(struct "Person")', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_one_prop
    stmts = parse('struct Person { name }')

    assert_equal('(struct "Person" (prop "name"))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_one_prop_trailing_comma
    stmts = parse('struct Person { name, }')

    assert_equal('(struct "Person" (prop "name"))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_two_props
    stmts = parse('struct Person { firstName, lastName }')

    assert_equal('(struct "Person" (prop "firstName") (prop "lastName"))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_initialize_empty
    stmts = parse(<<~CODE)
      struct Person {}
      var denis = new Person();
    CODE

    assert_equal('(struct "Person")', stmts.shift.inspect)
    assert_equal('(var "denis" (new "Person"))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_initialize_one_prop
    stmts = parse(<<~CODE)
      struct Person {
        name,
      }

      var denis = new Person(name="Denis");
    CODE

    assert_equal('(struct "Person" (prop "name"))', stmts.shift.inspect)
    assert_equal('(var "denis" (new "Person" (kwarg "name" (string (string_part_lit "Denis")))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_initialize_two_props
    stmts = parse(<<~CODE)
      struct Person {
        firstName,
        lastName,
      }

      var denis = new Person(firstName="Denis", lastName="Defreyne");
    CODE

    assert_equal('(struct "Person" (prop "firstName") (prop "lastName"))', stmts.shift.inspect)
    assert_equal('(var "denis" (new "Person" (kwarg "firstName" (string (string_part_lit "Denis"))) (kwarg "lastName" (string (string_part_lit "Defreyne")))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_prop
    stmts = parse(<<~CODE)
      print person.name;
    CODE

    assert_equal('(print (dot (ident "person") "name"))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_prop_assign
    stmts = parse(<<~CODE)
      person.name = "Denis";
    CODE

    assert_equal('(expr (assign (dot (ident "person") "name") (string (string_part_lit "Denis"))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_prop_assign_twice
    stmts = parse(<<~CODE)
      person.name.full = "Denis";
    CODE

    assert_equal('(expr (assign (dot (dot (ident "person") "name") "full") (string (string_part_lit "Denis"))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_struct_method_def
    stmts = parse(<<~CODE)
      struct Person {
        firstName,
        lastName,

        fun toString() {
          return self.firstName;
        }

        fun fullName() {
          return self.firstName;
        }
      }
    CODE

    assert_equal('(struct "Person" (prop "firstName") (prop "lastName") (fun "toString" (group (return (dot (ident "self") "firstName")))) (fun "fullName" (group (return (dot (ident "self") "firstName")))))', stmts.shift.inspect)
  end

  def test_struct_method_call_zero_args
    stmts = parse(<<~CODE)
      thing.show();
    CODE

    assert_equal('(expr (call (dot (ident "thing") "show")))', stmts.shift.inspect)
  end

  def test_struct_method_call_some_args
    stmts = parse(<<~CODE)
      thing.show(10, 20);
    CODE

    assert_equal('(expr (call (dot (ident "thing") "show") (integer 10) (integer 20)))', stmts.shift.inspect)
  end

  def test_unary_basic
    stmts = parse('print bla; print 123; print true; print false; print null;')

    assert_equal('(print (ident "bla"))', stmts.shift.inspect)
    assert_equal('(print (integer 123))', stmts.shift.inspect)
    assert_equal('(print (true))', stmts.shift.inspect)
    assert_equal('(print (false))', stmts.shift.inspect)
    assert_equal('(print (null))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_unary_operators
    stmts = parse('print -4; print --++8; print !false;')

    assert_equal('(print (unary MINUS (integer 4)))', stmts.shift.inspect)
    assert_equal('(print (unary MINUS (unary MINUS (unary PLUS (unary PLUS (integer 8))))))', stmts.shift.inspect)
    assert_equal('(print (unary BANG (false)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_equality
    stmts = parse('print a == 123; print a != 234;')

    assert_equal('(print (binary EQ_EQ (ident "a") (integer 123)))', stmts.shift.inspect)
    assert_equal('(print (binary BANG_EQ (ident "a") (integer 234)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_comparison
    stmts = parse('print a < 1; print a <= 2; print a > 3; print a >= 4;')

    assert_equal('(print (binary LT (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary LTE (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_equal('(print (binary GT (ident "a") (integer 3)))', stmts.shift.inspect)
    assert_equal('(print (binary GTE (ident "a") (integer 4)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_term
    stmts = parse('print a + 1; print a - 2;')

    assert_equal('(print (binary PLUS (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary MINUS (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_factor
    stmts = parse('print a * 1; print a / 2;')

    assert_equal('(print (binary ASTERISK (ident "a") (integer 1)))', stmts.shift.inspect)
    assert_equal('(print (binary SLASH (ident "a") (integer 2)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_binary_precedence_term_factor
    stmts = parse('print 1 + 2 * 3;')

    assert_equal('(print (binary PLUS (integer 1) (binary ASTERISK (integer 2) (integer 3))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string
    stmts = parse('print "Hello, world!";')

    assert_equal('(print (string (string_part_lit "Hello, world!")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string_escape
    stmts = parse('print "Hello\\"world!";')

    assert_equal('(print (string (string_part_lit "Hello") (string_part_lit "\\"") (string_part_lit "world!")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string_dollar
    stmts = parse('print "$USD";')

    assert_equal('(print (string (string_part_lit "$") (string_part_lit "USD")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string_interpolate
    stmts = parse('print "a${10}b";')

    assert_equal('(print (string (string_part_lit "a") (string_part_interp (integer 10)) (string_part_lit "b")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_string_interpolate_nested
    stmts = parse('print "a${"${10}"}b";')

    assert_equal('(print (string (string_part_lit "a") (string_part_interp (string (string_part_interp (integer 10)))) (string_part_lit "b")))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_empty
    stmts = parse('var things = [];')

    assert_equal('(var "things" (list))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_one_elem
    stmts = parse('var things = [100];')

    assert_equal('(var "things" (list (integer 100)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_one_elem_trailing_comma
    stmts = parse('var things = [100,];')

    assert_equal('(var "things" (list (integer 100)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_two_elem
    stmts = parse('var things = [100, 200];')

    assert_equal('(var "things" (list (integer 100) (integer 200)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_two_elem_trailing_comma
    stmts = parse('var things = [100, 200,];')

    assert_equal('(var "things" (list (integer 100) (integer 200)))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_list_nested
    stmts = parse('var things = [100, [200, [[300]]]];')

    assert_equal('(var "things" (list (integer 100) (list (integer 200) (list (list (integer 300))))))', stmts.shift.inspect)
    assert_nil(stmts.shift)
  end

  def test_error_unknown_infix
    error = assert_raises(Deli::LocatableError) { parse('var x = a var b') }

    assert_equal('parse error: expected “;” (SEMICOLON), but got “var” (KW_VAR)', error.message)
  end

  def test_error_unsupported_infix
    error = assert_raises(Deli::LocatableError) { parse('var x = a ! b') }

    assert_equal('parse error: “!” (BANG) cannot be used as an infix operator', error.message)
  end

  def test_error_unknown_prefix
    error = assert_raises(Deli::LocatableError) { parse('var x = var b') }

    assert_equal('parse error: unexpected “var” (KW_VAR)', error.message)
  end

  def test_error_unsupported_prefix
    error = assert_raises(Deli::LocatableError) { parse('var x = < 1') }

    assert_equal('parse error: unexpected “<” (LT)', error.message)
  end

  def test_error_end_of_input_a
    error = assert_raises(Deli::LocatableError) { parse('var x = 123') }

    assert_equal('parse error: expected “;” (SEMICOLON), but got end of input (EOF)', error.message)
  end

  def test_error_end_of_input_b
    error = assert_raises(Deli::LocatableError) { parse('var x =') }

    assert_equal('parse error: unexpected end of input (EOF)', error.message)
  end

  private

  def parse(string)
    source_code = Deli::SourceCode.new('(test)', string)
    tokens = Deli::Lexer.new(source_code).call
    Deli::Parser.new(tokens).call
  end
end
