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

    UnaryExpr = Struct.new(:op, :expr) do
      def inspect
        "(unary #{op.value.inspect} #{expr.inspect})"
      end
    end

    BinaryExpr = Struct.new(:op, :left, :right) do
      def inspect
        "(unary #{op.value.inspect} #{left.inspect} #{right.inspect})"
      end
    end
  end
end
