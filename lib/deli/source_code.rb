# frozen_string_literal: true

module Deli
  class SourceCode
    attr_reader :filename
    attr_reader :string

    def initialize(filename, string)
      @filename = filename
      @string = string
    end

    def show_span(span)
      show_string(span.row, span.col, span.length)
    end

    def show_string(row, col, length)
      col_string = format('  %d  |  ', row + 1)

      indicator_indent = ' ' * (col_string.length + col)
      indicator = '^' * [length, 1].max

      "#{col_string}#{lines[row]}\n#{indicator_indent}#{indicator}"
    end

    private

    def lines
      @_lines ||= string.lines.map(&:chomp)
    end
  end
end
