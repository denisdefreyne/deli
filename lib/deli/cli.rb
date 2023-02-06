# frozen_string_literal: true

module Deli
  class CLI
    def initialize(args)
      @args = args
    end

    def call
      if @args.size != 1
        warn 'usage: deli [path]'
        exit 64
      end

      contents = File.read(@args[0])
      source_code = Deli::SourceCode.new(@args[0], contents)

      lexer = Deli::Lexer.new(source_code)
      tokens = lexer.call

      parser = Deli::Parser.new(source_code, tokens)
      stmts = parser.call

      evaluator = Deli::Evaluator.new(source_code, stmts)
      evaluator.call
    rescue Deli::Error => e
      warn e.message
    end
  end
end
