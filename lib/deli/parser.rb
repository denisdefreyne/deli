# frozen_string_literal: true

module Deli
  class Parser
    def initialize(source_code, tokens)
      @source_code = source_code
      @tokens = tokens.dup

      @last_token = @tokens.last
    end

    def call
      stmts = []
      until @tokens.empty?
        stmts << parse_stmt
      end
      stmts
    end

    private

    def parse_stmt
      return nil if @tokens.empty?

      token = advance
      case token.type
      when :KW_VAR
        parse_var_stmt
      when :KW_PRINT
        parse_print_stmt
      when :KW_IF
        parse_if_stmt
      when :KW_WHILE
        parse_while_stmt
      when :IDENTIFIER
        parse_partial_identifier_stmt(token)
      else
        raise Deli::LocatableError.new(
          @source_code, token.span, "parse error: expected `var` or `print`, but got #{token.type}",
        )
      end
    end

    def parse_var_stmt
      # NOTE: :KW_VAR already consumed

      identifier_token = consume(:IDENTIFIER)
      consume(:EQ)
      value_expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::VarStmt.new(identifier_token, value_expr)
    end

    def parse_print_stmt
      # NOTE: :KW_PRINT already consumed

      expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::PrintStmt.new(expr)
    end

    def parse_if_stmt
      # NOTE: :KW_IF already consumed

      condition_expr = parse_expr
      consume(:LBRACE)

      true_stmt = parse_group_stmt

      false_stmt = nil
      if peek&.type == :KW_ELSE
        advance # consume :ELSE
        consume(:LBRACE)
        false_stmt = parse_group_stmt
      end

      Deli::AST::IfStmt.new(condition_expr, true_stmt, false_stmt)
    end

    def parse_while_stmt
      # NOTE: :KW_WHILE already consumed

      condition_expr = parse_expr
      consume(:LBRACE)

      body_stmt = parse_group_stmt

      Deli::AST::WhileStmt.new(condition_expr, body_stmt)
    end

    def parse_group_stmt
      # NOTE: :LBRACE already consumed

      stmts = []
      until peek.type == :RBRACE
        stmts << parse_stmt
      end

      consume(:RBRACE)

      Deli::AST::GroupStmt.new(stmts)
    end

    def parse_partial_identifier_stmt(identifier_token)
      # NOTE: :IDENTIFIER already consumed

      token = advance
      case token.type
      when :EQ
        parse_assign(identifier_token)
      else
        raise Deli::LocatableError.new(
          @source_code, token.span, "parse error: expected `=`, but got #{token.type}",
        )
      end
    end

    def parse_assign(identifier_token)
      # NOTE: :IDENTIFIER already consumed
      # NOTE: :EQ already consumed

      expr = parse_expr
      consume(:SEMICOLON)

      Deli::AST::AssignStmt.new(identifier_token, expr)
    end

    module Precedence
      NONE   = 0
      LOWEST = 1

      EQUALITY   = 1
      COMPARISON = 2
      TERM       = 3
      FACTOR     = 4
      UNARY      = 5
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
      KW_TRUE:    ParseRule.new(Precedence::NONE, prefix: :parse_true),
      KW_FALSE:   ParseRule.new(Precedence::NONE, prefix: :parse_false),
      KW_NULL:    ParseRule.new(Precedence::NONE, prefix: :parse_null),

      EQ_EQ:      ParseRule.new(Precedence::EQUALITY, infix: :parse_binary),
      BANG_EQ:    ParseRule.new(Precedence::EQUALITY, infix: :parse_binary),

      LT:         ParseRule.new(Precedence::COMPARISON, infix: :parse_binary),
      LTE:        ParseRule.new(Precedence::COMPARISON, infix: :parse_binary),
      GT:         ParseRule.new(Precedence::COMPARISON, infix: :parse_binary),
      GTE:        ParseRule.new(Precedence::COMPARISON, infix: :parse_binary),

      PLUS:       ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),
      MINUS:      ParseRule.new(Precedence::TERM, prefix: :parse_unary, infix: :parse_binary),

      ASTERISK:   ParseRule.new(Precedence::FACTOR, infix: :parse_binary),
      SLASH:      ParseRule.new(Precedence::FACTOR, infix: :parse_binary),

      BANG:       ParseRule.new(Precedence::UNARY, prefix: :parse_unary),

      SEMICOLON:  ParseRule.new(Precedence::NONE),
      LBRACE:     ParseRule.new(Precedence::NONE),
    }.freeze

    def parse_expr
      parse_precedence(Precedence::LOWEST)
    end

    # TODO: handle right associativity

    def parse_precedence(precedence)
      token = advance
      rule = PARSE_RULES.fetch(token.type) # TODO: handle errors
      expr = send(rule.prefix, token)

      while peek && PARSE_RULES.fetch(peek.type).precedence >= precedence
        token = advance
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

    def parse_true(_token)
      Deli::AST::TrueExpr.new
    end

    def parse_false(_token)
      Deli::AST::FalseExpr.new
    end

    def parse_null(_token)
      Deli::AST::NullExpr.new
    end

    def consume(type)
      if peek
        if peek.type == type
          @tokens.shift
        else
          raise Deli::LocatableError.new(
            @source_code, @tokens.span.first, "parse error: expected #{type}, but got #{peek.type}",
          )
        end
      else
        raise Deli::LocatableError.new(
          @source_code, @last_token.span, "parse error: expected #{type}, but got end of input",
        )
      end
    end

    def advance
      must_peek
      @tokens.shift
    end

    def peek
      @tokens.first
    end

    def must_peek
      peek or unexpected_end_of_input
    end

    def unexpected_end_of_input
      raise Deli::LocatableError.new(
        @source_code, @last_token.span, 'parse error: unexpected end of input',
      )
    end
  end
end
