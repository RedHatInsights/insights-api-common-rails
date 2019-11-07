module Insights
  module API
    module Common
      class Logging
        def self.activate(config)
          require 'manageiq/loggers'
          config.logger = if Rails.env.production?
                            config.colorize_logging = false
                            ManageIQ::Loggers::CloudWatch.new
                          else
                            ManageIQ::Loggers::Base.new(Rails.root.join("log", "#{Rails.env}.log"))
                          end
        end
      end
    end
  end
end
