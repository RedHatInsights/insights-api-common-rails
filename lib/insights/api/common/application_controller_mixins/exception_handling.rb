module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module ExceptionHandling
          DEFAULT_ERROR_CODE = 400
          PUNDIT_UNAUTHORIZED_ERROR = "Pundit::NotAuthorizedError".freeze

          def self.included(other)
            other.rescue_from(StandardError, RuntimeError) do |exception|
              rescue_from_handler(exception) do |error_document, exc|
                error_document.add(error_code_from_class(exc).to_s, "#{exc.class}: #{exc.message}")
              end
            end
          end

          def rescue_from_handler(exception)
            logger.error("#{exception.class.name}: #{exception.message}\n#{exception.backtrace.join("\n")}")
            errors = Insights::API::Common::ErrorDocument.new.tap do |error_document|
              exception_list_from(exception).each do |exc|
                if api_client_exception?(exc)
                  api_client_errors(exc, error_document)
                elsif pundit_exception?(exc)
                  message = "You are not authorized to #{exc.query.delete_suffix('?')} this #{exc.record.model_name.human.downcase}"
                  error_document.add(error_code_from_class(exc).to_s, message)
                else
                  yield error_document, exc
                end
              end
            end

            render :json => errors.to_h, :status => error_code_from_class(exception)
          end

          def exception_list_from(exception)
            [].tap do |arr|
              until exception.nil?
                arr << exception
                exception = exception.cause
              end
            end
          end

          def pundit_exception?(exception)
            exception.class.to_s == PUNDIT_UNAUTHORIZED_ERROR
          end

          def error_code_from_class(exception)
            if ActionDispatch::ExceptionWrapper.rescue_responses.key?(exception.class.to_s)
              Rack::Utils.status_code(ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.to_s])
            else
              DEFAULT_ERROR_CODE
            end
          end

          def api_client_exception?(exc)
            exc.respond_to?(:code) && exc.respond_to?(:response_body) && exc.respond_to?(:response_headers) &&
              !exc.response_body.nil?
          end

          def api_client_errors(exc, error_document)
            body = JSON.parse(exc.response_body)
            if body.is_a?(Hash) && body.key?('errors') && body['errors'].is_a?(Array)
              body['errors'].each do |error|
                next unless error.key?('status') && error.key?('detail')

                error_document.add(error['status'], error['detail'])
              end
            else
              error_document.add(exc.code.to_s, exc.message )
            end
          end
        end
      end
    end
  end
end
