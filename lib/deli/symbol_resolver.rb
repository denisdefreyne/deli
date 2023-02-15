# frozen_string_literal: true

module Deli
  class SymbolResolver < AbstractWalker
    def handle_var_stmt(stmt)
      handle(stmt.expr)
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
      stmt.stmts.each { |s| handle(s) }
    end

    def handle_fun_stmt(stmt)
      handle(stmt.body_stmt)
    end

    def handle_struct_stmt(stmt)
    end

    def handle_expr_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_return_stmt(stmt)
      handle(stmt.expr)
    end

    def handle_integer_expr(expr)
    end

    def handle_string_part_lit_expr(expr)
    end

    def handle_string_part_interp_expr(expr)
      handle(expr.expr)
    end

    def handle_string_expr(expr)
      expr.parts.each { |part| handle(part) }
    end

    def handle_identifier_expr(expr)
      symbol = expr.scope.resolve(expr.ident.value, expr.ident.span)
      expr.symbol = symbol
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
  end
end
