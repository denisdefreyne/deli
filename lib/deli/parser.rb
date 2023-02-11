# frozen_string_literal: true

module Deli
  class Parser
    def initialize(tokens)
      @tokens = tokens.dup
    end

    def call
      stmts = []
      until peek.type == TokenType::EOF
        stmts << parse_stmt
      end
      stmts
    end

    private

    def parse_stmt
      case peek.type
      when TokenType::KW_VAR
        parse_var_stmt
      when TokenType::KW_PRINT
        parse_print_stmt
      when TokenType::KW_IF
        parse_if_stmt
      when TokenType::KW_WHILE
        parse_while_stmt
      when TokenType::KW_FUN
        parse_fun_stmt
      when TokenType::KW_STRUCT
        parse_struct_stmt
      when TokenType::KW_RETURN
        parse_return_stmt
      else
        parse_expr_stmt
      end
    end

    def parse_var_stmt
      advance # `var` token
      ident_token = consume(TokenType::IDENT)
      consume(TokenType::EQ)
      expr = parse_expr
      consume(TokenType::SEMICOLON)

      Deli::AST::VarStmt.new(ident_token, expr)
    end

    def parse_print_stmt
      advance # `print` token
      expr = parse_expr
      consume(TokenType::SEMICOLON)

      Deli::AST::PrintStmt.new(expr)
    end

    def parse_if_stmt
      advance # `if` token
      condition_expr = parse_expr

      true_stmt = parse_group_stmt

      false_stmt = nil
      if peek.type == TokenType::KW_ELSE
        advance # consume :ELSE
        false_stmt = parse_group_stmt
      end

      Deli::AST::IfStmt.new(
        condition_expr, true_stmt, false_stmt,
      )
    end

    def parse_while_stmt
      advance # `while` token
      condition_expr = parse_expr
      body_stmt = parse_group_stmt

      Deli::AST::WhileStmt.new(condition_expr, body_stmt)
    end

    # FIXME: is this really a statement?
    def parse_fun_stmt
      advance # `fun` tokena

      ident = consume(TokenType::IDENT)

      # Parameter list
      consume(TokenType::LPAREN)
      params = []
      if peek.type != TokenType::RPAREN
        param_token = consume(TokenType::IDENT)
        params << AST::Param.new(param_token)

        while peek.type == TokenType::COMMA
          advance # comma

          # Handle trailing comma
          if peek.type == TokenType::RPAREN
            break
          end

          param_token = consume(TokenType::IDENT)
          params << AST::Param.new(param_token)
        end
      end
      consume(TokenType::RPAREN)

      # Body
      body_stmt = parse_group_stmt

      Deli::AST::FunStmt.new(ident, params, body_stmt)
    end

    def parse_struct_stmt
      advance # `struct` token

      ident = consume(TokenType::IDENT)
      consume(TokenType::LBRACE)
      props = []
      if peek.type != TokenType::RBRACE
        prop_token = consume(TokenType::IDENT)
        props << AST::Prop.new(prop_token)

        while peek.type == TokenType::COMMA
          advance # comma

          # Handle trailing comma
          if peek.type == TokenType::RBRACE
            break
          end

          prop_token = consume(TokenType::IDENT)
          props << AST::Prop.new(prop_token)
        end
      end
      consume(TokenType::RBRACE)

      Deli::AST::StructStmt.new(ident, props)
    end

    def parse_return_stmt
      advance # `return` token

      if peek.type == TokenType::SEMICOLON
        advance
        Deli::AST::ReturnStmt.new(nil)
      else
        expr = parse_expr
        consume(TokenType::SEMICOLON)
        Deli::AST::ReturnStmt.new(expr)
      end
    end

    def parse_group_stmt
      advance # `{` token

      stmts = []
      until peek.type == TokenType::RBRACE
        stmts << parse_stmt
      end

      consume(TokenType::RBRACE)

      Deli::AST::GroupStmt.new(stmts)
    end

    def parse_expr_stmt
      expr = parse_expr
      consume(TokenType::SEMICOLON)

      Deli::AST::ExprStmt.new(expr)
    end

    def parse_call_stmt(ident_token, lparen_token)
      fun_expr = Deli::AST::IdentifierExpr.new(ident_token)
      expr = parse_call_expr(fun_expr, lparen_token)
      consume(TokenType::SEMICOLON)
      Deli::AST::ExprStmt.new(expr)
    end

    module Precedence
      NONE   = 0
      LOWEST = 1

      ASSIGN     = 1 # =
      EQUALITY   = 2 # == !=
      COMPARISON = 3 # > >= < <=
      TERM       = 4 # + -
      FACTOR     = 5 # * /
      UNARY      = 6 # - !
      CALL       = 7 # ( .
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
      TokenType::IDENT,
      Precedence::NONE,
      prefix: :parse_variable,
    )

    PARSE_RULES.register(
      TokenType::NUMBER,
      Precedence::NONE,
      prefix: :parse_number,
    )

    PARSE_RULES.register(
      TokenType::DQUO,
      Precedence::NONE,
      prefix: :parse_string,
    )

    PARSE_RULES.register(
      TokenType::KW_TRUE,
      Precedence::NONE,
      prefix: :parse_true,
    )

    PARSE_RULES.register(
      TokenType::KW_FALSE,
      Precedence::NONE,
      prefix: :parse_false,
    )

    PARSE_RULES.register(
      TokenType::KW_NULL,
      Precedence::NONE,
      prefix: :parse_null,
    )

    PARSE_RULES.register(
      TokenType::EQ,
      Precedence::ASSIGN,
      infix: :parse_assign,
    )

    PARSE_RULES.register(
      TokenType::EQ_EQ,
      Precedence::EQUALITY,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::BANG_EQ,
      Precedence::EQUALITY,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::LT,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::LTE,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::GT,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::GTE,
      Precedence::COMPARISON,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::PLUS,
      Precedence::TERM,
      prefix: :parse_unary,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::MINUS,
      Precedence::TERM,
      prefix: :parse_unary,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::ASTERISK,
      Precedence::FACTOR,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::SLASH,
      Precedence::FACTOR,
      infix: :parse_binary,
    )

    PARSE_RULES.register(
      TokenType::BANG,
      Precedence::UNARY,
      prefix: :parse_unary,
    )

    PARSE_RULES.register(
      TokenType::LPAREN,
      Precedence::CALL,
      infix: :parse_call_expr,
    )

    def parse_expr
      parse_precedence(Precedence::LOWEST)
    end

    def parse_precedence(precedence)
      token = advance
      rule = PARSE_RULES[token.type]
      unless rule.prefix
        raise Deli::LocatableError.new(
          "parse error: unexpected #{token.type}",
          token.span,
        )
      end

      expr = send(rule.prefix, token)

      while (rule = PARSE_RULES[peek.type]).precedence >= precedence
        token = advance
        unless rule.infix
          raise Deli::LocatableError.new(
            "parse error: #{token.type} cannot be used as an infix operator",
            token.span,
          )
        end

        expr = send(rule.infix, expr, token)
      end

      expr
    end

    def parse_string(_token)
      parts = []

      until peek.type == TokenType::DQUO
        case peek.type
        when TokenType::LIT
          parts << Deli::AST::StringPartLitExpr.new(advance.value)
        when TokenType::DOLLAR_LBRACE
          advance
          parts << Deli::AST::StringPartInterpExpr.new(parse_expr)
          consume(TokenType::RBRACE)
        else
          # TODO
          raise '???'
        end
      end

      consume(TokenType::DQUO)

      Deli::AST::StringExpr.new(parts)
    end

    def parse_number(token)
      Deli::AST::IntegerExpr.new(Integer(token.value))
    end

    def parse_unary(token)
      expr = parse_precedence(Precedence::UNARY)
      Deli::AST::UnaryExpr.new(token, expr)
    end

    def parse_assign(left_expr, token)
      right_expr = parse_precedence(Precedence::ASSIGN + 1)
      Deli::AST::AssignExpr.new(left_expr, token, right_expr)
    end

    def parse_binary(left_expr, token)
      rule = PARSE_RULES[token.type]
      right_expr = parse_precedence(rule.precedence + 1)
      Deli::AST::BinaryExpr.new(token, left_expr, right_expr)
    end

    def parse_variable(token)
      Deli::AST::IdentifierExpr.new(token)
    end

    def parse_call_expr(left_expr, _lparen_token)
      args = []
      if peek.type != TokenType::RPAREN
        args << parse_expr

        while peek.type == TokenType::COMMA
          advance # comma

          # Handle trailing comma
          if peek.type == TokenType::RPAREN
            break
          end

          args << parse_expr
        end
      end

      consume(TokenType::RPAREN)

      Deli::AST::CallExpr.new(left_expr, args)
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
          "parse error: expected #{type}, but got #{peek.type}",
          peek.span,
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
