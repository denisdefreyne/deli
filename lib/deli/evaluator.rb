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

      def [](token)
        @values.fetch(token.value) do
          if @parent
            @parent[token]
          else
            raise Deli::LocatableError.new(
              @source_code,
              token.span,
              "Unknown name: #{token.value}",
            )
          end
        end
      end

      def assign_new(token, value)
        @values[token.value] = value
      end

      def assign_existing(token, value)
        if @values.key?(token.value)
          @values[token.value] = value
        elsif @parent
          @parent.assign_existing(token, value)
        else
          raise Deli::LocatableError.new(
            @source_code,
            token.span,
            "Unknown name: #{token.value}",
          )
        end
      end

      def []=(token, value)
        @values[token.value] = value
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
        value = eval_expr(stmt.value_expr)
        @env.assign_new(stmt.identifier, value)
      when AST::AssignStmt
        value = eval_expr(stmt.value_expr)
        @env.assign_existing(stmt.identifier, value)
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
        @env[expr.identifier]
      when AST::TrueExpr
        true
      when AST::FalseExpr
        false
      when AST::NullExpr
        nil
      when AST::UnaryExpr
        val = eval_expr(expr.expr)

        case expr.op.type
        when :PLUS
          val
        when :MINUS
          -val
        when :BANG
          !val
        else
          raise Deli::InternalInconsistencyError,
            "Unexpected unary operator: #{expr.op}"
        end
      when AST::BinaryExpr
        left_val = eval_expr(expr.left)
        right_val = eval_expr(expr.right)

        case expr.op.type
        when :PLUS
          left_val + right_val
        when :MINUS
          left_val - right_val
        when :ASTERISK
          left_val * right_val
        when :SLASH
          left_val / right_val
        when :LT
          left_val < right_val
        when :LTE
          left_val <= right_val
        when :GT
          left_val > right_val
        when :GTE
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
