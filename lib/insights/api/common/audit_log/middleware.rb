module Insights::API::Common
  class AuditLog
    class Middleware
      attr_reader :logger, :evidence, :request, :status

      def initialize(app)
        @app = app
        @logger = AuditLog.logger
        @subscribers = []
        @evidence = {}
      end

      def call(env)
        subscribe
        @request = ActionDispatch::Request.new(env)
        @app.call(env).tap do |status, _headers, _body|
          @status = status
          response_finished
        end
      ensure
        unsubscribe
      end

      private

      def response_finished
        payload = {
          :controller => evidence[:controller],
          :remote_ip  => request.remote_ip,
          :message    => generate_message
        }
        log(payload)
      end

      def generate_message
        status_label = Rack::Utils::HTTP_STATUS_CODES[status]
        msg = "#{request.method} #{request.original_fullpath} -> #{status} #{status_label}"
        if evidence[:unpermitted_parameters]
          msg += "; unpermitted params #{fmt_params(evidence[:unpermitted_parameters])}"
        end
        if evidence[:halted_callback].present?
          msg += "; filter chain halted by :#{evidence[:halted_callback]}"
        end
        msg
      end

      def log(payload)
        if status < 400
          logger.info(payload)
        elsif status < 500
          logger.warn(payload)
        else
          logger.error(payload)
        end
      end

      def subscribe
        @subscribers << subscribe_conroller
      end

      def subscribe_conroller
        ActiveSupport::Notifications.subscribe(/\.action_controller$/) do |name, _started, _finished, _unique_id, payload|
          # https://guides.rubyonrails.org/active_support_instrumentation.html#action-controller
          case name.split('.')[0]
          when 'process_action'
            @evidence[:controller] = fmt_controller(payload)
          when 'halted_callback'
            @evidence[:halted_callback] = payload[:filter]
          when 'unpermitted_parameters'
            @evidence[:unpermitted_parameters] = payload[:keys]
          end
        end
      end

      def unsubscribe
        @subscribers.each do |sub|
          ActiveSupport::Notifications.unsubscribe(sub)
        end
      end

      def fmt_controller(payload)
        return if payload[:controller].blank?

        [payload[:controller], payload[:action]].compact.join('#')
      end

      def fmt_params(params)
        params.map { |e| ":#{e}" }.join(", ")
      end
    end
  end
end
