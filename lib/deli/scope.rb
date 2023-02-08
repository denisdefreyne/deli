# frozen_string_literal: true

module Deli
  class Scope
    attr_reader :source_code
    attr_reader :parent

    def initialize(source_code:, parent: nil)
      @source_code = source_code
      @parent = parent

      @contents = {}
    end

    def define(name)
      @contents[name] = DeliSymbol.new(name)
    end

    def resolve(name, span)
      @contents.fetch(name) do
        if @parent
          @parent.resolve(name, span)
        else
          raise Deli::LocatableError.new(
            @source_code,
            span,
            "Unknown name: #{name}",
          )
        end
      end
    end
  end
end
