module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module ExceptionHandling
          DEFAULT_ERROR_CODE = 400

          def self.included(other)
            other.rescue_from(StandardError, RuntimeError) do |exception|
              errors = Insights::API::Common::ErrorDocument.new.tap do |error_document|
                exception_list_from(exception).each do |exc|
                  code = exc.respond_to?(:code) ? exc.code : error_code_from_class(exc)
                  error_document.add(code, "#{exc.class}: #{exc.message}")
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
              ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.to_s]
            else
              DEFAULT_ERROR_CODE
            end
          end
        end
      end
    end
  end
end
