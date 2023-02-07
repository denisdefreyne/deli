# frozen_string_literal: true

module Deli
  class Evaluator
    class Env
      attr_reader :parent

      def initialize(source_code, parent: nil)
        @source_code = source_code
        @parent = parent

        @values = {}
      end

      def lookup(symbol, token)
        # TODO: use symbol
        # TODO: maybe pass only token, not symbol

        @values.fetch(token.value) do
          if @parent
            @parent.lookup(symbol, token)
          else
            raise Deli::LocatableError.new(
              @source_code,
              token.span,
              "Unknown name: #{token.value}",
            )
          end
        end
      end

      def assign_new(token, _symbol, value)
        # TODO: use symbol
        @values[token.value] = value
      end

      def assign_existing(token, symbol, value)
        # TODO: use symbol
        if @values.key?(token.value)
          @values[token.value] = value
        elsif @parent
          @parent.assign_existing(token, symbol, value)
        else
          raise Deli::LocatableError.new(
            @source_code,
            token.span,
            "Unknown name: #{token.value}",
          )
        end
      end
    end

    class Fun
      attr_reader :params
      attr_reader :body_stmt

      def initialize(params, body_stmt)
        @params = params
        @body_stmt = body_stmt
      end
    end

    def initialize(source_code, stmts)
      @source_code = source_code
      @stmts = stmts

      @env = Env.new(source_code)
    end

    def call
      @stmts.each { eval_stmt(_1) }
    end

    private

    def eval_stmt(stmt)
      case stmt
      when AST::VarStmt
        value = eval_expr(stmt.expr)
        # TODO: use symbol
        @env.assign_new(stmt.ident, nil, value)
      when AST::PrintStmt
        value = eval_expr(stmt.expr)
        puts(stringify(value))
      when AST::IfStmt
        value = eval_expr(stmt.cond_expr)
        if value
          eval_stmt(stmt.true_stmt)
        elsif stmt.false_stmt
          eval_stmt(stmt.false_stmt)
        end
      when AST::WhileStmt
        while eval_expr(stmt.cond_expr)
          eval_stmt(stmt.body_stmt)
        end
      when AST::GroupStmt
        push_env do
          stmt.stmts.each { eval_stmt(_1) }
        end
      when AST::FunStmt
        fn = Fun.new(stmt.params, stmt.body_stmt)
        # TODO: use symbol
        @env.assign_new(stmt.ident, nil, fn)
      when AST::ExprStmt
        eval_expr(stmt.expr)
      when AST::ReturnStmt
        if stmt.expr
          throw :return, eval_expr(stmt.expr)
        else
          throw :return
        end
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected stmt class: #{stmt.class}"
      end
    end

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr
        expr.value
      when AST::IdentifierExpr
        @env.lookup(expr.symbol, expr.ident)
      when AST::CallExpr
        callee = eval_expr(expr.callee)

        unless callee.is_a?(Fun)
          # TODO: raise locatable error
          raise 'nope'
        end

        unless callee.params.size == expr.arg_exprs.size
          raise 'args count mismatch'
        end

        push_env do
          callee.params.zip(expr.arg_exprs) do |param, arg_expr|
            # TODO: use symbol
            @env.assign_new(param, nil, eval_expr(arg_expr))
          end

          catch :return do
            eval_stmt(callee.body_stmt)
          end
        end
      when AST::TrueExpr
        true
      when AST::FalseExpr
        false
      when AST::NullExpr
        nil
      when AST::AssignExpr
        unless expr.left_expr.is_a?(AST::IdentifierExpr)
          raise Deli::LocatableError.new(
            @source_code,
            expr.token.span,
            'Left-hand side cannot be assigned to',
          )
        end

        right_value = eval_expr(expr.right_expr)
        # TODO: use symbol
        @env.assign_existing(expr.left_expr.ident, nil, right_value)
      when AST::UnaryExpr
        val = eval_expr(expr.expr)

        case expr.op.type
        when TokenType::PLUS
          val
        when TokenType::MINUS
          -val
        when TokenType::BANG
          !val
        else
          raise Deli::InternalInconsistencyError,
            "Unexpected unary operator: #{expr.op}"
        end
      when AST::BinaryExpr
        left_val = eval_expr(expr.left_expr)
        right_val = eval_expr(expr.right_expr)

        case expr.op.type
        when TokenType::PLUS
          left_val + right_val
        when TokenType::MINUS
          left_val - right_val
        when TokenType::ASTERISK
          left_val * right_val
        when TokenType::SLASH
          left_val / right_val
        when TokenType::LT
          left_val < right_val
        when TokenType::LTE
          left_val <= right_val
        when TokenType::GT
          left_val > right_val
        when TokenType::GTE
          left_val >= right_val
        else
          raise Deli::InternalInconsistencyError,
            "Unexpected unary operator: #{expr.op}"
        end
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected expr class: #{expr.class}"
      end
    end

    def push_env
      @env = Env.new(@source_code, parent: @env)
      yield
    ensure
      @env = @env.parent
    end

    def stringify(obj)
      case obj
      when nil
        'null'
      else
        obj.to_s
      end
    end
  end
end
