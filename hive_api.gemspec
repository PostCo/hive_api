# frozen_string_literal: true

require_relative "lib/hive_api/version"

Gem::Specification.new do |spec|
  spec.name = "hive_api"
  spec.version = HiveAPI::VERSION
  spec.authors = ["PostCo"]
  spec.email = ["engineering@postco.co"]

  spec.summary = "Rails-independent Ruby client for the Hive Merchant API"
  spec.description = "A small Ruby client foundation for integrating with Hive without depending on Rails."
  spec.homepage = "https://github.com/PostCo/hive_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "CHANGELOG.md", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-net_http", ">= 2.0"
  spec.add_dependency "activesupport", ">= 7.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "standard"
end
