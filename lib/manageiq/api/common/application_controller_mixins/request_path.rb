module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module RequestPath
          class RequestPathError < ::RuntimeError
          end

          def self.included(other)
            other.extend(self::ClassMethods)

            other.before_action(:validate_primary_collection_id)

            other.rescue_from(ManageIQ::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError) do |exception|
              error_document = ManageIQ::API::Common::ErrorDocument.new.add(400, exception.message)
              render :json => error_document.to_h, :status => error_document.status
            end
          end

          def request_path
            request.env["REQUEST_URI"]
          end

          def request_path_parts
            @request_path_parts ||= request_path.match(/\/(?<full_version_string>v\d+.\d+)\/(?<primary_collection_name>\w+)(\/(?<primary_collection_id>[^\/]+)(\/(?<subcollection_name>\w+))?)?/)&.named_captures || {}
          end

          def subcollection?
            !!(request_path_parts["subcollection_name"] && request_path_parts["primary_collection_id"] && request_path_parts["primary_collection_name"])
          end

          private

          def id_regexp
            self.class.send(:id_regexp, request_path_parts["primary_collection_name"])
          end

          def validate_primary_collection_id
            id = request_path_parts["primary_collection_id"]
            return if id.blank?

            raise RequestPathError, "ID is invalid" unless id.match(id_regexp)
          end

          module ClassMethods
            private

            def id_regexp(primary_collection_name)
              @id_regexp ||= begin
                instance_path = "/#{primary_collection_name}/{id}"
                id_parameter  = api_doc.paths.fetch_path(instance_path, "get", "parameters", 0)
                reference     = id_parameter["$ref"]
                id_parameter  = api_doc.parameters[reference.split("parameters/").last] if reference

                id_parameter.fetch_path("schema", "pattern")# || /^\d+$/
              end
            end
          end
        end
      end
    end
  end
end
