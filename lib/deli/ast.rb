# frozen_string_literal: true

module Deli
  module AST
    # Statements

    VarStmt = Struct.new(:identifier, :value_expr) do
      def inspect
        "(var #{identifier.value.inspect} #{value_expr.inspect})"
      end
    end

    AssignStmt = Struct.new(:identifier, :value_expr) do
      def inspect
        "(assign #{identifier.value.inspect} #{value_expr.inspect})"
      end
    end

    PrintStmt = Struct.new(:expr) do
      def inspect
        "(print #{expr.inspect})"
      end
    end

    GroupStmt = Struct.new(:stmts) do
      def inspect
        "(group #{stmts.map(&:inspect).join(' ')})"
      end
    end

    IfStmt = Struct.new(:cond_expr, :true_stmt, :false_stmt) do
      def inspect
        "(if #{cond_expr.inspect} #{true_stmt.inspect} #{false_stmt.inspect})"
      end
    end

    # Expressions

    IntegerExpr = Struct.new(:value) do
      def inspect
        "(integer #{value.inspect})"
      end
    end

    IdentifierExpr = Struct.new(:identifier) do
      def inspect
        "(identifier #{identifier.value.inspect})"
      end
    end

    TrueExpr = Class.new do
      def inspect
        '(true)'
      end
    end

    FalseExpr = Class.new do
      def inspect
        '(false)'
      end
    end

    NullExpr = Class.new do
      def inspect
        '(null)'
      end
    end

    UnaryExpr = Struct.new(:op, :expr) do
      def inspect
        "(unary #{op.lexeme} #{expr.inspect})"
      end
    end

    BinaryExpr = Struct.new(:op, :left, :right) do
      def inspect
        "(binary #{op.lexeme} #{left.inspect} #{right.inspect})"
      end
    end
  end
end
