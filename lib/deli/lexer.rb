# frozen_string_literal: true

module Deli
  class Lexer
    class TrackingStringScanner
      def initialize(string)
        @scanner = StringScanner.new(string)

        @prev_row = 0
        @prev_col = 0

        @row = 0
        @col = 0
      end

      def eos?
        @scanner.eos?
      end

      def scan_newline
        res = @scanner.scan(/\n+/)
        return nil if res.nil?

        advance
        @row += res.size
        @col = 0

        res
      end

      def scan(pattern)
        res = @scanner.scan(pattern)
        return nil if res.nil?

        advance
        @col += res.size

        res
      end

      def span
        Span.new(@prev_row, @prev_col, matched.length)
      end

      def matched
        @scanner.matched
      end

      def getch
        res = @scanner.getch
        return nil if res.nil?

        advance
        @col += res.size

        res
      end

      private

      def advance
        @prev_row = @row
        @prev_col = @col
      end
    end

    def initialize(source_code)
      @source_code = source_code
      @scanner = TrackingStringScanner.new(source_code.string)
    end

    def call
      tokens = []
      while (t = lex_token)
        tokens << t
      end

      # Add EOF token
      @scanner.scan('')
      tokens << new_token(TokenTypes::EOF)

      tokens
    end

    private

    def lex_token
      if @scanner.eos?
        nil

      # Whitespace
      elsif @scanner.scan_newline || @scanner.scan(/[^\S\n]+/)
        lex_token

      # Two-character tokens
      elsif @scanner.scan('==')
        new_token(TokenTypes::EQ_EQ)
      elsif @scanner.scan('!=')
        new_token(TokenTypes::BANG_EQ)
      elsif @scanner.scan('<=')
        new_token(TokenTypes::LTE)
      elsif @scanner.scan('>=')
        new_token(TokenTypes::GTE)

      # One-character tokens
      elsif @scanner.scan('+')
        new_token(TokenTypes::PLUS)
      elsif @scanner.scan('-')
        new_token(TokenTypes::MINUS)
      elsif @scanner.scan('*')
        new_token(TokenTypes::ASTERISK)
      elsif @scanner.scan('/')
        new_token(TokenTypes::SLASH)
      elsif @scanner.scan('<')
        new_token(TokenTypes::LT)
      elsif @scanner.scan('>')
        new_token(TokenTypes::GT)
      elsif @scanner.scan(';')
        new_token(TokenTypes::SEMICOLON)
      elsif @scanner.scan('=')
        new_token(TokenTypes::EQ)
      elsif @scanner.scan('!')
        new_token(TokenTypes::BANG)
      elsif @scanner.scan('(')
        new_token(TokenTypes::LPAREN)
      elsif @scanner.scan(')')
        new_token(TokenTypes::RPAREN)
      elsif @scanner.scan('{')
        new_token(TokenTypes::LBRACE)
      elsif @scanner.scan('}')
        new_token(TokenTypes::RBRACE)
      elsif @scanner.scan('[')
        new_token(TokenTypes::LBRACKET)
      elsif @scanner.scan(']')
        new_token(TokenTypes::RBRACKET)

      # Values
      elsif @scanner.scan(/\d+/)
        new_token(TokenTypes::NUMBER, @scanner.matched)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched

        # Keywords
        when 'true'
          new_token(TokenTypes::KW_TRUE)
        when 'false'
          new_token(TokenTypes::KW_FALSE)
        when 'null'
          new_token(TokenTypes::KW_NULL)
        when 'print'
          new_token(TokenTypes::KW_PRINT)
        when 'if'
          new_token(TokenTypes::KW_IF)
        when 'else'
          new_token(TokenTypes::KW_ELSE)
        when 'fun'
          new_token(TokenTypes::KW_FUN)
        when 'return'
          new_token(TokenTypes::KW_RETURN)
        when 'while'
          new_token(TokenTypes::KW_WHILE)
        when 'for'
          new_token(TokenTypes::KW_FOR)
        when 'var'
          new_token(TokenTypes::KW_VAR)

        # Identifier
        else
          new_token(TokenTypes::IDENT, @scanner.matched)
        end
      else
        char = @scanner.getch
        raise Deli::LocatableError.new(
          @source_code,
          @scanner.span,
          "Unknown character: #{char}",
        )
      end
    end

    def new_token(type, value = nil)
      Token.new(
        type: type,
        lexeme: @scanner.matched,
        value: value,
        span: @scanner.span,
      )
    end
  end
end
