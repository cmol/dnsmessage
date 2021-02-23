# frozen_string_literal: true

require_relative "lib/dnsmessage/version"

Gem::Specification.new do |spec|
  spec.name          = "dnsmessage"
  spec.version       = DNSMessage::VERSION
  spec.authors       = ["Claus Lensbøl"]
  spec.email         = ["cmol@cmol.dk"]

  spec.summary       = "Ruby library to build and parse DNS messages"
  spec.description   = 'A full featured DNS parser. The library supports DNS
name compression and gives access to parse, build, and manipulate all aspects
of the DNS queries and replies.'
  spec.homepage      = "https://github.com/cmol/dnsmessage"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmol/dnsmessage"
  spec.metadata["changelog_uri"] = "https://github.com/cmol/dnsmessage"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
