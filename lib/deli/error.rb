# frozen_string_literal: true

module Deli
  class Error < StandardError; end

  class InternalInconsistencyError < Error; end

  class LocatableError < Error
    attr_reader :short_message

    def initialize(source_code, span, short_message)
      super(short_message)

      @source_code = source_code
      @span = span
      @short_message = short_message
    end

    def message
      <<~MESSAGE
        #{@source_code.filename}:#{@span.row + 1}: #{@short_message}
        #{@source_code.show_span(@span)}
      MESSAGE
    end
  end
end
