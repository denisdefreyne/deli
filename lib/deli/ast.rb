# frozen_string_literal: true

module Deli
  module AST
    def self.dump_sexp(sexp, out, indent)
      # Try one-line
      tmp_out = StringIO.new
      dump_sexp_oneline(sexp, tmp_out, indent)

      if tmp_out.string.size < 80
        out << tmp_out.string
      else
        dump_sexp_multiline(sexp, out, indent)
      end
    end

    def self.dump_sexp_oneline(sexp, out, indent)
      out << '('
      out << sexp.first

      sexp.drop(1).each do |child|
        out << ' '
        if child.respond_to?(:to_sexp)
          dump_sexp(child.to_sexp, out, indent + 1)
        else
          out << child.inspect
        end
      end

      out << ')'
    end

    def self.dump_sexp_multiline(sexp, out, indent)
      out << '('
      out << sexp.first

      sexp.drop(1).each do |child|
        out << "\n"
        out << ('  ' * (indent + 1))
        if child.respond_to?(:to_sexp)
          dump_sexp(child.to_sexp, out, indent + 1)
        else
          out << child.inspect
        end
      end

      out << ')'
    end

    # Statements

    VarStmt = Struct.new(:identifier, :value_expr) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:var, identifier.value, value_expr]
      end
    end

    AssignStmt = Struct.new(:identifier, :value_expr) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:assign, identifier.value, value_expr]
      end
    end

    PrintStmt = Struct.new(:expr) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:print, expr]
      end
    end

    GroupStmt = Struct.new(:stmts) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:group, *stmts]
      end
    end

    IfStmt = Struct.new(:cond_expr, :true_stmt, :false_stmt) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:if, cond_expr, true_stmt, false_stmt]
      end
    end

    WhileStmt = Struct.new(:cond_expr, :body_stmt) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:while, cond_expr, body_stmt]
      end
    end

    # Expressions

    IntegerExpr = Struct.new(:value) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:integer, value]
      end
    end

    IdentifierExpr = Struct.new(:identifier) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:identifier, identifier.value]
      end
    end

    TrueExpr = Class.new do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:true] # rubocop:disable Lint/BooleanSymbol
      end
    end

    FalseExpr = Class.new do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:false] # rubocop:disable Lint/BooleanSymbol
      end
    end

    NullExpr = Class.new do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:null]
      end
    end

    UnaryExpr = Struct.new(:op, :expr) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:unary, op.lexeme, expr]
      end
    end

    BinaryExpr = Struct.new(:op, :left, :right) do
      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end

      def to_sexp
        [:binary, op.lexeme, left, right]
      end
    end
  end
end
