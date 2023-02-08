# frozen_string_literal: true

module Deli
  class SourceCode
    attr_reader :filename
    attr_reader :string

    def initialize(filename, string)
      @filename = filename
      @string = string
    end

    def show_span(span, message)
      row, col = calc_row_and_col(span.offset)

      col_string = format('  %d  |  ', row + 1)

      indicator_indent = ' ' * (col_string.length + col)
      indicator = '^' * [span.length, 1].max

      "#{span.filename}:#{row + 1}: #{message}\n" \
        "#{col_string}#{lines[row]}\n#{indicator_indent}#{indicator}"
    end

    private

    def calc_row_and_col(offset)
      scanner = StringScanner.new(string)

      row = 0
      col = 0

      while !scanner.eos? && scanner.pos < offset
        if scanner.scan(/\n/)
          row += 1
          col = 0
        elsif scanner.scan(/[^\n]+/)
          col += scanner.matched.length

          if scanner.pos > offset
            col -= (scanner.pos - offset)
          end
        end
      end

      [row, col]
    end

    def lines
      @_lines ||= string.lines.map(&:chomp)
    end
  end
end
