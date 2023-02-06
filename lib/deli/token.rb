# frozen_string_literal: true

module Deli
  class Token
    attr_reader :type
    attr_reader :lexeme
    attr_reader :value
    attr_reader :span

    def initialize(type:, lexeme:, value:, span:)
      @type   = type
      @lexeme = lexeme
      @value  = value
      @span   = span
    end

    def inspect
      format(
        '%-10<type>s  %<value>s',
        {
          type:,
          value: value&.inspect,
        },
      ).strip
    end
  end
end
