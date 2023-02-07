# frozen_string_literal: true

module Deli
  class TokenType
    attr_reader :symbol
    attr_reader :name

    def initialize(symbol, name)
      @symbol = symbol
      @name   = name
    end

    def to_s
      "#{name} (#{symbol})"
    end
  end
end
