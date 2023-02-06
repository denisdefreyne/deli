# frozen_string_literal: true

module Deli
  Token = Struct.new(:type, :lexeme, :value, :span) do
    def inspect
      format('%-10<type>s  %<value>s', {type:, value: value ? value.inspect : nil}).strip
    end
  end
end
