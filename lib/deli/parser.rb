# frozen_string_literal: true

module Deli
  class Parser
    def initialize(source_code, tokens)
      @source_code = source_code
      @tokens = tokens.dup
    end

    def call
      stmts = []
      until peek.type.symbol == :EOF
        stmts << parse_stmt
      end
      stmts
    end

    private

    def parse_stmt
      token = advance
      case token.type.symbol
      when :KW_VAR
        parse_var_stmt
      when :KW_PRINT
        parse_print_stmt
      when :KW_IF
        parse_if_stmt
      when :KW_WHILE
        parse_while_stmt
      when :KW_FUN
        parse_fun_stmt
      when :KW_RETURN
        parse_return_stmt
      when :IDENT
        parse_partial_ident_stmt(token)
      else
        raise Deli::LocatableError.new(
          @source_code,
          token.span,
          "parse error: unexpected #{token.type}",
        )
      end
    end

    def parse_var_stmt
      # NOTE: :KW_VAR already consumed

      ident_token = consume(TokenTypes::IDENT)
      consume(TokenTypes::EQ)
      value_expr = parse_expr
      consume(TokenTypes::SEMICOLON)

      Deli::AST::VarStmt.new(ident_token, value_expr)
    end

    def parse_print_stmt
      # NOTE: :KW_PRINT already consumed

      expr = parse_expr
      consume(TokenTypes::SEMICOLON)

      Deli::AST::PrintStmt.new(expr)
    end

    def parse_if_stmt
      # NOTE: :KW_IF already consumed

      condition_expr = parse_expr
      consume(TokenTypes::LBRACE)

      true_stmt = parse_group_stmt

      false_stmt = nil
      if peek.type.symbol == :KW_ELSE
        advance # consume :ELSE
        consume(TokenTypes::LBRACE)
        false_stmt = parse_group_stmt
      end

      Deli::AST::IfStmt.new(
        condition_expr, true_stmt, false_stmt,
      )
    end

    def parse_while_stmt
      # NOTE: :KW_WHILE already consumed

      condition_expr = parse_expr
      consume(TokenTypes::LBRACE)

      body_stmt = parse_group_stmt

      Deli::AST::WhileStmt.new(condition_expr, body_stmt)
    end

    # FIXME: is this really a statement?
    def parse_fun_stmt
      # NOTE: :KW_FUN already consumed

      ident = consume(TokenTypes::IDENT)

      # Parameter list
      consume(TokenTypes::LPAREN)
      # TODO: parameters
      consume(TokenTypes::RPAREN)

      # Body
      consume(TokenTypes::LBRACE)
      body_stmt = parse_group_stmt

      Deli::AST::FunStmt.new(ident, body_stmt)
    end

    def parse_return_stmt
      # NOTE: :KW_RETURN already consumed

      if peek.type.symbol == :SEMICOLON
        advance
        Deli::AST::ReturnStmt.new(nil)
      else
        expr = parse_expr
        consume(TokenTypes::SEMICOLON)
        Deli::AST::ReturnStmt.new(expr)
      end
    end

    def parse_group_stmt
      # NOTE: :LBRACE already consumed

      stmts = []
      until peek.type.symbol == :RBRACE
        stmts << parse_stmt
      end

      consume(TokenTypes::RBRACE)

      Deli::AST::GroupStmt.new(stmts)
    end

    def parse_partial_ident_stmt(ident_token)
      # NOTE: :IDENT already consumed

      token = advance
      case token.type.symbol
      when :EQ
        parse_assign_stmt(ident_token, token)
      when :LPAREN
        parse_call_stmt(ident_token, token)
      else
        raise Deli::LocatableError.new(
          @source_code,
          token.span,
          "parse error: unexpected #{token.type}",
        )
      end
    end

    def parse_assign_stmt(ident_token, _eq_token)
      # NOTE: :IDENT already consumed
      # NOTE: :EQ already consumed

      expr = parse_expr
      consume(TokenTypes::SEMICOLON)

      Deli::AST::AssignStmt.new(ident_token, expr)
    end

    def parse_call_stmt(ident_token, lparen_token)
      # NOTE: :IDENT already consumed
      # NOTE: :LPAREN already consumed

      fun_expr = Deli::AST::IdentifierExpr.new(ident_token)
      expr = parse_call_expr(fun_expr, lparen_token)
      consume(TokenTypes::SEMICOLON)
      Deli::AST::ExprStmt.new(expr)
    end

    module Precedence
      NONE   = 0
      LOWEST = 1

      EQUALITY   = 1 # == !=
      COMPARISON = 2 # > >= < <=
      TERM       = 3 # + -
      FACTOR     = 4 # * /
      UNARY      = 5 # - !
      CALL       = 6 # ( .
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

    class ParseRules
      def initialize
        @rules = {}

        @default_rule = ParseRule.new(Precedence::NONE)
      end

      def register(
        token_type, precedence, prefix: nil, infix: nil
      )
        rule = ParseRule.new(
          precedence,
          prefix: prefix,
          infix: infix,
        )

        @rules[token_type] = rule
      end

      def [](token_type)
        @rules.fetch(token_type, @default_rule)
      end
    end

    PARSE_RULES = ParseRules.new

    PARSE_RULES.register(
      :IDENT,
      Precedence::NONE,
      prefix: :parse_variable,
    )

    PARSE_RULES.register(
      :NUMBER,
      Precedence::NONE,
      prefix: :parse_number,
    )

    PARSE_RULES.register(
      :KW_TRUE,
      Precedence::NONE,
      prefix: :parse_true,
    )

    PARSE_RULES.register(
      :KW_FALSE,
      Precedence::NONE,
      prefix: :parse_false,
    )

    PARSE_RULES.register(
      :KW_NULL,
      Precedence::NONE,
      prefix: :parse_null,
    )

    PARSE_RULES.register(
      :EQ_EQ,
      Precedence::EQUALITY,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :BANG_EQ,
      Precedence::EQUALITY,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :LT,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :LTE,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :GT,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :GTE,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :PLUS,
      Precedence::TERM,
      prefix: :parse_unary,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :MINUS,
      Precedence::TERM,
      prefix: :parse_unary,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :ASTERISK,
      Precedence::FACTOR,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :SLASH,
      Precedence::FACTOR,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      :BANG,
      Precedence::UNARY,
      prefix: :parse_unary,
    )

    PARSE_RULES.register(
      :LPAREN,
      Precedence::CALL,
      infix: :parse_call_expr,
    )

    def parse_expr
      parse_precedence(Precedence::LOWEST)
    end

    # TODO: handle right associativity

    def parse_precedence(precedence)
      token = advance
      rule = PARSE_RULES[token.type.symbol]
      unless rule.prefix
        raise Deli::LocatableError.new(
          @source_code,
          token.span,
          "parse error: unexpected #{token.type}",
        )
      end

      expr = send(rule.prefix, token)

      while (rule = PARSE_RULES[peek.type.symbol]).precedence >= precedence
        token = advance
        unless rule.infix
          raise Deli::LocatableError.new(
            @source_code,
            token.span,
            "parse error: #{token.type} cannot be used as an infix operator",
          )
        end

        expr = send(rule.infix, expr, token)
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

    def parse_binary(left_expr, token)
      rule = PARSE_RULES[token.type.symbol]
      right_expr = parse_precedence(rule.precedence + 1)
      Deli::AST::BinaryExpr.new(token, left_expr, right_expr)
    end

    def parse_variable(token)
      Deli::AST::IdentifierExpr.new(token)
    end

    def parse_call_expr(left_expr, _lparen_token)
      # TODO: arguments
      consume(TokenTypes::RPAREN)

      Deli::AST::CallExpr.new(left_expr)
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
      if peek.type == type
        @tokens.shift
      else
        raise Deli::LocatableError.new(
          @source_code,
          peek.span,
          "parse error: expected #{type}, but got #{peek.type}",
        )
      end
    end

    def advance
      @tokens.shift
    end

    def peek
      @tokens.first
    end
  end
end
