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

    module Precedence
      NONE = 0

      TERM   = 1
      FACTOR = 2
      UNARY  = 3
    end

    class ParseRule
      attr_reader :precedence
      attr_reader :prefix
      attr_reader :infix

      def initialize(precedence, prefix: nil, infix: nil)
        @precedence = precedence
        @prefix     = prefix
        @infix      = infix
      end
    end

    PARSE_RULES = {
      IDENTIFIER: ParseRule.new(Precedence::NONE, prefix: :parse_variable),
      NUMBER:     ParseRule.new(Precedence::NONE, prefix: :parse_number),

      PLUS:       ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),
      MINUS:      ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),
      ASTERISK:   ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),
      SLASH:      ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),

      SEMICOLON:  ParseRule.new(Precedence::NONE),
    }.freeze

    def parse_expr
      parse_precedence(Precedence::TERM)
    end

    def parse_precedence(precedence)
      token = @tokens.shift
      rule = PARSE_RULES.fetch(token.type) # TODO: handle errors
      expr = send(rule.prefix, token)

      while PARSE_RULES.fetch(@tokens.first.type).precedence >= precedence
        token = @tokens.shift
        rule = PARSE_RULES.fetch(token.type) # TODO: handle errors
        expr = send(rule.infix, token, expr)
      end

      expr
    end

    def parse_number(token)
      Deli::AST::IntegerExpr.new(Integer(token.value))
    end

    def parse_unary(token)
      expr = parse_precedence(Precedence::UNARY)
      Deli::AST::UnaryExpr.new(token, expr)
    end

    def parse_binary(token, left_expr)
      rule = PARSE_RULES.fetch(token.type)
      right_expr = parse_precedence(rule.precedence + 1)
      Deli::AST::BinaryExpr.new(token, left_expr, right_expr)
    end

    def parse_variable(token)
      Deli::AST::IdentifierExpr.new(token)
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
