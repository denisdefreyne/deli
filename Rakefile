require "minitest/test_task"
require "rubocop/rake_task"

Minitest::TestTask.create(:minitest) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_globs = ["test/**/*_test.rb"]
end

RuboCop::RakeTask.new(:rubocop)

task test: [:minitest, :rubocop]
task default: :test
