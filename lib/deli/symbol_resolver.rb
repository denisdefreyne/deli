# frozen_string_literal: true

module Deli
  class SymbolResolver
    def initialize(source_code, stmts)
      @source_code = source_code
      @stmts = stmts
    end

    def call
      @stmts.each { eval_stmt(_1) }
    end

    private

    def eval_stmt(stmt)
      case stmt
      when AST::VarStmt
        eval_expr(stmt.expr)
      when AST::PrintStmt
        eval_expr(stmt.expr)
      when AST::IfStmt
        eval_expr(stmt.cond_expr)
        eval_stmt(stmt.true_stmt)
        if stmt.false_stmt
          eval_stmt(stmt.false_stmt)
        end
      when AST::WhileStmt
        eval_expr(stmt.cond_expr)
        eval_stmt(stmt.body_stmt)
      when AST::GroupStmt
        stmt.stmts.each { |s| eval_stmt(s) }
      when AST::FunStmt
        eval_stmt(stmt.body_stmt)
      when AST::ExprStmt
        eval_expr(stmt.expr)
      when AST::ReturnStmt
        eval_expr(stmt.expr)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected stmt class: #{stmt.class}"
      end
    end

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr
      when AST::IdentifierExpr
        symbol = expr.scope.resolve(expr.ident.value, expr.ident.span)
        expr.symbol = symbol
      when AST::CallExpr
        eval_expr(expr.callee)
        expr.arg_exprs.each { |ae| eval_expr(ae) }
      when AST::TrueExpr
      when AST::FalseExpr
      when AST::NullExpr
      when AST::AssignExpr
        eval_expr(expr.left_expr)
        eval_expr(expr.right_expr)
      when AST::UnaryExpr
        eval_expr(expr.expr)
      when AST::BinaryExpr
        eval_expr(expr.left_expr)
        eval_expr(expr.right_expr)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected expr class: #{expr.class}"
      end
    end
  end
end
