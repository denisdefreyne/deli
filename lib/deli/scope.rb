# frozen_string_literal: true

module Deli
  class Scope
    def initialize(parent: nil)
      @parent = parent

      @contents = {}
    end

    def define(name)
      @contents[name] = DeliSymbol.new(name)
    end

    def [](name)
      @contents[name]
    end
  end
end
