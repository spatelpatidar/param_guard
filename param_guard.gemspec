# frozen_string_literal: true

require_relative "lib/param_guard/version"

Gem::Specification.new do |spec|
  spec.name          = "param_guard"
  spec.version       = ParamGuard::VERSION
  spec.authors       = ["Shailendra Kumar"]
  spec.email         = ["shailendrapatidar00@gmail.com"]

  spec.summary       = "A clean DSL for validating controller and service object parameters in Ruby/Rails."
  spec.description   = <<~DESC
    ParamGuard provides a declarative DSL for validating incoming parameters before
    they reach your business logic. Supports required/optional fields, type coercion,
    range checks, and inclusion lists — with structured error reporting.
  DESC
  spec.homepage      = "https://github.com/spatelpatidar/param_guard"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE.txt",
    "CHANGELOG.md",
    "param_guard.gemspec"
  ]

  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec",     "~> 3.12"
  spec.add_development_dependency "rake",      "~> 13.0"
end
