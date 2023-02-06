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
      col_string = format('  %d  |  ', span.row + 1)

      indicator_indent = ' ' * (col_string.length + span.col)
      indicator = '^' * [span.length, 1].max

      "#{col_string}#{lines[span.row]}\n#{indicator_indent}#{indicator}"
    end

    private

    def lines
      @_lines ||= string.lines.map(&:chomp)
    end
  end
end
