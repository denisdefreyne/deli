# frozen_string_literal: true

module Deli
  class Evaluator
    class Env
      def initialize(source_code)
        @source_code = source_code

        @values = {}
      end

      def [](token)
        @values.fetch(token.value) do
          raise Deli::LocatableError.new(@source_code, token.span, "Unknown name: #{token.value}")
        end
      end

      def []=(token, value)
        @values[token.value] = value
      end
    end

    def initialize(source, stmts)
      @stmts = stmts

      @env = Env.new(source)
    end

    def call
      @stmts.each { eval_stmt(_1) }
    end

    private

    def eval_stmt(stmt)
      case stmt
      when AST::VarStmt, AST::AssignStmt
        # TODO: split var from assign
        value = eval_expr(stmt.value_expr)
        @env[stmt.identifier] = value
      when AST::PrintStmt
        value = eval_expr(stmt.expr)
        puts value
      else
        raise Deli::InternalInconsistencyError, "Unexpected stmt class: #{stmt.class}"
      end
    end

    class True
      include Singleton

      def to_s
        'true'
      end

      def !@
        False.instance
      end
    end

    class False
      include Singleton

      def to_s
        'false'
      end

      def !@
        True.instance
      end
    end

    class Null
      include Singleton

      def to_s
        'null'
      end

      def !@
        True.instance
      end
    end

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr
        expr.value
      when AST::IdentifierExpr
        @env[expr.identifier]
      when AST::TrueExpr
        True.instance
      when AST::FalseExpr
        False.instance
      when AST::NullExpr
        Null.instance
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
          raise Deli::InternalInconsistencyError, "Unexpected unary operator: #{expr.op}"
        end
      when AST::BinaryExpr
        left_val = eval_expr(expr.left)
        right_val = eval_expr(expr.right)

        case expr.op.type
        when :PLUS
          left_val + right_val
        when :MINUS
          left_val - right_val
        else
          raise Deli::InternalInconsistencyError, "Unexpected unary operator: #{expr.op}"
        end
      else
        raise Deli::InternalInconsistencyError, "Unexpected expr class: #{expr.class}"
      end
    end
  end
end
