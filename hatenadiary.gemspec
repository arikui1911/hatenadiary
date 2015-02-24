# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hatenadiary/version'

Gem::Specification.new do |spec|
  spec.name          = "hatenadiary"
  spec.version       = Hatenadiary::VERSION
  spec.authors       = ["arikui1911"]
  spec.email         = ["arikui.ruby@gmail.com"]

  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  # end

  spec.summary       = %q{A client for Hatena Diary to post and delete blog entries.}
  spec.description   = %q{It is a library provides a client for Hatena Diary to post and delete blog entries.}
  spec.homepage      = "https://github.com/arikui1911/hatenadiary"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mechanize", "~> 0"
  if RUBY_VERSION >= "2.0.0"
    spec.add_runtime_dependency "iconv", "~> 1.0.0"
  end

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "test-unit", "~> 0"
  spec.add_development_dependency "flexmock", "~> 0"
end
