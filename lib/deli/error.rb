module Deli
  class Error < StandardError; end

  class CharLocatableError < Error
    def initialize(source_code, row, col, message)
      @source_code = source_code
      @row = row
      @col = col
      @message = message
    end

    def message
      <<~MESSAGE
        #{@source_code.filename}:#{@row + 1}: #{@message}
        #{@source_code.locate_string(@row, @col, 1)}
      MESSAGE
    end
  end

  class TokenLocatableError < Error
    def initialize(source_code, token, message)
      @source_code = source_code
      @token = token
      @message = message
    end

    def message
      <<~MESSAGE
        #{@source_code.filename}:#{@token.row + 1}: #{@message}
        #{@source_code.locate_token(@token)}
      MESSAGE
    end
  end
end
