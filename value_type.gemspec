# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "value_type/version"

Gem::Specification.new do |spec|
  spec.name          = "value_type"
  spec.version       = ValueType::VERSION
  spec.authors       = ["Tom Dalling"]
  spec.email         = [["tom", "@", "tomdalling.com"].join]

  spec.summary       = %q{Immutable struct-like value classes, with light-weight validation and coercion.}
  spec.description   = %q{Immutable struct-like value classes, with light-weight validation and coercion.}
  spec.homepage      = "https://github.com/tomdalling/value_type"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rspec", "~> 3.0"
end
