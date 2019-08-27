module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module RequestPath
          def request_path
            request.env["REQUEST_URI"]
          end

          def request_path_parts
            @request_path_parts ||= request_path.match(/\/(?<full_version_string>v\d+.\d+)\/(?<primary_collection_name>\w+)(\/(?<primary_collection_id>[^\/]+)(\/(?<subcollection_name>\w+))?)?/)&.named_captures || {}
          end

          def subcollection?
            !!(request_path_parts["subcollection_name"] && request_path_parts["primary_collection_id"] && request_path_parts["primary_collection_name"])
          end
        end
      end
    end
  end
end
