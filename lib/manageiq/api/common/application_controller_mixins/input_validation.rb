module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module InputValidation
        private
          def body_params
            @body_params ||= begin
              raw_body = request.body.read
              parsed_body = JSON.parse(raw_body)
              ActionController::Parameters.new(parsed_body)
            rescue JSON::ParserError
              raise Sources::Api::BodyParseError
            end
          end

          # Validates against openapi.json
          # - only for HTTP POST/PATCH
          def validate_request
            return unless request.post? || request.patch?

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
