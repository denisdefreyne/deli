module Deli
  class Evaluator
    class Env
      def initialize(source_code)
        @source_code = source_code

        @values = {}
      end

      def [](token)
        @values.fetch(token.value) do
          raise Deli::TokenLocatableError.new(@source_code, token, "Unknown name: #{token.value}")
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
      when AST::VarStmt # Struct.new(:identifier, :value_expr)
        value = eval_expr(stmt.value_expr)
        @env[stmt.identifier] = value
      when AST::PrintStmt # Struct.new(:expr)
        value = eval_expr(stmt.expr)
        puts value
      end
    end

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr # Struct.new(:value)
        expr.value
      when AST::IdentifierExpr # Struct.new(:identifier)
        @env[expr.identifier]
      end
    end
  end
end
