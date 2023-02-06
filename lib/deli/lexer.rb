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
        new_token(:EQ_EQ)
      elsif @scanner.scan('!=')
        new_token(:BANG_EQ)
      elsif @scanner.scan('<=')
        new_token(:LTE)
      elsif @scanner.scan('>=')
        new_token(:GTE)

      # One-character tokens
      elsif @scanner.scan('+')
        new_token(:PLUS)
      elsif @scanner.scan('-')
        new_token(:MINUS)
      elsif @scanner.scan('*')
        new_token(:ASTERISK)
      elsif @scanner.scan('/')
        new_token(:SLASH)
      elsif @scanner.scan('<')
        new_token(:LT)
      elsif @scanner.scan('>')
        new_token(:GT)
      elsif @scanner.scan(';')
        new_token(:SEMICOLON)
      elsif @scanner.scan('=')
        new_token(:EQ)
      elsif @scanner.scan('!')
        new_token(:BANG)

      # Values
      elsif @scanner.scan(/\d+/)
        new_token(:NUMBER, @scanner.matched)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched
        # Keywords
        when 'true'
          new_token(:KW_TRUE)
        when 'false'
          new_token(:KW_FALSE)
        when 'null'
          new_token(:KW_NULL)
        when 'print'
          new_token(:KW_PRINT)
        when 'if'
          new_token(:KW_IF)
        when 'then'
          new_token(:KW_THEN)
        when 'else'
          new_token(:KW_ELSE)
        when 'for'
          new_token(:KW_FOR)
        when 'while'
          new_token(:KW_WHILE)
        when 'var'
          new_token(:KW_VAR)

        # Identifier
        else
          new_token(:IDENTIFIER, @scanner.matched)
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
        type:,
        lexeme: @scanner.matched,
        value:,
        span:   @scanner.span,
      )
    end
  end
end
