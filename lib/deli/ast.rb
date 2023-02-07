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

    module SExp
      attr_accessor :scope

      def inspect
        StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
      end

      def inspect_multiline
        StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
      end
    end

    # Statements

    VarStmt = Struct.new(:ident, :expr) do
      include SExp

      def to_sexp
        [:var, ident.value, expr]
      end
    end

    ExprStmt = Struct.new(:expr) do
      include SExp

      def to_sexp
        [:expr, expr]
      end
    end

    PrintStmt = Struct.new(:expr) do
      include SExp

      def to_sexp
        [:print, expr]
      end
    end

    GroupStmt = Struct.new(:stmts) do
      include SExp

      def to_sexp
        [:group, *stmts]
      end
    end

    IfStmt = Struct.new(:cond_expr, :true_stmt, :false_stmt) do
      include SExp

      def to_sexp
        [:if, cond_expr, true_stmt, false_stmt]
      end
    end

    WhileStmt = Struct.new(:cond_expr, :body_stmt) do
      include SExp

      def to_sexp
        [:while, cond_expr, body_stmt]
      end
    end

    FunStmt = Struct.new(:ident, :params, :body_stmt) do
      include SExp

      def to_sexp
        [:fun, ident.value, *params.map(&:value), body_stmt]
      end
    end

    ReturnStmt = Struct.new(:expr) do
      include SExp

      def to_sexp
        [:return, expr]
      end
    end

    # Expressions

    IntegerExpr = Struct.new(:value) do
      include SExp

      def to_sexp
        [:integer, value]
      end
    end

    IdentifierExpr = Struct.new(:ident) do
      include SExp

      attr_accessor :symbol

      def to_sexp
        [:ident, ident.value]
      end
    end

    TrueExpr = Class.new do
      include SExp

      def to_sexp
        [:true] # rubocop:disable Lint/BooleanSymbol
      end
    end

    FalseExpr = Class.new do
      include SExp

      def to_sexp
        [:false] # rubocop:disable Lint/BooleanSymbol
      end
    end

    NullExpr = Class.new do
      include SExp

      def to_sexp
        [:null]
      end
    end

    AssignExpr = Struct.new(:left_expr, :token, :right_expr) do
      include SExp

      def to_sexp
        [:assign, left_expr, right_expr]
      end
    end

    CallExpr = Struct.new(:callee, :arg_exprs) do
      include SExp

      def to_sexp
        [:call, callee, *arg_exprs]
      end
    end

    UnaryExpr = Struct.new(:op, :expr) do
      include SExp

      def to_sexp
        [:unary, op.lexeme, expr]
      end
    end

    BinaryExpr = Struct.new(:op, :left_expr, :right_expr) do
      include SExp

      def to_sexp
        [:binary, op.lexeme, left_expr, right_expr]
      end
    end
  end
end
