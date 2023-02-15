# frozen_string_literal: true

module Deli
  class AbstractWalker
    def initialize(stmts)
      @stmts = stmts
    end

    def call
      @stmts.each { handle(_1) }
    end

    private

    def handle(node)
      case node
      when AST::VarStmt
        handle_var_stmt(node)
      when AST::PrintStmt
        handle_print_stmt(node)
      when AST::IfStmt
        handle_if_stmt(node)
      when AST::WhileStmt
        handle_while_stmt(node)
      when AST::GroupStmt
        handle_group_stmt(node)
      when AST::FunStmt
        handle_fun_stmt(node)
      when AST::StructStmt
        handle_struct_stmt(node)
      when AST::ExprStmt
        handle_expr_stmt(node)
      when AST::ReturnStmt
        handle_return_stmt(node)
      when AST::IntegerExpr
        handle_integer_expr(node)
      when AST::StringPartLitExpr
        handle_string_part_lit_expr(node)
      when AST::StringPartInterpExpr
        handle_string_part_interp_expr(node)
      when AST::StringExpr
        handle_string_expr(node)
      when AST::IdentifierExpr
        handle_identifier_expr(node)
      when AST::CallExpr
        handle_call_expr(node)
      when AST::TrueExpr
        handle_true_expr(node)
      when AST::FalseExpr
        handle_false_expr(node)
      when AST::NullExpr
        handle_null_expr(node)
      when AST::AssignExpr
        handle_assign_expr(node)
      when AST::UnaryExpr
        handle_unary_expr(node)
      when AST::BinaryExpr
        handle_binary_expr(node)
      when AST::NewExpr
        handle_new_expr(node)
      else
        raise Deli::InternalInconsistencyError,
          "Unexpected class: #{node.class}"
      end
    end
  end
end
