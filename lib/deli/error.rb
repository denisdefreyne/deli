module Deli
  class Error < StandardError; end

  class LocatableError < Error
    def initialize(source_code, span, message)
      @source_code = source_code
      @span = span
      @message = message
    end

    def message
      <<~MESSAGE
        #{@source_code.filename}:#{@span.row + 1}: #{@message}
        #{@source_code.show_span(@span)}
      MESSAGE
    end
  end
end
