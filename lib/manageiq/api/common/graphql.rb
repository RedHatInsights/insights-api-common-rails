require "graphql"
require "graphql/batch"
require "graphql/preload"

require "manageiq/api/common/graphql/generator"

require "manageiq/api/common/graphql/types/big_int"
require "manageiq/api/common/graphql/types/date_time"
require "manageiq/api/common/graphql/types/query_filter"

module ManageIQ
  module API
    module Common
      module GraphQL
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
                    "type" => "object"
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
                      "type" => "object"
                    }
                  }
                }
              }
            }
          }
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
