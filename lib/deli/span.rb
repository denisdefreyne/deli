# frozen_string_literal: true

module Deli
  class Span
    attr_reader :filename
    attr_reader :offset
    attr_reader :length

    def initialize(filename, offset, length)
      @filename = filename
      @offset = offset
      @length = length
    end
  end
end
