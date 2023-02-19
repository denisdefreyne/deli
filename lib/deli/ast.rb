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
                attr = instance_variable_get("@#{attr_name}")

                res =
                  if attr.is_a?(Deli::Token)
                    attr.value || attr.type
                  else
                    attr
                  end

                [res].flatten
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
      attr_accessor :this_symbol
    end

    ReturnStmt = Node.define(:return, [:expr])

    Param = Node.define(:param, [:name]) do
      attr_accessor :symbol
    end

    Prop = Node.define(:prop, [:name]) do
      attr_accessor :symbol
    end

    # Expressions

    IntegerExpr = Node.define(:integer, [:value])

    StringPartLitExpr = Node.define(:string_part_lit, [:value])

    StringPartInterpExpr = Node.define(:string_part_interp, [:expr])

    StringExpr = Node.define(:string, [:parts])

    IdentifierExpr = Node.define(:ident, [:ident]) do
      attr_accessor :symbol
    end

    TrueExpr = Node.define(:true, []) # rubocop:disable Lint/BooleanSymbol

    FalseExpr = Node.define(:false, []) # rubocop:disable Lint/BooleanSymbol

    NullExpr = Node.define(:null, [])

    AssignExpr = Node.define(:assign, [:left_expr, :right_expr]) do
      attr_accessor :token
      attr_accessor :symbol
    end

    CallExpr = Node.define(:call, [:callee, :arg_exprs])

    DotExpr = Node.define(:dot, [:target, :ident])

    UnaryExpr = Node.define(:unary, [:op, :expr])

    BinaryExpr = Node.define(:binary, [:op, :left_expr, :right_expr])

    Kwarg = Node.define(:kwarg, [:key, :value]) do
      attr_accessor :symbol
    end

    NewExpr = Node.define(:new, [:ident, :kwargs]) do
      attr_accessor :symbol
    end
  end
end
