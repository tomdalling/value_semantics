# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "value_semantics/version"

Gem::Specification.new do |spec|
  spec.name          = "value_semantics"
  spec.version       = ValueSemantics::VERSION
  spec.authors       = ["Tom Dalling"]
  spec.email         = [["tom", "@", "tomdalling.com"].join]

  spec.summary       = %q{Create value classes quickly, with all the proper conventions.}
  spec.description   = %q{
    Create value classes quickly, with all the proper conventions.

    Generates modules that provide value semantics for a given set of attributes.
    Provides the behaviour of an immutable struct-like value class,
    with light-weight validation and coercion.
  }
  spec.homepage      = "https://github.com/tomdalling/value_semantics"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.7.0"
  spec.add_development_dependency "mutant-rspec", "0.8.17"
  spec.add_development_dependency "mutant", "0.8.23"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "gem-release"
end
