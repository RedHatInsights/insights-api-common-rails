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

          def self.graphql_schema_file
            Rails.root.join("lib", "api", "graphql.rb").to_s
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

          def self.init_schema
            api_version = ManageIQ::API::GraphQL.version
            openapi_content = Api::Docs[api_version].content

puts "AHA:  api_version = #{api_version}"

            graphql_model_types = ""

            resources = openapi_content["paths"].keys.sort
            collections = []
            resources.each do |resource|
              next unless openapi_content.dig("paths", resource, "get") # we only care for queries

              rmatch = resource.match("^/(.*)/{id}$")
              next unless rmatch

              collection = rmatch[1]
              klass_name = collection.camelize.singularize
              this_schema = openapi_content.dig(*path_parts(SCHEMAS_PATH), klass_name)
              next if this_schema["type"] != "object" || this_schema["properties"].nil?

              graphql_model_types << "\n" unless collections.empty?

              collections << collection

              model_properties = []
              properties = this_schema["properties"]
              properties.keys.sort.each do |property_name|
                property_schema = properties[property_name]
                property_schema = openapi_content.dig(*path_parts(property_schema["$ref"])) if property_schema["$ref"]
                property_format = property_schema["format"] || ""
                property_type   = property_schema["type"]
                description     = property_schema["description"]

                property_graphql_type = graphql_type(property_name, property_format, property_type)
                model_properties << [property_name, property_graphql_type, description] if property_graphql_type
              end

              model_is_associated, model_associations = resource_associations(openapi_content, collection)
              graphql_model_types << ERB.new(template("model_type"), nil, '<>').result(binding)
            end
            graphql_query_type = ERB.new(template("query_type"), nil, '<>').result(binding)
            graphql_schema = ERB.new(template("graphql"), nil, '<>').result(binding)
            File.write(graphql_schema_file, graphql_schema)
          end
        end
      end
    end
  end
end
