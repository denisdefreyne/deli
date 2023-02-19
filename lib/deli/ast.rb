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
          dump_sexp_oneline(child.to_sexp, out, indent + 1)
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

    class Node
      def self.define(name, attr_names, &)
        Class.new(self) do
          attr_names.each do |attr_name|
            attr_reader(attr_name)
          end

          attr_accessor :scope

          if block_given?
            instance_eval(&)
          end

          define_method :initialize do |*attrs|
            if attr_names.size != attrs.size
              raise ArgumentError, 'Not enough args'
            end

            attr_names.zip(attrs).each do |attr_name, attr|
              instance_variable_set("@#{attr_name}", attr)
            end
          end

          define_method :to_sexp do
            [
              name.to_sym,
              *attr_names.flat_map do |attr_name|
                value = instance_variable_get("@#{attr_name}")
                value = value.value if value.is_a?(Deli::Token)
                [value].flatten
              end,
            ]
          end

          def inspect
            StringIO.new.tap { AST.dump_sexp_oneline(to_sexp, _1, 0) }.string
          end

          def inspect_multiline
            StringIO.new.tap { AST.dump_sexp_multiline(to_sexp, _1, 0) }.string
          end
        end
      end
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

    VarStmt = Node.define(:var, [:ident, :expr]) do
      attr_accessor :symbol
    end

    ExprStmt = Node.define(:expr, [:expr])

    PrintStmt = Node.define(:print, [:expr])

    GroupStmt = Node.define(:group, [:stmts])

    IfStmt = Node.define(:if, [:cond_expr, :true_stmt, :false_stmt])

    WhileStmt = Node.define(:while, [:cond_expr, :body_stmt])

    StructStmt = Node.define(:struct, [:ident, :props, :methods]) do
      attr_accessor :symbol
    end

    FunStmt = Node.define(:fun, [:ident, :params, :body_stmt]) do
      attr_accessor :symbol
    end

    ReturnStmt = Node.define(:return, [:expr])

    Param = Node.define(:param, [:name]) do
      attr_accessor :symbol
    end

    Prop = Node.define(:prop, [:name]) do
      attr_accessor :symbol
    end

    # Expressions

    IntegerExpr = Struct.new(:value) do
      include SExp

      def to_sexp
        [:integer, value]
      end
    end

    StringPartLitExpr = Struct.new(:value) do
      include SExp

      def to_sexp
        [:string_part_lit, value]
      end
    end

    StringPartInterpExpr = Struct.new(:expr) do
      include SExp

      def to_sexp
        [:string_part_interp, expr]
      end
    end

    StringExpr = Struct.new(:parts) do
      include SExp

      def to_sexp
        [:string, *parts]
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

      attr_accessor :symbol

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

    DotExpr = Struct.new(:target, :ident) do
      include SExp

      def to_sexp
        [:dot, target, ident.value]
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

    Kwarg = Struct.new(:key, :value) do
      include SExp

      attr_accessor :symbol

      def to_sexp
        [:kwarg, key.lexeme, value]
      end
    end

    NewExpr = Struct.new(:ident, :kwargs) do
      include SExp

      attr_accessor :symbol

      def to_sexp
        [:new, ident.lexeme, *kwargs]
      end
    end
  end
end
