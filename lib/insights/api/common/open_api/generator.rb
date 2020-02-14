module Insights
  module API
    module Common
      module OpenApi
        class Generator
          require 'json'
          require 'insights/api/common/graphql'

          PARAMETERS_PATH = "/components/parameters".freeze
          SCHEMAS_PATH = "/components/schemas".freeze

          def path_parts(openapi_path)
            openapi_path.split("/")[1..-1]
          end

          # Let's get the latest api version based on the openapi.json routes
          def api_version
            @api_version ||= Rails.application.routes.routes.each_with_object([]) do |route, array|
              matches = ActionDispatch::Routing::RouteWrapper
                        .new(route)
                        .path.match(/\A.*\/v(\d+.\d+)\/openapi.json.*\z/)
              array << matches[1] if matches
            end.max
          end

          def rails_routes
            Rails.application.routes.routes.each_with_object([]) do |route, array|
              r = ActionDispatch::Routing::RouteWrapper.new(route)
              next if r.internal? # Don't display rails routes
              next if r.engine? # Don't care right now...

              array << r
            end
          end

          def openapi_file
            @openapi_file ||= Rails.root.join("public", "doc", "openapi-3-v#{api_version}.json").to_s
          end

          def openapi_contents
            @openapi_contents ||= begin
              JSON.parse(File.read(openapi_file))
            end
          end

          def initialize
            app_prefix, app_name = server_base_path.match(/\A(.*)\/(.*)\/v\d+.\d+\z/).captures
            ENV['APP_NAME'] = app_name
            ENV['PATH_PREFIX'] = app_prefix
            Rails.application.reload_routes!
          end

          def server_base_path
            openapi_contents["servers"].first["variables"]["basePath"]["default"]
          end

          def applicable_rails_routes
            rails_routes.select { |i| i.path.start_with?(server_base_path) }
          end

          def schemas
            @schemas ||= {
              "CollectionLinks"    => {
                "type"       => "object",
                "properties" => {
                  "first" => {
                    "type" => "string"
                  },
                  "last"  => {
                    "type" => "string"
                  },
                  "next"  => {
                    "type" => "string"
                  },
                  "prev"  => {
                    "type" => "string"
                  },
                }
              },
              "CollectionMetadata" => {
                "type"       => "object",
                "properties" => {
                  "count"  => {
                    "type" => "integer"
                  },
                  "limit"  => {
                    "type" => "integer"
                  },
                  "offset" => {
                    "type" => "integer"
                  }
                }
              },
              "ID"                 => {
                "type"        => "string",
                "description" => "ID of the resource",
                "pattern"     => "^\\d+$",
                "readOnly"    => true,
              },
              "SortByAttribute"    => {
                "type"        => "string",
                "description" => "Attribute with optional order to sort the result set by.",
                "pattern"     => "^[a-z\\-_]+(:asc|:desc)?$"
              }
            }
          end

          def build_schema(klass_name)
            schemas[klass_name] = openapi_schema(klass_name)
            "##{SCHEMAS_PATH}/#{klass_name}"
          end

          def build_schema_error_not_found
            klass_name = "ErrorNotFound"

            schemas[klass_name] = {
              "type"       => "object",
              "properties" => {
                "errors"  => {
                  "type"  => "array",
                  "items" => {
                    "type"        => "object",
                    "properties"  => {
                      "status"    => {
                        "type"    => "integer",
                        "example" => 404
                      },
                      "detail"    => {
                        "type"    => "string",
                        "example" => "Record not found"
                      }
                    }
                  }
                }
              }
            }

            "##{SCHEMAS_PATH}/#{klass_name}"
          end

          def parameters
            @parameters ||= {
              "QueryFilter" => {
                "in"          => "query",
                "name"        => "filter",
                "description" => "Filter for querying collections.",
                "required"    => false,
                "style"       => "deepObject",
                "explode"     => true,
                "schema"      => {
                  "type" => "object"
                }
              },
              "QueryLimit"  => {
                "in"          => "query",
                "name"        => "limit",
                "description" => "The numbers of items to return per page.",
                "required"    => false,
                "schema"      => {
                  "type"    => "integer",
                  "minimum" => 1,
                  "maximum" => 1000,
                  "default" => 100
                }
              },
              "QueryOffset" => {
                "in"          => "query",
                "name"        => "offset",
                "description" => "The number of items to skip before starting to collect the result set.",
                "required"    => false,
                "schema"      => {
                  "type"    => "integer",
                  "minimum" => 0,
                  "default" => 0
                }
              },
              "QuerySortBy" => {
                "in"          => "query",
                "name"        => "sort_by",
                "description" => "The list of attribute and order to sort the result set by.",
                "required"    => false,
                "schema"      => {
                  "oneOf" => [
                    { "$ref" => "##{SCHEMAS_PATH}/SortByAttribute" },
                    { "type" => "array", "items" => { "$ref" => "##{SCHEMAS_PATH}/SortByAttribute" } }
                  ]
                }
              }
            }
          end

          def build_parameter(name, value = nil)
            parameters[name] = value
            "##{PARAMETERS_PATH}/#{name}"
          end

          def openapi_schema(klass_name)
            {
              "type"                 => "object",
              "properties"           => openapi_schema_properties(klass_name),
              "additionalProperties" => false
            }
          end

          def openapi_list_description(klass_name, primary_collection)
            sub_collection = (primary_collection != klass_name)
            {
              "summary"     => "List #{klass_name.pluralize}#{" for #{primary_collection}" if sub_collection}",
              "operationId" => "list#{primary_collection if sub_collection}#{klass_name.pluralize}",
              "description" => "Returns an array of #{klass_name} objects",
              "parameters"  => [
                { "$ref" => "##{PARAMETERS_PATH}/QueryLimit"  },
                { "$ref" => "##{PARAMETERS_PATH}/QueryOffset" },
                { "$ref" => "##{PARAMETERS_PATH}/QueryFilter" },
                { "$ref" => "##{PARAMETERS_PATH}/QuerySortBy" }
              ],
              "responses"   => {
                "200" => {
                  "description" => "#{klass_name.pluralize} collection",
                  "content"     => {
                    "application/json" => {
                      "schema" => { "$ref" => build_collection_schema(klass_name) }
                    }
                  }
                }
              }
            }.tap do |h|
              h["parameters"] << { "$ref" => build_parameter("ID") } if sub_collection

              next unless sub_collection

              h["responses"]["404"] = {
                "description" => "Not found",
                "content"     => {
                  "application/json" => {
                    "schema"         => { "$ref" => build_schema_error_not_found }
                  }
                }
              }
            end
          end

          def build_collection_schema(klass_name)
            collection_name = "#{klass_name.pluralize}Collection"
            schemas[collection_name] = {
              "type"       => "object",
              "properties" => {
                "meta"  => { "$ref" => "##{SCHEMAS_PATH}/CollectionMetadata" },
                "links" => { "$ref" => "##{SCHEMAS_PATH}/CollectionLinks"    },
                "data"  => {
                  "type"  => "array",
                  "items" => { "$ref" => build_schema(klass_name) }
                }
              }
            }

            "##{SCHEMAS_PATH}/#{collection_name}"
          end

          def openapi_show_description(klass_name)
            {
              "summary"     => "Show an existing #{klass_name}",
              "operationId" => "show#{klass_name}",
              "description" => "Returns a #{klass_name} object",
              "parameters"  => [{ "$ref" => build_parameter("ID") }],
              "responses"   => {
                "200" => {
                  "description" => "#{klass_name} info",
                  "content"     => {
                    "application/json" => {
                      "schema" => { "$ref" => build_schema(klass_name) }
                    }
                  }
                },
                "404" => {
                  "description" => "Not found",
                  "content"     => {
                    "application/json" => {
                      "schema"         => { "$ref" => build_schema_error_not_found }
                    }
                  }
                }
              }
            }
          end

          def openapi_destroy_description(klass_name)
            {
              "summary"     => "Delete an existing #{klass_name}",
              "operationId" => "delete#{klass_name}",
              "description" => "Deletes a #{klass_name} object",
              "parameters"  => [{ "$ref" => build_parameter("ID") }],
              "responses"   => {
                "204" => { "description" => "#{klass_name} deleted" },
                "404" => {
                  "description" => "Not found",
                  "content"     => {
                    "application/json" => {
                      "schema"         => { "$ref" => build_schema_error_not_found }
                    }
                  }
                }
              }
            }
          end

          def openapi_tag_description(klass_name)
            {
              "summary"     => "Tag a #{klass_name}",
              "operationId" => "tag#{klass_name}",
              "description" => "Tags a #{klass_name} object",
              "parameters"  => [
                { "$ref" => build_parameter("ID") }
              ],
              "requestBody" => request_body("Tag", "add", :single => false),
              "responses"   => {
                "201" => {
                  "description" => "#{klass_name} tagged successful",
                  "content"     => {
                    "application/json" => {
                      "schema" => {
                        "type"  => "array",
                        "items" => {
                          "$ref" => build_schema("Tag")
                        }
                      }
                    }
                  }
                },
                "304" => {
                  "description" => "Not modified"
                }
              }
            }
          end

          def openapi_untag_description(klass_name)
            {
              "summary"     => "Untag a #{klass_name}",
              "operationId" => "untag#{klass_name}",
              "description" => "Untags a #{klass_name} object",
              "parameters"  => [
                { "$ref" => build_parameter("ID") }
              ],
              "requestBody" => request_body("Tag", "removed", :single => false),
              "responses"   => {
                "204" => {
                  "description" => "#{klass_name} untagged successfully",
                }
              }
            }
          end

          def openapi_create_description(klass_name)
            {
              "summary"     => "Create a new #{klass_name}",
              "operationId" => "create#{klass_name}",
              "description" => "Creates a #{klass_name} object",
              "requestBody" => request_body(klass_name, "create"),
              "responses"   => {
                "201" => {
                  "description" => "#{klass_name} creation successful",
                  "content"     => {
                    "application/json" => {
                      "schema" => { "$ref" => build_schema(klass_name) }
                    }
                  }
                }
              }
            }
          end

          def request_body(klass_name, action, single: true)
            schema = single ? { "$ref" => build_schema(klass_name) } : {"type" => "array", "items" => {"$ref" => build_schema(klass_name)}}

            {
              "content"     => {
                "application/json" => {
                  "schema" => schema
                }
              },
              "description" => "#{klass_name} attributes to #{action}",
              "required"    => true
            }
          end

          def openapi_update_description(klass_name, verb)
            action = verb == "patch" ? "Update" : "Replace"
            {
              "summary"     => "#{action} an existing #{klass_name}",
              "operationId" => "#{action.downcase}#{klass_name}",
              "description" => "#{action}s a #{klass_name} object",
              "parameters"  => [
                { "$ref" => build_parameter("ID") }
              ],
              "requestBody" => request_body(klass_name, "update"),
              "responses"   => {
                "204" => { "description" => "Updated, no content" },
                "400" => { "description" => "Bad request"         },
                "404" => {
                  "description" => "Not found",
                  "content"     => {
                    "application/json" => {
                      "schema"         => { "$ref" => build_schema_error_not_found }
                    }
                  }
                }
              }
            }
          end

          def openapi_schema_properties_value(klass_name, model, key, value)
            if key == model.primary_key
              {
                "$ref" => "##{SCHEMAS_PATH}/ID"
              }
            elsif key.ends_with?("_id")
              properties_value = {}
              properties_value["$ref"] = if generator_read_only_definitions.include?(klass_name)
                                           # Everything under providers data is read only for now
                                           "##{SCHEMAS_PATH}/ID"
                                         else
                                           openapi_contents.dig(*path_parts(SCHEMAS_PATH), klass_name, "properties", key, "$ref") || "##{SCHEMAS_PATH}/ID"
                                         end
              properties_value
            else
              properties_value = {
                "type" => "string"
              }

              case value.sql_type_metadata.type
              when :datetime
                properties_value["format"] = "date-time"
              when :integer
                properties_value["type"] = "integer"
              when :float
                properties_value["type"] = "number"
              when :boolean
                properties_value["type"] = "boolean"
              when :jsonb
                properties_value["type"] = "object"
                ['type', 'items', 'properties', 'additionalProperties'].each do |property_key|
                  prop = openapi_contents.dig(*path_parts(SCHEMAS_PATH), klass_name, "properties", key, property_key)
                  properties_value[property_key] = prop unless prop.nil?
                end
              end

              # Take existing attrs, that we won't generate
              ['example', 'format', 'readOnly', 'title', 'description'].each do |property_key|
                property_value                 = openapi_contents.dig(*path_parts(SCHEMAS_PATH), klass_name, "properties", key, property_key)
                properties_value[property_key] = property_value if property_value
              end

              if generator_read_only_definitions.include?(klass_name) || generator_read_only_attributes.include?(key.to_sym)
                # Everything under providers data is read only for now
                properties_value['readOnly'] = true
              end

              properties_value.sort.to_h
            end
          end

          def run(graphql = false)
            new_content = openapi_contents.dup
            new_content["paths"] = build_paths.sort.to_h
            new_content["components"] ||= {}
            new_content["components"]["schemas"]    = schemas.merge(schema_overrides).sort.each_with_object({}) { |(name, val), h| h[name] = val || openapi_contents["components"]["schemas"][name] || {} }
            new_content["components"]["parameters"] = parameters.sort.each_with_object({}) { |(name, val), h| h[name] = val || openapi_contents["components"]["parameters"][name] || {} }
            File.write(openapi_file, JSON.pretty_generate(new_content) + "\n")
            Insights::API::Common::GraphQL::Generator.generate(api_version, new_content) if graphql
          end

          def openapi_schema_properties(klass_name)
            model = klass_name.constantize
            model.columns_hash.map do |key, value|
              unless (generator_blacklist_allowed_attributes[key.to_sym] || []).include?(klass_name)
                next if generator_blacklist_attributes.include?(key.to_sym)
              end

              if generator_blacklist_substitute_attributes.include?(key.to_sym)
                generator_blacklist_substitute_attributes[key.to_sym]
              else
                [key, openapi_schema_properties_value(klass_name, model, key, value)]
              end
            end.compact.sort.to_h
          rescue NameError
            openapi_contents["components"]["schemas"][klass_name]["properties"]
          end

          def generator_blacklist_attributes
            @generator_blacklist_attributes ||= [
              :resource_timestamp,
              :resource_timestamps,
              :resource_timestamps_max,
              :tenant_id,
            ].to_set.freeze
          end

          def generator_blacklist_allowed_attributes
            @generator_blacklist_allowed_attributes ||= {}
          end

          def generator_blacklist_substitute_attributes
            @generator_blacklist_substitute_attributes ||= {}
          end

          def generator_read_only_attributes
            @generator_read_only_attributes ||= [
              :archived_at,
              :created_at,
              :last_seen_at,
              :updated_at,
            ].to_set.freeze
          end

          def generator_read_only_definitions
            @generator_read_only_definitions ||= [].to_set.freeze
          end

          def build_paths
            applicable_rails_routes.each_with_object({}) do |route, expected_paths|
              without_format     = route.path.split("(.:format)").first
              sub_path           = without_format.split(server_base_path).last.sub(/:[_a-z]*id/, "{id}")
              route_destination  = route.controller.split("/").last.camelize
              controller         = "Api::V#{api_version.sub(".", "x")}::#{route_destination}Controller".safe_constantize
              klass_name         = controller.try(:presentation_name) || route_destination.singularize
              verb               = route.verb.downcase
              primary_collection = sub_path.split("/")[1].camelize.singularize

              expected_paths[sub_path] ||= {}
              expected_paths[sub_path][verb] =
                case route.action
                when "index"   then openapi_list_description(klass_name, primary_collection)
                when "show"    then openapi_show_description(klass_name)
                when "destroy" then openapi_destroy_description(klass_name)
                when "create"  then openapi_create_description(klass_name)
                when "update"  then openapi_update_description(klass_name, verb)
                when "tag"     then openapi_tag_description(primary_collection)
                when "untag"   then openapi_untag_description(primary_collection)
                else handle_custom_route_action(route.action.camelize, verb, primary_collection)
                end

              next if expected_paths[sub_path][verb]

              # If it's not generic action but a custom method like e.g. `post "order", :to => "service_plans#order"`, we will
              # try to take existing schema, because the description, summary, etc. are likely to be custom.
              expected_paths[sub_path][verb] =
                case verb
                when "post"
                  if sub_path == "/graphql" && route.action == "query"
                    schemas["GraphQLRequest"]  = ::Insights::API::Common::GraphQL.openapi_graphql_request
                    schemas["GraphQLResponse"] = ::Insights::API::Common::GraphQL.openapi_graphql_response
                    ::Insights::API::Common::GraphQL.openapi_graphql_description
                  else
                    openapi_contents.dig("paths", sub_path, verb) || openapi_create_description(klass_name)
                  end
                when "get"
                  openapi_contents.dig("paths", sub_path, verb) || openapi_show_description(klass_name)
                else
                  openapi_contents.dig("paths", sub_path, verb)
                end
            end
          end

          def handle_custom_route_action(_route_action, _verb, _primary_collection)
          end

          def schema_overrides
            {}
          end
        end
      end
    end
  end
end
