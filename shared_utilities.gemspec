lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shared_utilities/version"

Gem::Specification.new do |spec|
  spec.name          = "shared_utilities"
  spec.version       = SharedUtilities::VERSION
  spec.authors       = ["Drew Bomhof"]
  spec.email         = ["dbomhof@redhat.com"]

  spec.summary       = %q{Shared Utilites for Microservices}
  spec.description   = %q{Header, Encryption, RBAC, Serialization General Utilities for shared microservices}
  spec.homepage      = "https://github.com/syncrou/shared-micro-utilities.git"
  spec.licenses      = ["Apache-2.0"]

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib","app","config"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "activemodel"
  spec.add_runtime_dependency "actionpack"
  spec.add_runtime_dependency "acts_as_tenant"
  spec.add_runtime_dependency "manageiq-password", ">=0.1.0"
  spec.add_runtime_dependency "pg", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "rspec-mocks"
end
