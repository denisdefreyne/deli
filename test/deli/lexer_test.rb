# frozen_string_literal: true

require 'test_helper'

class TestDeliLexer < Minitest::Test
  def test_numbers
    tokens = lex('0 1 123 -8')

    assert_token(:NUMBER, '0',   '0',   tokens.shift)
    assert_token(:NUMBER, '1',   '1',   tokens.shift)
    assert_token(:NUMBER, '123', '123', tokens.shift)
    assert_token(:MINUS,  '-',   nil,   tokens.shift)
    assert_token(:NUMBER, '8',   '8',   tokens.shift)
    assert_token(:EOF,    '',    nil,   tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_binary_operators
    tokens = lex('+ - * /')

    assert_token(:PLUS,     '+', nil, tokens.shift)
    assert_token(:MINUS,    '-', nil, tokens.shift)
    assert_token(:ASTERISK, '*', nil, tokens.shift)
    assert_token(:SLASH,    '/', nil, tokens.shift)
    assert_token(:EOF,      '',  nil, tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_pairs
    tokens = lex('[]{}<>()')

    assert_token(:LBRACKET, '[', nil, tokens.shift)
    assert_token(:RBRACKET, ']', nil, tokens.shift)
    assert_token(:LBRACE,   '{', nil, tokens.shift)
    assert_token(:RBRACE,   '}', nil, tokens.shift)
    assert_token(:LT,       '<', nil, tokens.shift)
    assert_token(:GT,       '>', nil, tokens.shift)
    assert_token(:LPAREN,   '(', nil, tokens.shift)
    assert_token(:RPAREN,   ')', nil, tokens.shift)
    assert_token(:EOF,      '',  nil, tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_relational_operators
    tokens = lex('= == != < <= > >=')

    assert_token(:EQ,      '=',  nil, tokens.shift)
    assert_token(:EQ_EQ,   '==', nil, tokens.shift)
    assert_token(:BANG_EQ, '!=', nil, tokens.shift)
    assert_token(:LT,      '<',  nil, tokens.shift)
    assert_token(:LTE,     '<=', nil, tokens.shift)
    assert_token(:GT,      '>',  nil, tokens.shift)
    assert_token(:GTE,     '>=', nil, tokens.shift)
    assert_token(:EOF,     '',   nil, tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_keywords_and_idents
    tokens = lex('if else for while fun struct return true false null gecko serif format')

    assert_token(:KW_IF,      'if',     nil,      tokens.shift)
    assert_token(:KW_ELSE,    'else',   nil,      tokens.shift)
    assert_token(:KW_FOR,     'for',    nil,      tokens.shift)
    assert_token(:KW_WHILE,   'while',  nil,      tokens.shift)
    assert_token(:KW_FUN,     'fun',    nil,      tokens.shift)
    assert_token(:KW_STRUCT,  'struct', nil,      tokens.shift)
    assert_token(:KW_RETURN,  'return', nil,      tokens.shift)
    assert_token(:KW_TRUE,    'true',   nil,      tokens.shift)
    assert_token(:KW_FALSE,   'false',  nil,      tokens.shift)
    assert_token(:KW_NULL,    'null',   nil,      tokens.shift)
    assert_token(:IDENT,      'gecko',  'gecko',  tokens.shift)
    assert_token(:IDENT,      'serif',  'serif',  tokens.shift)
    assert_token(:IDENT,      'format', 'format', tokens.shift)
    assert_token(:EOF,        '',       nil,      tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_idents
    tokens = lex('doit do_it doit123')

    assert_token(:IDENT, 'doit',    'doit',    tokens.shift)
    assert_token(:IDENT, 'do_it',   'do_it',   tokens.shift)
    assert_token(:IDENT, 'doit123', 'doit123', tokens.shift)
    assert_token(:EOF,   '',        nil,       tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_string_basic
    tokens = lex('"stuff"')

    assert_token(:STRING_START,    '"',     nil,     tokens.shift)
    assert_token(:STRING_PART_LIT, 'stuff', 'stuff', tokens.shift)
    assert_token(:STRING_END,      '"',     nil,     tokens.shift)
    assert_token(:EOF,             '',      nil,     tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_string_escape
    tokens = lex('"abc \" xyz"')

    assert_token(:STRING_START,    '"',    nil,     tokens.shift)
    assert_token(:STRING_PART_LIT, 'abc ', 'abc ',  tokens.shift)
    assert_token(:STRING_PART_LIT, '\\"',  '"',     tokens.shift)
    assert_token(:STRING_PART_LIT, ' xyz', ' xyz',  tokens.shift)
    assert_token(:STRING_END,      '"',    nil,     tokens.shift)
    assert_token(:EOF,             '',     nil,     tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_string_dollar
    tokens = lex('"a$z"')

    assert_token(:STRING_START,    '"', nil,  tokens.shift)
    assert_token(:STRING_PART_LIT, 'a', 'a',  tokens.shift)
    assert_token(:STRING_PART_LIT, '$', '$',  tokens.shift)
    assert_token(:STRING_PART_LIT, 'z', 'z',  tokens.shift)
    assert_token(:STRING_END,      '"', nil,  tokens.shift)
    assert_token(:EOF,             '',  nil,  tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_string_interpolation
    tokens = lex('"abc ${12+34} xyz"')

    assert_token(:STRING_START,         '"',    nil,    tokens.shift)
    assert_token(:STRING_PART_LIT,      'abc ', 'abc ', tokens.shift)
    assert_token(:STRING_INTERP_START,  '${',   nil,    tokens.shift)
    assert_token(:NUMBER,               '12',   '12',   tokens.shift)
    assert_token(:PLUS,                 '+',    nil,    tokens.shift)
    assert_token(:NUMBER,               '34',   '34',   tokens.shift)
    assert_token(:STRING_INTERP_END,    '}',    nil,    tokens.shift)
    assert_token(:STRING_PART_LIT,      ' xyz', ' xyz', tokens.shift)
    assert_token(:STRING_END,           '"',    nil,    tokens.shift)
    assert_token(:EOF,                  '',     nil,    tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_error
    error = assert_raises(Deli::LocatableError) { lex('#') }

    assert_equal('Unknown character: #', error.message)
  end

  private

  def lex(string)
    source_code = Deli::SourceCode.new('(test)', string)
    Deli::Lexer.new(source_code).call
  end

  def assert_token(expected_type_symbol, expected_lexeme, expected_value, token)
    assert_equal(Deli::Token, token.class)

    assert_equal(expected_type_symbol, token.type.symbol)
    assert_equal(expected_lexeme, token.lexeme)

    if expected_value
      assert_equal(expected_value, token.value)
    else
      assert_nil(token.value)
    end
  end
end
