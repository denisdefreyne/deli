# frozen_string_literal: true

module Deli
  Token = Struct.new(:type, :lexeme, :value, :span)
end
