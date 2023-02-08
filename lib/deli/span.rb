# frozen_string_literal: true

module Deli
  class Span
    attr_reader :filename
    attr_reader :row
    attr_reader :col
    attr_reader :length

    def initialize(filename, row, col, length)
      @filename = filename
      @row = row
      @col = col
      @length = length
    end
  end
end
