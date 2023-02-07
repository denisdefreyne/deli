# frozen_string_literal: true

module Deli
  class SymbolDefiner
    def initialize(source_code, stmts)
      @source_code = source_code
      @stmts = stmts

      @scope = Scope.new
    end

    def call
      @stmts.each { eval_stmt(_1) }
    end

    private

    def eval_stmt(stmt)
      case stmt
      when AST::VarStmt
        eval_expr(stmt.value_expr)
        @scope.define(stmt.ident.value)
        stmt.scope = @scope
      when AST::PrintStmt
        eval_expr(stmt.expr)
        stmt.scope = @scope
      when AST::IfStmt
        # TODO
        raise 'not implemented yet'
      when AST::WhileStmt
        # TODO
        raise 'not implemented yet'
      when AST::GroupStmt
        # TODO
        raise 'not implemented yet'
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
        expr.scope = @scope
      when AST::IdentifierExpr
        expr.scope = @scope
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
        # TODO
        raise 'not implemented yet'
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected expr class: #{expr.class}"
      end
    end
  end
end
