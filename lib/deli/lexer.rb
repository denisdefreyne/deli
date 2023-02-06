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
        Token.new(:EQ_EQ, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('!=')
        Token.new(:BANG_EQ, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('<=')
        Token.new(:LTE, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('>=')
        Token.new(:GTE, @scanner.matched, nil, @scanner.span)

      # One-character tokens
      elsif @scanner.scan('+')
        Token.new(:PLUS, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('-')
        Token.new(:MINUS, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('*')
        Token.new(:ASTERISK, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('/')
        Token.new(:SLASH, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('<')
        Token.new(:LT, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('>')
        Token.new(:GT, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan(';')
        Token.new(:SEMICOLON, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('=')
        Token.new(:EQ, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan('!')
        Token.new(:BANG, @scanner.matched, nil, @scanner.span)

      # Values
      elsif @scanner.scan(/\d+/)
        Token.new(:NUMBER, @scanner.matched, @scanner.matched, @scanner.span)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched
        # Constants
        when 'true'
          Token.new(:KW_TRUE, @scanner.matched, nil, @scanner.span)
        when 'false'
          Token.new(:KW_FALSE, @scanner.matched, nil, @scanner.span)
        # Keywords
        when 'print'
          Token.new(:KW_PRINT, @scanner.matched, nil, @scanner.span)
        when 'if'
          Token.new(:KW_IF, @scanner.matched, nil, @scanner.span)
        when 'then'
          Token.new(:KW_THEN, @scanner.matched, nil, @scanner.span)
        when 'else'
          Token.new(:KW_ELSE, @scanner.matched, nil, @scanner.span)
        when 'for'
          Token.new(:KW_FOR, @scanner.matched, nil, @scanner.span)
        when 'while'
          Token.new(:KW_WHILE, @scanner.matched, nil, @scanner.span)
        when 'var'
          Token.new(:KW_VAR, @scanner.matched, nil, @scanner.span)
        # Identifier
        else
          Token.new(:IDENTIFIER, @scanner.matched, @scanner.matched, @scanner.span)
        end
      else
        char = @scanner.getch
        raise Deli::LocatableError.new(@source_code, @scanner.span, "Unknown character: #{char}")
      end
    end
  end
end
