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
      elsif @scanner.scan_newline
        lex_token
      elsif @scanner.scan(/[^\S\n]+/)
        lex_token
      elsif @scanner.scan("+")
        Token.new(:PLUS, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan("*")
        Token.new(:TIMES, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan("-")
        Token.new(:MINUS, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan("/")
        Token.new(:DIVIDE, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan(";")
        Token.new(:SEMICOLON, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan("=")
        Token.new(:EQUAL, @scanner.matched, nil, @scanner.span)
      elsif @scanner.scan(/\d+/)
        Token.new(:NUMBER, @scanner.matched, @scanner.matched, @scanner.span)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched
        when "var"
          Token.new(:KEYWORD_VAR, @scanner.matched, nil, @scanner.span)
        when "print"
          Token.new(:KEYWORD_PRINT, @scanner.matched, nil, @scanner.span)
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
