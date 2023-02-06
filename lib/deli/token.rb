# frozen_string_literal: true

module Deli
  Token = Struct.new(:type, :lexeme, :value, :span) do
    def inspect
      format "%-10s  %s", type, value ? value.inspect : nil
    end
  end
end
