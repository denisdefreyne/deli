# frozen_string_literal: true

module Deli
  class Lexer
    class TrackingStringScanner
      def initialize(source_code)
        @scanner = StringScanner.new(source_code.string)
        @filename = source_code.filename

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
        Span.new(@filename, @prev_row, @prev_col, matched.length)
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
      @scanner = TrackingStringScanner.new(source_code)
    end

    def call
      tokens = []
      while (t = lex_token)
        tokens << t
      end

      # Add EOF token
      @scanner.scan('')
      tokens << new_token(TokenType::EOF)

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
        new_token(TokenType::EQ_EQ)
      elsif @scanner.scan('!=')
        new_token(TokenType::BANG_EQ)
      elsif @scanner.scan('<=')
        new_token(TokenType::LTE)
      elsif @scanner.scan('>=')
        new_token(TokenType::GTE)

      # One-character tokens
      elsif @scanner.scan('+')
        new_token(TokenType::PLUS)
      elsif @scanner.scan('-')
        new_token(TokenType::MINUS)
      elsif @scanner.scan('*')
        new_token(TokenType::ASTERISK)
      elsif @scanner.scan('/')
        new_token(TokenType::SLASH)
      elsif @scanner.scan('<')
        new_token(TokenType::LT)
      elsif @scanner.scan('>')
        new_token(TokenType::GT)
      elsif @scanner.scan(',')
        new_token(TokenType::COMMA)
      elsif @scanner.scan(';')
        new_token(TokenType::SEMICOLON)
      elsif @scanner.scan('=')
        new_token(TokenType::EQ)
      elsif @scanner.scan('!')
        new_token(TokenType::BANG)
      elsif @scanner.scan('(')
        new_token(TokenType::LPAREN)
      elsif @scanner.scan(')')
        new_token(TokenType::RPAREN)
      elsif @scanner.scan('{')
        new_token(TokenType::LBRACE)
      elsif @scanner.scan('}')
        new_token(TokenType::RBRACE)
      elsif @scanner.scan('[')
        new_token(TokenType::LBRACKET)
      elsif @scanner.scan(']')
        new_token(TokenType::RBRACKET)

      # Values
      elsif @scanner.scan(/\d+/)
        new_token(TokenType::NUMBER, @scanner.matched)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched

        # Keywords
        when 'true'
          new_token(TokenType::KW_TRUE)
        when 'false'
          new_token(TokenType::KW_FALSE)
        when 'null'
          new_token(TokenType::KW_NULL)
        when 'print'
          new_token(TokenType::KW_PRINT)
        when 'if'
          new_token(TokenType::KW_IF)
        when 'else'
          new_token(TokenType::KW_ELSE)
        when 'fun'
          new_token(TokenType::KW_FUN)
        when 'return'
          new_token(TokenType::KW_RETURN)
        when 'while'
          new_token(TokenType::KW_WHILE)
        when 'for'
          new_token(TokenType::KW_FOR)
        when 'var'
          new_token(TokenType::KW_VAR)

        # Identifier
        else
          new_token(TokenType::IDENT, @scanner.matched)
        end
      else
        char = @scanner.getch
        raise Deli::LocatableError.new(
          "Unknown character: #{char}",
          @scanner.span,
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
