# frozen_string_literal: true

module Deli
  class SymbolDefiner
    def initialize(source_code, stmts)
      @source_code = source_code
      @stmts = stmts

      @scope = Scope.new(source_code: @source_code)
    end

    def call
      @stmts.each { handle_stmt(_1) }
    end

    private

    def handle_stmt(stmt)
      stmt.scope = @scope

      case stmt
      when AST::VarStmt
        handle_var_stmt(stmt)
      when AST::PrintStmt
        handle_print_stmt(stmt)
      when AST::IfStmt
        handle_if_stmt(stmt)
      when AST::WhileStmt
        handle_while_stmt(stmt)
      when AST::GroupStmt
        handle_group_stmt(stmt)
      when AST::FunStmt
        handle_fun_stmt(stmt)
      when AST::ExprStmt
        handle_expr_stmt(stmt)
      when AST::ReturnStmt
        handle_return_stmt(stmt)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected stmt class: #{stmt.class}"
      end
    end

    def handle_expr(expr)
      expr.scope = @scope

      case expr
      when AST::IntegerExpr
        handle_integer_expr(expr)
      when AST::IdentifierExpr
        handle_identifier_expr(expr)
      when AST::CallExpr
        handle_call_expr(expr)
      when AST::TrueExpr
        handle_true_expr(expr)
      when AST::FalseExpr
        handle_false_expr(expr)
      when AST::NullExpr
        handle_null_expr(expr)
      when AST::AssignExpr
        handle_assign_expr(expr)
      when AST::UnaryExpr
        handle_unary_expr(expr)
      when AST::BinaryExpr
        handle_binary_expr(expr)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected expr class: #{expr.class}"
      end
    end

    def handle_var_stmt(stmt)
      handle_expr(stmt.expr)
      symbol = @scope.define(stmt.ident.value)
      stmt.symbol = symbol
    end

    def handle_print_stmt(stmt)
      handle_expr(stmt.expr)
    end

    def handle_if_stmt(stmt)
      handle_expr(stmt.cond_expr)
      handle_stmt(stmt.true_stmt)
      if stmt.false_stmt
        handle_stmt(stmt.false_stmt)
      end
    end

    def handle_while_stmt(stmt)
      handle_expr(stmt.cond_expr)
      handle_stmt(stmt.body_stmt)
    end

    def handle_group_stmt(stmt)
      push_scope do
        stmt.stmts.each { |s| handle_stmt(s) }
      end
    end

    def handle_fun_stmt(stmt)
      symbol = @scope.define(stmt.ident.value)
      stmt.symbol = symbol

      push_scope do
        stmt.params.each do |param|
          param.symbol = @scope.define(param.name.value)
        end

        handle_stmt(stmt.body_stmt)
      end
    end

    def handle_expr_stmt(stmt)
      handle_expr(stmt.expr)
    end

    def handle_return_stmt(stmt)
      handle_expr(stmt.expr)
    end

    def handle_integer_expr(expr)
    end

    def handle_identifier_expr(expr)
    end

    def handle_call_expr(expr)
      handle_expr(expr.callee)
      expr.arg_exprs.each { |ae| handle_expr(ae) }
    end

    def handle_true_expr(expr)
    end

    def handle_false_expr(expr)
    end

    def handle_null_expr(expr)
    end

    def handle_assign_expr(expr)
      handle_expr(expr.left_expr)
      handle_expr(expr.right_expr)
    end

    def handle_unary_expr(expr)
      handle_expr(expr.expr)
    end

    def handle_binary_expr(expr)
      handle_expr(expr.left_expr)
      handle_expr(expr.right_expr)
    end

    def push_scope
      @scope = Scope.new(source_code: @scope.source_code, parent: @scope)
      yield
    ensure
      @scope = @scope.parent
    end
  end
end
