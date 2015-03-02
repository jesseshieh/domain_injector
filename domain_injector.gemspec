# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'domain_injector/version'

Gem::Specification.new do |spec|
  spec.name          = "domain_injector"
  spec.version       = DomainInjector::VERSION
  spec.authors       = ["Jesse Shieh"]
  spec.email         = ["jesse.shieh.pub@gmail.com"]
  spec.summary       = %q{Lightweight dependency injection tool. Constructs objects and injects their constructor parameters based on their names.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "memoist"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
end
