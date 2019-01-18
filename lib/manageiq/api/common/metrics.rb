module ManageIQ
  module API
    module Common
      class Metrics
        def self.activate(config)
          require 'prometheus/middleware/collector'
          require 'prometheus/middleware/exporter'

          config.middleware.use(Prometheus::Middleware::Collector)
          config.middleware.use(Prometheus::Middleware::Exporter)
        end
      end
    end
  end
end
