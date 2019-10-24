module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module RequestParameterValidation
          def self.included(other)
            other.include(OpenapiEnabled)

            other.before_action(:validate_request_parameters)
          end

          private

          def validate_request_parameters
            api_version = self.class.send(:api_version)[1..-1].sub(/x/, ".")

            self.class.send(:api_doc).try(
              :validate_parameters!,
              request.method,
              request.path,
              api_version,
              params.slice(:sort_by)
            )
          end
        end
      end
    end
  end
end
