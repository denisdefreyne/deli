# frozen_string_literal: true

module Deli
  class TokenType
    attr_reader :symbol
    attr_reader :name

    def initialize(symbol, name)
      @symbol = symbol
      @name   = name
    end

    def to_s
      "#{name} (#{symbol})"
    end

    EOF       = TokenType.new(:EOF,       'end of input')

    EQ_EQ     = TokenType.new(:EQ_EQ,     '“==”')
    BANG_EQ   = TokenType.new(:BANG_EQ,   '“!=”')
    LTE       = TokenType.new(:LTE,       '“<=”')
    GTE       = TokenType.new(:GTE,       '“>=”')

    PLUS      = TokenType.new(:PLUS,      '“+”')
    MINUS     = TokenType.new(:MINUS,     '“-”')
    ASTERISK  = TokenType.new(:ASTERISK,  '“*”')
    SLASH     = TokenType.new(:SLASH,     '“/”')
    LT        = TokenType.new(:LT,        '“<”')
    GT        = TokenType.new(:GT,        '“>”')
    COMMA     = TokenType.new(:COMMA,     '“,”')
    SEMICOLON = TokenType.new(:SEMICOLON, '“;”')
    EQ        = TokenType.new(:EQ,        '“=”')
    BANG      = TokenType.new(:BANG,      '“!”')
    LPAREN    = TokenType.new(:LPAREN,    '“(”')
    RPAREN    = TokenType.new(:RPAREN,    '“)”')
    LBRACE    = TokenType.new(:LBRACE,    '“{”')
    RBRACE    = TokenType.new(:RBRACE,    '“}”')
    LBRACKET  = TokenType.new(:LBRACKET,  '“[”')
    RBRACKET  = TokenType.new(:RBRACKET,  '“]”')

    STRING    = TokenType.new(:STRING,    'string')
    NUMBER    = TokenType.new(:NUMBER,    'number')
    IDENT     = TokenType.new(:IDENT,     'identifier')

    KW_TRUE   = TokenType.new(:KW_TRUE,   '“true”')
    KW_FALSE  = TokenType.new(:KW_FALSE,  '“false”')
    KW_NULL   = TokenType.new(:KW_NULL,   '“null”')
    KW_PRINT  = TokenType.new(:KW_PRINT,  '“print”')
    KW_IF     = TokenType.new(:KW_IF,     '“if”')
    KW_ELSE   = TokenType.new(:KW_ELSE,   '“else”')
    KW_FUN    = TokenType.new(:KW_FUN,    '“fun”')
    KW_RETURN = TokenType.new(:KW_RETURN, '“return”')
    KW_WHILE  = TokenType.new(:KW_WHILE,  '“while”')
    KW_FOR    = TokenType.new(:KW_FOR,    '“for”')
    KW_VAR    = TokenType.new(:KW_VAR,    '“var”')
  end
end
