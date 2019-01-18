module ManageIQ
  module API
    module Common
      class Metrics
        def self.activate(config, prefix)
          require 'prometheus/middleware/collector'
          require 'prometheus/middleware/exporter'

          config.middleware.use(Prometheus::Middleware::Collector, :metrics_prefix => prefix)
          config.middleware.use(Prometheus::Middleware::Exporter)
        end
      end
    end
  end
end
