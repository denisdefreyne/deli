# frozen_string_literal: true

module Deli
  class SymbolDefiner < AbstractWalker
    def initialize(source_code, stmts)
      super(stmts)

      @source_code = source_code

      @scope = Scope.new(source_code: @source_code)
    end

    private

    def handle(node)
      node.scope = @scope

      super
    end

    def handle_var_stmt(stmt)
      handle(stmt.expr)
      symbol = @scope.define(stmt.ident.value)
      stmt.symbol = symbol
    end

    def handle_print_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_if_stmt(stmt)
      handle(stmt.cond_expr)
      handle(stmt.true_stmt)
      if stmt.false_stmt
        handle(stmt.false_stmt)
      end
    end

    def handle_while_stmt(stmt)
      handle(stmt.cond_expr)
      handle(stmt.body_stmt)
    end

    def handle_group_stmt(stmt)
      push_scope do
        stmt.stmts.each { |s| handle(s) }
      end
    end

    def handle_fun_stmt(stmt)
      symbol = @scope.define(stmt.ident.value)
      stmt.symbol = symbol

      push_scope do
        stmt.params.each do |param|
          param.symbol = @scope.define(param.name.value)
        end

        handle(stmt.body_stmt)
      end
    end

    def handle_expr_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_return_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_integer_expr(expr)
    end

    def handle_identifier_expr(expr)
    end

    def handle_call_expr(expr)
      handle(expr.callee)
      expr.arg_exprs.each { |ae| handle(ae) }
    end

    def handle_true_expr(expr)
    end

    def handle_false_expr(expr)
    end

    def handle_null_expr(expr)
    end

    def handle_assign_expr(expr)
      handle(expr.left_expr)
      handle(expr.right_expr)
    end

    def handle_unary_expr(expr)
      handle(expr.expr)
    end

    def handle_binary_expr(expr)
      handle(expr.left_expr)
      handle(expr.right_expr)
    end

    def push_scope
      @scope = Scope.new(source_code: @scope.source_code, parent: @scope)
      yield
    ensure
      @scope = @scope.parent
    end
  end
end
