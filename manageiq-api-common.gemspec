$:.push File.expand_path("../lib", __FILE__)
require "manageiq/api/version"

Gem::Specification.new do |spec|
  spec.name          = "manageiq-api-common"
  spec.version       = ManageIQ::API::VERSION
  spec.authors       = ["Drew Bomhof"]
  spec.email         = ["dbomhof@redhat.com"]

  spec.summary       = %q{Common Utilites for Microservices}
  spec.description   = %q{Header, Encryption, RBAC, Serialization Common Behavior for microservices}
  spec.homepage      = "https://github.com/ManageIQ/manageiq-api-common.git"
  spec.licenses      = ["Apache-2.0"]

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
