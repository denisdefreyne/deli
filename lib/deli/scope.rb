# frozen_string_literal: true

module Deli
  class Scope
    attr_reader :parent

    def initialize(parent: nil)
      @parent = parent

      @contents = {}
    end

    def define(name)
      symbol = DeliSymbol.new(name)
      @contents[name] = symbol
      symbol
    end

    def resolve(name, span)
      @contents.fetch(name) do
        if @parent
          @parent.resolve(name, span)
        else
          raise Deli::LocatableError.new(
            "Unknown name: #{name}",
            span,
          )
        end
      end
    end
  end
end
