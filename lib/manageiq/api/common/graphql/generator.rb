require "erb"

module ManageIQ
  module API
    module Common
      module GraphQL
        module Generator
          PARAMETERS_PATH = "/components/parameters".freeze
          SCHEMAS_PATH = "/components/schemas".freeze

          def self.path_parts(openapi_path)
            openapi_path.split("/")[1..-1]
          end

          def self.template(type)
            File.read(Pathname.new(__dir__).join(File.expand_path("templates", __dir__), "#{type}.erb").to_s)
          end

          def self.graphql_type(property_name, property_format, property_type)
            return "!types.ID" if property_name == "id"

            case property_type
            when "string"
              property_format == "date-time" ? "::ManageIQ::API::Common::GraphQL::Types::DateTime" : "types.String"
            when "number"
              "types.Float"
            when "boolean"
              "types.Boolean"
            when "integer"
              "::ManageIQ::API::Common::GraphQL::Types::BigInt"
            end
          end

          def self.resource_associations(openapi_content, collection)
            collection_is_associated = openapi_content["paths"].keys.any? do |path|
              path.match("^/[^/]*/{id}/#{collection}$") &&
                openapi_content.dig("paths", path, "get")
            end
            collection_associations = []
            openapi_content["paths"].keys.each do |path|
              subcollection_match = path.match("^/#{collection}/{id}/([^/]*)$")
              next unless subcollection_match

              subcollection = subcollection_match[1]
              next unless openapi_content.dig("paths", "/#{subcollection}/{id}", "get")

              collection_associations << subcollection
            end
            [collection_is_associated ? true : false, collection_associations.sort]
          end

          def self.collection_field_resolvers(schema_overlay, collection)
            field_resolvers = {}
            schema_overlay.keys.each do |collection_regex|
              next unless collection.match(collection_regex)

              field_resolvers.merge!(schema_overlay.fetch_path(collection_regex, "field_resolvers") || {})
            end
            field_resolvers
          end

          def self.init_schema(request, schema_overlay = {})
            api_version       = GraphQL.version(request)
            version_namespace = "V#{api_version.tr('.', 'x')}"
            openapi_content   = ::ManageIQ::API::Common::OpenApi::Docs.instance[api_version].content

            api_namespace = if ::Api.const_defined?(version_namespace, false)
                              ::Api.const_get(version_namespace)
                            else
                              ::Api.const_set(version_namespace, Module.new)
                            end

            graphql_namespace = if api_namespace.const_defined?("GraphQL", false)
                                  api_namespace.const_get("GraphQL")
                                else
                                  api_namespace.const_set("GraphQL", Module.new)
                                end

            return graphql_namespace.const_get("Schema") if graphql_namespace.const_defined?("Schema", false)

            resources = openapi_content["paths"].keys.sort
            collections = []
            resources.each do |resource|
              next unless openapi_content.dig("paths", resource, "get") # we only care for queries

              rmatch = resource.match("^/(.*/)?([^/]*)/{id}$")
              next unless rmatch

              collection = rmatch[2]
              klass_name = collection.camelize.singularize
              this_schema = openapi_content.dig(*path_parts(SCHEMAS_PATH), klass_name)
              next if this_schema["type"] != "object" || this_schema["properties"].nil?

              collections << collection

              model_class = klass_name.constantize
              model_encrypted_columns_set = (model_class.try(:encrypted_columns) || []).to_set

              model_properties = []
              properties = this_schema["properties"]
              properties.keys.sort.each do |property_name|
                next if model_encrypted_columns_set.include?(property_name)

                property_schema = properties[property_name]
                property_schema = openapi_content.dig(*path_parts(property_schema["$ref"])) if property_schema["$ref"]
                property_format = property_schema["format"] || ""
                property_type   = property_schema["type"]
                description     = property_schema["description"]

                property_graphql_type = graphql_type(property_name, property_format, property_type)
                model_properties << [property_name, property_graphql_type, description] if property_graphql_type
              end

              field_resolvers = collection_field_resolvers(schema_overlay, klass_name)
              model_is_associated, model_associations = resource_associations(openapi_content, collection)

              graphql_model_type_template = ERB.new(template("model_type"), nil, '<>').result(binding)
              graphql_namespace.module_eval(graphql_model_type_template)
            end

            graphql_query_type_template = ERB.new(template("query_type"), nil, '<>').result(binding)
            graphql_namespace.module_eval(graphql_query_type_template)

            graphql_schema_template = ERB.new(template("schema"), nil, '<>').result(binding)
            graphql_namespace.module_eval(graphql_schema_template)
            graphql_namespace.const_get("Schema")
          end
        end
      end
    end
  end
end
