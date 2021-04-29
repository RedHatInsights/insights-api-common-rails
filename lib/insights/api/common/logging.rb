module Insights
  module API
    module Common
      class Logging
        def self.logger_class
          if ENV['LOG_HANDLER'] == "haberdasher"
            "Insights::Loggers::StdErrorLogger"
          else
            "Insights::Loggers::CloudWatch"
          end
        end

        def self.activate(config, app_name = nil)
          require 'insights/loggers'
          log_params = {}
          klass_for_logger = if Rails.env.production?
                               config.colorize_logging = false
                               log_params[:app_name] = app_name if app_name
                               logger_class
                             else
                               log_params = {:log_path => Rails.root.join("log", "#{Rails.env}.log")}
                               "ManageIQ::Loggers::Base"
                             end

          config.logger = Insights::Loggers::Factory.create_logger(klass_for_logger, log_params)
        end
      end
    end
  end
end
