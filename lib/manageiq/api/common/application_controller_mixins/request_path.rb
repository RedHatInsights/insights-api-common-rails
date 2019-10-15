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
          end

          def request_path
            request.env["REQUEST_URI"]
          end

          def request_path_parts
            @request_path_parts ||= begin
              path, _query = request_path.split("?")
              path.match(/\/(?<full_version_string>v\d+.\d+)\/(?<primary_collection_name>\w+)(\/(?<primary_collection_id>[^\/]+)(\/(?<subcollection_name>\w+))?)?/)&.named_captures || {}
            end
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
                id_parameter = id_parameter_from_api_doc(primary_collection_name)
                id_parameter ? id_parameter.fetch_path("schema", "pattern") : /^\d+$/
              end
            end

            def id_parameter_from_api_doc(primary_collection_name)
              # Find the id parameter in the documented route
              id_parameter = api_doc.paths.fetch_path("/#{primary_collection_name}/{id}", "get", "parameters", 0)
              # The route isn't documented, return nil
              return unless id_parameter

              # Return the id parameter or resolve the reference to it and return that
              reference = id_parameter["$ref"]
              return id_parameter unless reference

              api_doc.parameters[reference.split("parameters/").last]
            end
          end
        end
      end
    end
  end
end
