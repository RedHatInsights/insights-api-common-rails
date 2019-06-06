module ManageIQ
  module API
    module Common
      module Middleware
        class WebServerMetrics
          def initialize(app, options = {})
            @app            = app
            @metrics_prefix = options[:metrics_prefix] || "http_server"

            require 'prometheus_exporter/client'
            require 'prometheus_exporter/metric'

            PrometheusExporter::Metric::Base.default_prefix = "#{@metrics_prefix}_"

            @puma_busy_threads = PrometheusExporter::Client.default.register(:gauge, "puma_busy_threads", "The number of threads currently handling HTTP requests.")
            @puma_max_threads  = PrometheusExporter::Client.default.register(:gauge, "puma_max_threads", "The total number of threads able to handle HTTP requests.")
            @request_counter   = PrometheusExporter::Client.default.register(:counter, "requests_total", "The total number of HTTP requests handled by the Rack application.")
            @request_histogram = PrometheusExporter::Client.default.register(:histogram, "request_duration_seconds", "The HTTP response duration of the Rack application.")
          end

          def call(env)
            @puma_busy_threads.increment

            result = nil
            duration = Benchmark.realtime { result = @app.call(env) }
            result
          rescue => error
            @error = error
            raise
          ensure
            duration_labels = {
              :method => env['REQUEST_METHOD'].downcase,
              :path   => strip_ids_from_path(env['PATH_INFO']),
            }

            counter_labels = duration_labels.merge(:code => result.first.to_s).tap do |labels|
              labels[:exception] = @error.class.name if @error
            end

            @request_counter.increment(counter_labels)
            @request_histogram.observe(duration, duration_labels)

            @puma_max_threads.observe(JSON.parse(Puma.stats)["max_threads"])
            @puma_busy_threads.decrement
          end

          private

          def strip_ids_from_path(path)
            path.gsub(%r{/\d+(/|$)}, '/:id\\1')
          end
        end
      end
    end
  end
end
