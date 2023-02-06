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

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr
        expr.value
      when AST::IdentifierExpr
        @env[expr.identifier]
      else
        raise Deli::InternalInconsistencyError, "Unexpected expr class: #{stmt.class}"
      end
    end
  end
end
