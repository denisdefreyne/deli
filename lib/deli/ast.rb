# frozen_string_literal: true

module Deli
  module AST
    VarStmt = Struct.new(:identifier, :value_expr)
    PrintStmt = Struct.new(:expr)

    IntegerExpr = Struct.new(:value)
    IdentifierExpr = Struct.new(:identifier)
  end
end
