# frozen_string_literal: true

module Deli
  class Span
    attr_reader :row
    attr_reader :col
    attr_reader :length

    def initialize(row, col, length)
      @row = row
      @col = col
      @length = length
    end
  end
end
