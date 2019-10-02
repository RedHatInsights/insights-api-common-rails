module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module ExceptionHandling
          DEFAULT_ERROR_CODE = 400

          def self.included(other)
            other.rescue_from(StandardError, RuntimeError) do |exception|
              errors, status = collected_errors(exception)

              render :json => errors, :status => status
            end
          end

          def collected_errors(exception)
            errors = []
            top_level_exception = exception

            until exception.nil?
              code = exception.respond_to?(:code) ? exception.code : error_code_from_class(exception)
              errors << {:status => code, :detail => "#{exception.class}: #{exception.message}"}
              exception = exception.cause
            end

            # Overwrite the first error since that one most likely doen't have a code
            errors.first[:status] = error_code_from_class(top_level_exception)

            [{:errors => errors}, error_code_from_class(top_level_exception)]
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
