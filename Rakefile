# frozen_string_literal: true

require 'minitest/test_task'
require 'rubocop/rake_task'
require 'bundler/gem_tasks'

Minitest::TestTask.create(:minitest) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*_test.rb']
end

RuboCop::RakeTask.new(:rubocop)

task test: %i[minitest rubocop]
task default: :test
