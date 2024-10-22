# frozen_string_literal: true

require 'optparse'
require 'singleton'
require 'stringio'
require 'strscan'

require_relative 'deli/version'

# Utilities
require_relative 'deli/source_code'
require_relative 'deli/error'
require_relative 'deli/span'
require_relative 'deli/abstract_walker'

# Primary models
require_relative 'deli/token'
require_relative 'deli/token_type'
require_relative 'deli/deli_symbol'
require_relative 'deli/scope'
require_relative 'deli/ast'

# Services
require_relative 'deli/lexer'
require_relative 'deli/parser'
require_relative 'deli/evaluator'
require_relative 'deli/symbol_definer'
require_relative 'deli/symbol_resolver'

# UI
require_relative 'deli/cli'
