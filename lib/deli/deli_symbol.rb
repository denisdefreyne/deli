# frozen_string_literal: true

module Deli
  class DeliSymbol
    class << self
      def next_num
        @num ||= 0
        @num += 1
      end
    end

    attr_reader :num
    attr_reader :name

    def initialize(name)
      @num = self.class.next_num
      @name = name
    end
  end
end
