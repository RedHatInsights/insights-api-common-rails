module ManageIQ
  module API
    module Common
      class Logging
        def self.activate(config)
          require 'manageiq/loggers'
          config.logger = if Rails.env.production?
                            config.colorize_logging = false
                            ::Rails.logger.request_id = Proc.new do
                              "Hello 123"
                            end
                            ManageIQ::Loggers::Container.new
                          else
                            ManageIQ::Loggers::Base.new(Rails.root.join("log", "#{Rails.env}.log"))
                          end
        end
      end
    end
  end
end
