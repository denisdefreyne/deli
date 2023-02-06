# frozen_string_literal: true

require 'optparse'
require 'singleton'
require 'stringio'
require 'strscan'

require_relative 'deli/version'
require_relative 'deli/cli'

# Utilities
require_relative 'deli/source_code'
require_relative 'deli/error'
require_relative 'deli/span'

# Primary models
require_relative 'deli/token'
require_relative 'deli/ast'

# Services
require_relative 'deli/lexer'
require_relative 'deli/parser'
require_relative 'deli/evaluator'
