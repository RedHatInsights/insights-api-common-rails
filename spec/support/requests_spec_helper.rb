require_relative "default_as_json"

module RequestSpecHelper
  RSpec.configure do |config|
    config.include DefaultAsJson, :type => :request
  end
end
