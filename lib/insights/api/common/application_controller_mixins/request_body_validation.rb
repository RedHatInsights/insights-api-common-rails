module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module RequestBodyValidation
          class BodyParseError < ::RuntimeError
          end

          def self.included(other)
            ActionController::Parameters.action_on_unpermitted_parameters = :raise

            other.include(OpenapiEnabled)

            other.before_action(:validate_request)
          end

          private

          def body_params
            @body_params ||= ActionController::Parameters.new(parsed_body).permit!
          end

          def parsed_body
            @parsed_body ||= begin
              request_body = request.body.read
              request_body.blank? ? {} : JSON.parse(request_body)
            rescue JSON::ParserError
              raise Insights::API::Common::ApplicationControllerMixins::RequestBodyValidation::BodyParseError, "Failed to parse request body, expected JSON"
            end
          end

          # Validates against openapi.json
          # - only for HTTP POST/PATCH
          def validate_request
            return unless request.post? || request.patch?
            return unless self.class.openapi_enabled

            api_version = self.class.send(:api_version)[1..-1].sub(/x/, ".")

            self.class.send(:api_doc).validate!(
              request.method,
              request.path,
              api_version,
              parsed_body
            )
          end
        end
      end
    end
  end
end
