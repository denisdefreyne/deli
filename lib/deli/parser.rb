# frozen_string_literal: true

module Deli
  class Parser
    def initialize(source_code, tokens)
      @source_code = source_code
      @tokens = tokens.dup
    end

    def call
      stmts = []
      while (s = parse_stmt)
        stmts << s
      end
      stmts
    end

    private

    def parse_stmt
      return nil if @tokens.empty?

      token = @tokens.shift
      case token.type
      when :KEYWORD_VAR
        parse_var_stmt
      when :KEYWORD_PRINT
        parse_print_stmt
      when :IDENTIFIER
        parse_partial_identifier(token)
      else
        raise Deli::LocatableError.new(
          @source_code, token.span, "parse error: expected `var` or `print`, but got #{token.type}"
        )
      end
    end

    def parse_var_stmt
      # NOTE: :KEYWORD_VAR already consumed

      identifier_token = consume(:IDENTIFIER)
      consume(:EQUAL)
      value_expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::VarStmt.new(identifier_token, value_expr)
    end

    def parse_print_stmt
      # NOTE: :KEYWORD_PRINT already consumed

      expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::PrintStmt.new(expr)
    end

    def parse_partial_identifier(identifier_token)
      # NOTE: :IDENTIFIER already consumed

      token = @tokens.shift
      case token.type
      when :EQUAL
        parse_assign(identifier_token)
      else
        raise Deli::LocatableError.new(
          @source_code, token.span, "parse error: expected `=`, but got #{token.type}"
        )
      end
    end

    def parse_assign(identifier_token)
      # NOTE: :IDENTIFIER already consumed
      # NOTE: :EQUAL already consumed

      expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::AssignStmt.new(identifier_token, expr)
    end

    def parse_expr
      token = @tokens.shift
      case token.type
      when :NUMBER
        Deli::AST::IntegerExpr.new(Integer(token.value))
      when :IDENTIFIER
        Deli::AST::IdentifierExpr.new(token)
      else
        raise Deli::LocatableError.new(
          @source_code, token.span, "parse error: expected NUMBER, but got #{token.type}"
        )
      end
    end

    def consume(type)
      if @tokens.first.type == type
        @tokens.shift
      else
        raise Deli::LocatableError.new(
          @source_code, @tokens.span.first, "parse error: expected #{type}, but got #{@tokens.first.type}"
        )
      end
    end
  end
end
