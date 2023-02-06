# frozen_string_literal: true

require_relative 'lib/deli/version'

Gem::Specification.new do |spec|
  spec.name = 'deli-lang'
  spec.version = Deli::VERSION
  spec.authors = ['Denis Defreyne']
  spec.email = ['deli@denisdefreyne.com']

  spec.summary = 'Denis’ Example Language (for Interpretation)'
  spec.description = 'The interpreter for DELI, a language for demonstrating how to write interpreters.'
  spec.homepage = 'https://deli.denisdefreyne.com'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = ''
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/denisdefreyne/deli'
  spec.metadata['changelog_uri'] = 'https://github.com/denisdefreyne/deli/releases'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
