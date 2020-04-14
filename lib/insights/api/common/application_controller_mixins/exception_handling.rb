module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module ExceptionHandling
          DEFAULT_ERROR_CODE = 400

          def self.included(other)
            other.rescue_from(StandardError, RuntimeError) do |exception|
              logger.error("#{exception.class.name}: #{exception.message}\n#{exception.backtrace.join("\n")}")
              errors = Insights::API::Common::ErrorDocument.new.tap do |error_document|
                exception_list_from(exception).each do |exc|
                  if api_client_exception?(exc)
                    api_client_errors(exc, error_document)
                  else
                    error_document.add(error_code_from_class(exc).to_s, "#{exc.class}: #{exc.message}")
                  end
                end
              end

              render :json => errors.to_h, :status => error_code_from_class(exception)
            end
          end

          def exception_list_from(exception)
            [].tap do |arr|
              until exception.nil?
                arr << exception
                exception = exception.cause
              end
            end
          end

          def error_code_from_class(exception)
            if ActionDispatch::ExceptionWrapper.rescue_responses.key?(exception.class.to_s)
              Rack::Utils.status_code(ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.to_s])
            else
              DEFAULT_ERROR_CODE
            end
          end

          def api_client_exception?(exc)
            exc.respond_to?(:code) && exc.respond_to?(:response_body) && exc.respond_to?(:response_headers)
          end

          def api_client_errors(exc, error_document)
            body = JSON.parse(exc.response_body)
            if body.key?('errors') && body['errors'].is_a?(Array)
              body['errors'].each do |error|
                next unless error.key?('status') && error.key?('detail')

                error_document.add(error['status'], error['detail'])
              end
            else
              error_document.add(exc.code, exc.message )
            end
          end
        end
      end
    end
  end
end
