require "graphql"
require "graphql/batch"
require "graphql/preload"

require "manageiq/api/common/graphql/association_loader"
require "manageiq/api/common/graphql/associated_records"
require "manageiq/api/common/graphql/generator"
require "manageiq/api/common/graphql/types/big_int"
require "manageiq/api/common/graphql/types/date_time"
require "manageiq/api/common/graphql/types/query_filter"

module ManageIQ
  module API
    module Common
      module GraphQL
        module Api
        end

        def self.version(request)
          /\/?\w+\/v(?<major>\d+)[x\.]?(?<minor>\d+)?\// =~ request.original_url
          [major, minor].compact.join(".")
        end

        def self.openapi_graphql_description
          {
            "summary"     => "Perform a GraphQL Query",
            "operationId" => "postGraphQL",
            "description" => "Performs a GraphQL Query",
            "requestBody" => {
              "content"     => {
                "application/json" => {
                  "schema" => {
                  }
                }
              },
              "description" => "GraphQL Query Request",
              "required"    => true
            },
            "responses"   => {
              "200" => {
                "description" => "GraphQL Query Response",
                "content"     => {
                  "application/json" => {
                    "schema" => {
                      "$ref" => "#/components/schemas/GraphQLResponse"
                    }
                  }
                }
              }
            }
          }
        end

        def self.openapi_graphql_request
          {
            "type"       => "object",
            "properties" => {
              "query"         => {
                "type"        => "string",
                "description" => "The GraphQL query",
                "default"     => "{}"
              },
              "operationName" => {
                "type"        => "string",
                "description" => "If the Query contains several named operations, the operationName controls which one should be executed",
                "default"     => ""
              },
              "variables"     => {
                "type"        => "object",
                "description" => "Optional Query variables",
                "nullable"    => true
              }
            },
            "required"   => [
              "query"
            ]
          }
        end

        def self.openapi_graphql_response
          {
            "type"       => "object",
            "properties" => {
              "data"   => {
                "type"        => "object",
                "description" => "Results from the GraphQL query"
              },
              "errors" => {
                "type"        => "array",
                "description" => "Errors resulting from the GraphQL query",
                "items"       => {
                  "type" => "object"
                }
              }
            }
          }
        end

        def self.search_options(scope, args)
          args[:id] ? scope.where(:id => args[:id]) : scope
        end

        # Following code is auto-generated via rails generate graphql:install
        #
        # Handle form data, JSON body, or a blank value
        def self.ensure_hash(ambiguous_param)
          case ambiguous_param
          when String
            if ambiguous_param.present?
              ensure_hash(JSON.parse(ambiguous_param))
            else
              {}
            end
          when Hash, ActionController::Parameters
            ambiguous_param
          when nil
            {}
          else
            raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
          end
        end
      end
    end
  end
end
