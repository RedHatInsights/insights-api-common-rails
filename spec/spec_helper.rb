if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment", __FILE__)

require 'rspec/rails'

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

require "factory_bot"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.include UserHeaderSpecHelper
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
