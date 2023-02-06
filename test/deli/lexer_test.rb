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
    assert_nil(tokens.shift)
  end

  def test_binary_operators
    tokens = lex('+ - * /')

    assert_token(:PLUS,     '+', nil, tokens.shift)
    assert_token(:MINUS,    '-', nil, tokens.shift)
    assert_token(:ASTERISK, '*', nil, tokens.shift)
    assert_token(:SLASH,    '/', nil, tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_relational_operators
    tokens = lex('= == != < <= > >=')

    assert_token(:EQUAL,                 '=',  nil, tokens.shift)
    assert_token(:EQUAL_EQUAL,           '==', nil, tokens.shift)
    assert_token(:BANG_EQUAL,            '!=', nil, tokens.shift)
    assert_token(:LESS_THAN,             '<',  nil, tokens.shift)
    assert_token(:LESS_THAN_OR_EQUAL,    '<=', nil, tokens.shift)
    assert_token(:GREATER_THAN,          '>',  nil, tokens.shift)
    assert_token(:GREATER_THAN_OR_EQUAL, '>=', nil, tokens.shift)
    assert_nil(tokens.shift)
  end

  def test_keywords_and_identifiers
    tokens = lex('if then else while for true false gecko format')

    assert_token(:KEYWORD_IF,    'if',     nil,      tokens.shift)
    assert_token(:KEYWORD_THEN,  'then',   nil,      tokens.shift)
    assert_token(:KEYWORD_ELSE,  'else',   nil,      tokens.shift)
    assert_token(:KEYWORD_WHILE, 'while',  nil,      tokens.shift)
    assert_token(:KEYWORD_FOR,   'for',    nil,      tokens.shift)
    assert_token(:KEYWORD_TRUE,  'true',   nil,      tokens.shift)
    assert_token(:KEYWORD_FALSE, 'false',  nil,      tokens.shift)
    assert_token(:IDENTIFIER,    'gecko',  'gecko',  tokens.shift)
    assert_token(:IDENTIFIER,    'format', 'format', tokens.shift)
    assert_nil(tokens.shift)
  end

  private

  def lex(string)
    source_code = Deli::SourceCode.new('(test)', string)
    lexer = Deli::Lexer.new(source_code)
    lexer.call
  end

  def assert_token(expected_type, expected_lexeme, expected_value, token)
    assert_equal(Deli::Token, token.class)

    assert_equal(expected_type, token.type)
    assert_equal(expected_lexeme, token.lexeme)

    if expected_value
      assert_equal(expected_value, token.value)
    else
      assert_nil(token.value)
    end
  end
end
