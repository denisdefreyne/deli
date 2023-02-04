module Deli
  class Lexer
    def initialize(source_code)
      @source_code = source_code
      @scanner = StringScanner.new(source_code.string)

      @col = 0
      @row = 0
    end

    def call
      tokens = []
      while (t = lex_token_except_whitespace)
        tokens << t
      end
      tokens
    end

    private

    def lex_token_except_whitespace
      token = lex_token
      return nil unless token

      case token.type
      when :WHITESPACE_NL
        @row += 1
        @col = 0
        lex_token_except_whitespace
      when :WHITESPACE
        @col += token.lexeme.size
        lex_token_except_whitespace
      else
        token.row = @row
        token.col = @col
        @col += token.lexeme.size
        token
      end
    end

    def lex_token
      if @scanner.eos?
        nil
      elsif @scanner.scan(/[\r\n]/)
        Token.new(:WHITESPACE_NL, @scanner.matched, nil)
      elsif @scanner.scan(/\s+/)
        Token.new(:WHITESPACE, @scanner.matched, nil)
      elsif @scanner.scan("+")
        Token.new(:PLUS, @scanner.matched, nil)
      elsif @scanner.scan("*")
        Token.new(:TIMES, @scanner.matched, nil)
      elsif @scanner.scan("-")
        Token.new(:MINUS, @scanner.matched, nil)
      elsif @scanner.scan("/")
        Token.new(:DIVIDE, @scanner.matched, nil)
      elsif @scanner.scan(";")
        Token.new(:SEMICOLON, @scanner.matched, nil)
      elsif @scanner.scan("=")
        Token.new(:EQUAL, @scanner.matched, nil)
      elsif @scanner.scan(/\d+/)
        Token.new(:NUMBER, @scanner.matched, @scanner.matched)
      elsif @scanner.scan(/\w+/)
        case @scanner.matched
        when "var"
          Token.new(:KEYWORD_VAR, @scanner.matched, nil)
        when "print"
          Token.new(:KEYWORD_PRINT, @scanner.matched, nil)
        else
          Token.new(:IDENTIFIER, @scanner.matched, @scanner.matched)
        end
      else
        char = @scanner.getch
        raise Deli::CharLocatableError.new(@source_code, @row, @col, "Unknown character: #{char}")
      end
    end
  end
end
