# frozen_string_literal: true

module Deli
  class CLI
    def initialize(args)
      @args = args.dup
    end

    def call
      # Parse options
      options = {}
      parser = OptionParser.new
      parser.banner = 'Usage: deli [options] path'
      parser.on('--dump-ast', 'Dump AST') do |_value|
        options[:dump_ast] = true
      end
      parser.on('--dump-tokens', 'Dump tokens') do |_value|
        options[:dump_tokens] = true
      end
      parser.parse!(@args)

      if @args.size != 1
        warn 'usage: deli [options] path'
        exit 64
      end

      contents = File.read(@args[0])
      source_code = Deli::SourceCode.new(@args[0], contents)

      lexer = Deli::Lexer.new(source_code)
      tokens = lexer.call
      if options.fetch(:dump_tokens, false)
        warn '--- Tokens'
        tokens.each do |token|
          warn token.inspect
        end
        warn '---'
        warn
      end

      parser = Deli::Parser.new(tokens)
      stmts = parser.call
      if options.fetch(:dump_ast, false)
        warn '--- AST'
        stmts.each do |stmt|
          Deli::AST.dump_sexp(stmt.to_sexp, $stdout, 0)
          $stdout.puts
        end
        warn '---'
        warn
      end

      Deli::SymbolDefiner.new(stmts).call
      Deli::SymbolResolver.new(stmts).call

      evaluator = Deli::Evaluator.new(stmts)
      evaluator.call
    rescue Deli::LocatableError => e
      warn "#{e.span.filename}:#{e.span.row + 1}: #{e.message}"
      warn source_code.show_span(e.span)
      exit 1
    rescue Deli::Error => e
      warn e.message
      exit 1
    end
  end
end
