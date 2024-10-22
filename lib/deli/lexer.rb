# frozen_string_literal: true

module Deli
  class Lexer
    def initialize(source_code)
      @scanner = StringScanner.new(source_code.string)
      mode = MainLexerMode.new(source_code, @scanner)
      @mode_stack = [mode]
    end

    def call
      tokens = []
      while (t = lex_token)
        tokens << t
      end

      # Add EOF token
      @scanner.scan('')
      tokens << @mode_stack.last.new_token(TokenType::EOF)

      tokens
    end

    def lex_token
      mode = @mode_stack.last
      mode.lex_token(@mode_stack)
    end
  end

  class AbstractLexerMode
    attr_reader :source_code
    attr_reader :scanner

    def initialize(source_code, scanner)
      @source_code = source_code
      @scanner = scanner
    end

    def span
      Span.new(
        @source_code.filename,
        @scanner.charpos - @scanner.matched.length,
        @scanner.matched.length,
      )
    end

    def new_token(type, value = nil)
      Token.new(
        type: type,
        lexeme: @scanner.matched,
        value: value,
        span: span,
      )
    end
  end

  class MainLexerMode < AbstractLexerMode
    def lex_token(mode_stack)
      scanner.skip(/\s+/)

      if scanner.eos?
        nil

      # Two-character tokens
      elsif scanner.scan('==')
        new_token(TokenType::EQ_EQ)
      elsif scanner.scan('!=')
        new_token(TokenType::BANG_EQ)
      elsif scanner.scan('<=')
        new_token(TokenType::LTE)
      elsif scanner.scan('>=')
        new_token(TokenType::GTE)
      elsif scanner.scan('::')
        new_token(TokenType::COLON_COLON)

      # One-character tokens
      elsif scanner.scan('+')
        new_token(TokenType::PLUS)
      elsif scanner.scan('-')
        new_token(TokenType::MINUS)
      elsif scanner.scan('*')
        new_token(TokenType::ASTERISK)
      elsif scanner.scan('/')
        new_token(TokenType::SLASH)
      elsif scanner.scan('<')
        new_token(TokenType::LT)
      elsif scanner.scan('>')
        new_token(TokenType::GT)
      elsif scanner.scan(',')
        new_token(TokenType::COMMA)
      elsif scanner.scan('.')
        new_token(TokenType::DOT)
      elsif scanner.scan(';')
        new_token(TokenType::SEMICOLON)
      elsif scanner.scan('=')
        new_token(TokenType::EQ)
      elsif scanner.scan('!')
        new_token(TokenType::BANG)
      elsif scanner.scan('(')
        new_token(TokenType::LPAREN)
      elsif scanner.scan(')')
        new_token(TokenType::RPAREN)
      elsif scanner.scan('{')
        new_token(TokenType::LBRACE)
      elsif scanner.scan('}')
        new_token(TokenType::RBRACE)
      elsif scanner.scan('[')
        new_token(TokenType::LBRACKET)
      elsif scanner.scan(']')
        new_token(TokenType::RBRACKET)

      # String
      elsif @scanner.scan('"')
        mode = StringLexerMode.new(source_code, scanner)
        mode_stack.push(mode)
        new_token(TokenType::DQUO)

      # Values
      elsif scanner.scan(/\d+/)
        new_token(TokenType::NUMBER, scanner.matched)
      elsif scanner.scan(/\w+/)
        case scanner.matched

        # Keywords
        when 'else'
          new_token(TokenType::KW_ELSE)
        when 'false'
          new_token(TokenType::KW_FALSE)
        when 'for'
          new_token(TokenType::KW_FOR)
        when 'fun'
          new_token(TokenType::KW_FUN)
        when 'if'
          new_token(TokenType::KW_IF)
        when 'import'
          new_token(TokenType::KW_IMPORT)
        when 'new'
          new_token(TokenType::KW_NEW)
        when 'null'
          new_token(TokenType::KW_NULL)
        when 'print'
          new_token(TokenType::KW_PRINT)
        when 'return'
          new_token(TokenType::KW_RETURN)
        when 'struct'
          new_token(TokenType::KW_STRUCT)
        when 'true'
          new_token(TokenType::KW_TRUE)
        when 'var'
          new_token(TokenType::KW_VAR)
        when 'while'
          new_token(TokenType::KW_WHILE)

        # Identifier
        else
          new_token(TokenType::IDENT, scanner.matched)
        end
      else
        char = scanner.getch
        raise Deli::LocatableError.new(
          "Unknown character: #{char}",
          span,
        )
      end
    end
  end

  class StringLexerMode < AbstractLexerMode
    def lex_token(mode_stack)
      if @scanner.eos?
        nil
      elsif @scanner.scan('"')
        mode_stack.pop
        new_token(TokenType::DQUO)
      elsif @scanner.scan(/\\"/)
        new_token(TokenType::LIT, '"')
      elsif @scanner.scan('${')
        mode = InterpolationLexerMode.new(source_code, scanner)
        mode_stack.push(mode)
        new_token(TokenType::DOLLAR_LBRACE)
      elsif @scanner.scan('$')
        new_token(TokenType::LIT, '$')
      elsif @scanner.scan(/[^"\\$]+/)
        new_token(TokenType::LIT, scanner.matched)
      else
        char = scanner.getch
        raise Deli::LocatableError.new(
          "Unknown character: #{char}",
          span,
        )
      end
    end

    class InterpolationLexerMode < AbstractLexerMode
      def initialize(source_code, scanner)
        super

        @delegate = MainLexerMode.new(source_code, scanner)
      end

      def lex_token(mode_stack)
        if @scanner.scan('}')
          mode_stack.pop
          new_token(TokenType::RBRACE)
        else
          @delegate.lex_token(mode_stack)
        end
      end
    end
  end
end
