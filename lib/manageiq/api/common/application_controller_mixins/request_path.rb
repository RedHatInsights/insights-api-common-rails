module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module RequestPath
          class RequestPathError < ::RuntimeError
          end

          def self.included(other)
            other.rescue_from(ManageIQ::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError) do |exception|
              error_document = ManageIQ::API::Common::ErrorDocument.new.add(400, exception.message)
              render :json => error_document.to_h, :status => error_document.status
            end
          end

          def request_path
            request.env["REQUEST_URI"]
          end

          def request_path_parts
            @request_path_parts ||=
              (request_path.match(/\/(?<full_version_string>v\d+.\d+)\/(?<primary_collection_name>\w+)(\/(?<primary_collection_id>[^\/]+)(\/(?<subcollection_name>\w+))?)?/)&.named_captures || {}).tap do |named_captures|
                id = named_captures["primary_collection_id"].presence
                raise RequestPathError, "ID is invalid" if id && !id.match(/^\d+$/)
              end
          end

          def subcollection?
            !!(request_path_parts["subcollection_name"] && request_path_parts["primary_collection_id"] && request_path_parts["primary_collection_name"])
          end
        end
      end
    end
  end
end
