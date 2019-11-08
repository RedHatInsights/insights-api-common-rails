module Insights
  module API
    module Common
      class Metrics
        def self.activate(config, prefix)
          require 'prometheus_exporter'
          require 'prometheus_exporter/client'

          ensure_exporter_server
          enable_in_process_metrics
          enable_web_server_metrics(prefix)
        end

        private_class_method def self.ensure_exporter_server
          require 'socket'
          TCPSocket.open("localhost", 9394) {}
        rescue Errno::ECONNREFUSED
          require 'prometheus_exporter/server'
          server = PrometheusExporter::Server::WebServer.new(port: 9394)
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
      end
    end
  end
end
