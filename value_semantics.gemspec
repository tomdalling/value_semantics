# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "value_semantics/version"

Gem::Specification.new do |spec|
  spec.name          = "value_semantics"
  spec.version       = ValueSemantics::VERSION
  spec.authors       = ["Tom Dalling"]
  spec.email         = [["tom", "@", "tomdalling.com"].join]

  spec.summary       = %q{Makes value classes, with lightweight validation and coercion.}
  spec.description   = %q{
    Generates modules that provide conventional value semantics for a given set of attributes.
    The behaviour is similar to an immutable `Struct` class,
    plus extensible, lightweight validation and coercion.
  }
  spec.homepage      = "https://github.com/tomdalling/value_semantics"
  spec.license       = "MIT"
  spec.files         = Dir['CHANGELOG.md', 'LICENSE.txt', 'README.md', 'lib/**/*']
  spec.require_paths = ["lib"]
  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/tomdalling/value_semantics/issues",
    "changelog_uri"     => "https://github.com/tomdalling/value_semantics/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/tomdalling/value_semantics/blob/v#{ValueSemantics::VERSION}/README.md",
    "source_code_uri"   => "https://github.com/tomdalling/value_semantics",
  }

  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "super_diff"
  spec.add_development_dependency "mutant-rspec"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "eceval"
end
