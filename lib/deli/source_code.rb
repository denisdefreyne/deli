module Deli
  class SourceCode
    attr_reader :filename
    attr_reader :string

    def initialize(filename, string)
      @filename = filename
      @string = string
    end

    def locate_token(token)
      locate_string(token.row, token.col, token.lexeme.length)
    end

    def locate_string(row, col, length)
      col_string = format("  %d  |  ", row + 1)

      indicator_indent = " " * (col_string.length + col)
      indicator = "^" * length

      "#{col_string}#{lines[row]}\n#{indicator_indent}#{indicator}"
    end

    private

    def lines
      @_lines ||= string.lines.map(&:chomp)
    end
  end
end
