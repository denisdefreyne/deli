module Deli
  Token = Struct.new(:type, :lexeme, :value, :span) do
    def col
      span.col
    end
  end
end
