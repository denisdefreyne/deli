# frozen_string_literal: true

module Deli
  class Error < StandardError; end

  class InternalInconsistencyError < Error; end

  class LocatableError < Error
    attr_reader :span

    def initialize(message, span)
      super(message)

      @span = span
    end
  end
end
