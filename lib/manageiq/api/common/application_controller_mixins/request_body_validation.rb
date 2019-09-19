module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module RequestBodyValidation
          class BodyParseError < ::RuntimeError
          end

          def self.included(other)
            ActionController::Parameters.action_on_unpermitted_parameters = :raise

            other.before_action(:validate_request)

            other.rescue_from(ActionController::UnpermittedParameters) do |exception|
              error_document = ManageIQ::API::Common::ErrorDocument.new.add(400, exception.message)
              render :json => error_document.to_h, :status => error_document.status
            end

            other.rescue_from(ManageIQ::API::Common::ApplicationControllerMixins::RequestBodyValidation::BodyParseError) do |_exception|
              error_document = ManageIQ::API::Common::ErrorDocument.new.add(400, "Failed to parse request body, expected JSON")
              render :json => error_document.to_h, :status => error_document.status
            end
          end

          private

          def body_params
            @body_params ||= begin
              raw_body    = request.body.read
              parsed_body = JSON.parse(raw_body)
              ActionController::Parameters.new(parsed_body).permit!
            rescue JSON::ParserError
              raise ManageIQ::API::Common::ApplicationControllerMixins::RequestBodyValidation::BodyParseError
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
              body_params.as_json
            )
          rescue OpenAPIParser::OpenAPIError => exception
            error_document = ManageIQ::API::Common::ErrorDocument.new.add(400, exception.message)
            render :json => error_document.to_h, :status => :bad_request
          end
        end
      end
    end
  end
end
