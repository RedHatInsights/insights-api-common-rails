$:.push File.expand_path("lib", __dir__)
require "manageiq/api/common/version"

Gem::Specification.new do |spec|
  spec.name          = "manageiq-api-common"
  spec.version       = ManageIQ::API::Common::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = %q{Common Utilites for Microservices}
  spec.description   = %q{Header, Encryption, RBAC, Serialization Common Behavior for microservices}
  spec.homepage      = "https://github.com/ManageIQ/manageiq-api-common.git"
  spec.licenses      = ["Apache-2.0"]

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  spec.add_runtime_dependency "acts_as_tenant"
  spec.add_runtime_dependency "manageiq-password", "~>0.1"
  spec.add_runtime_dependency "pg", "> 0"
  spec.add_runtime_dependency "rails", ">= 5.2.1.1", "~> 5.2"

  # For ManageIQ::API::Common::Logging
  spec.add_runtime_dependency "manageiq-loggers", "~> 0.3"
  spec.add_runtime_dependency "cloudwatchlogger", "~> 0.2"

  # For ManageIQ::API::Common::Metrics
  spec.add_runtime_dependency 'prometheus_exporter', '~> 0.4.5'

  # For ManageIQ::API::Common::OpenApi
  spec.add_runtime_dependency "more_core_extensions"

  # For ManageIQ::API::Common::GraphQL
  spec.add_runtime_dependency "graphql",         "~> 1.7"
  spec.add_runtime_dependency "graphql-batch",   "~> 0.3.8"
  spec.add_runtime_dependency "graphql-preload", "~> 1.0"

  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "rspec-rails", "~> 3.8"
  spec.add_development_dependency "simplecov"
end
