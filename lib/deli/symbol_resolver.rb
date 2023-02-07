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
        eval_expr(stmt.value_expr)
      when AST::PrintStmt
        eval_expr(stmt.expr)
      when AST::IfStmt
        eval_expr(stmt.cond_expr)
        eval_stmt(stmt.true_stmt)
        if stmt.false_stmt
          eval_stmt(stmt.false_stmt)
        end
      when AST::WhileStmt
        # TODO
        raise 'not implemented yet'
      when AST::GroupStmt
        stmt.stmts.each { |s| eval_stmt(s) }
      when AST::FunStmt
        # TODO
        raise 'not implemented yet'
      when AST::ExprStmt
        # TODO
        raise 'not implemented yet'
      when AST::ReturnStmt
        # TODO
        raise 'not implemented yet'
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected stmt class: #{stmt.class}"
      end
    end

    def eval_expr(expr)
      case expr
      when AST::IntegerExpr
        # Do nothing
      when AST::IdentifierExpr
        symbol = expr.scope[expr.ident.value]
        expr.symbol = symbol
      when AST::CallExpr
        # TODO
        raise 'not implemented yet'
      when AST::TrueExpr
        # TODO
        raise 'not implemented yet'
      when AST::FalseExpr
        # TODO
        raise 'not implemented yet'
      when AST::NullExpr
        # TODO
        raise 'not implemented yet'
      when AST::AssignExpr
        # TODO
        raise 'not implemented yet'
      when AST::UnaryExpr
        # TODO
        raise 'not implemented yet'
      when AST::BinaryExpr
        eval_expr(expr.left)
        eval_expr(expr.right)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected expr class: #{expr.class}"
      end
    end
  end
end
