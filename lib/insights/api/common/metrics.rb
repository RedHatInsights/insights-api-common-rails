module Insights
  module API
    module Common
      class Metrics
        def self.activate(config, prefix, args = {})
          require 'prometheus_exporter'
          require 'prometheus_exporter/client'

          setup_custom_metrics(args[:custom_metrics])

          return if metrics_port == 0

          ensure_exporter_server
          enable_in_process_metrics
          enable_web_server_metrics(prefix)
        end

        private_class_method def self.ensure_exporter_server
          require 'socket'
          TCPSocket.open("127.0.0.1", metrics_port) {}
        rescue Errno::ECONNREFUSED
          require 'prometheus_exporter/server'
          server = PrometheusExporter::Server::WebServer.new(port: metrics_port)
          server.start

          PrometheusExporter::Client.default = PrometheusExporter::LocalClient.new(collector: server.collector)
        end

        private_class_method def self.enable_in_process_metrics
          require 'prometheus_exporter/instrumentation'

          # this reports basic process metrics such as RSS and Ruby metrics
          PrometheusExporter::Instrumentation::Process.start
        end

        private_class_method def self.enable_web_server_metrics(prefix)
          require "insights/api/common/middleware/web_server_metrics"
          Rails.application.middleware.unshift(Insights::API::Common::Middleware::WebServerMetrics, :metrics_prefix => prefix)
        end

        private_class_method def self.setup_custom_metrics(custom_metrics)
          return if custom_metrics.nil?

          custom_metrics.each do |metric|
            if metrics_port == 0
              define_singleton_method(metric[:name]) {}
            else
              instance_variable_set("@#{metric[:name]}_#{metric[:type]}", PrometheusExporter::Client.default.register(metric[:type], metric[:name], metric[:description]))

              define_singleton_method(metric[:name]) do
                case metric[:type]
                when :counter
                  instance_variable_get("@#{metric[:name]}_#{metric[:type]}")&.observe(1)
                else
                  "Metric of type #{metric[:type]} unsupported, implement it in Insights::API::Common::Metrics#L45"
                end
              end
            end
          end
        end

        private_class_method def self.metrics_port
          @metrics_port ||= (ENV['METRICS_PORT']&.to_i || 9394)
        end
      end
    end
  end
end
