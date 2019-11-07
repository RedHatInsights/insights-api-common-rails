require "more_core_extensions/core_ext/hash"
require "more_core_extensions/core_ext/array"
require "openapi_parser"

module Insights
  module API
    module Common
      module OpenApi
        class Docs
          class DocV3
            attr_reader :content

            def initialize(content)
              spec_version = content["openapi"]
              raise "Unsupported OpenAPI Specification version #{spec_version}" unless spec_version =~ /\A3\..*\z/

              @content = content
            end

            # Validates data types against OpenAPI schema
            #
            # @param http_method [String] POST/PATCH/...
            # @param request_path [String] i.e. /api/sources/v1.0/sources
            # @param api_version [String] i.e. "v1.0", has to be part of **request_path**
            # @param payload [String] JSON if payload_content_type == 'application/json'
            # @param payload_content_type [String]
            #
            # @raise OpenAPIParser::OpenAPIError
            def validate!(http_method, request_path, api_version, payload, payload_content_type = 'application/json')
              path = request_path.split(api_version)[1]
              raise "API version not found in request_path" if path.nil?

              request_operation = validator_doc.request_operation(http_method.to_s.downcase, path)
              request_operation.validate_request_body(payload_content_type, payload)
            end

            def validate_parameters!(http_method, request_path, api_version, params)
              path = request_path.split(api_version)[1]
              raise "API version not found in request_path" if path.nil?

              request_operation = validator_doc.request_operation(http_method.to_s.downcase, path)
              return unless request_operation

              request_operation.validate_request_parameter(params, {})
            end

            def version
              @version ||= Gem::Version.new(content.fetch_path("info", "version"))
            end

            def parameters
              @parameters ||= ::Insights::API::Common::OpenApi::Docs::ComponentCollection.new(self, "components/parameters")
            end

            def schemas
              @schemas ||= ::Insights::API::Common::OpenApi::Docs::ComponentCollection.new(self, "components/schemas")
            end

            def definitions
              schemas
            end

            def example_attributes(key)
              schemas[key]["properties"].each_with_object({}) do |(col, stuff), hash|
                hash[col] = stuff["example"] if stuff.key?("example")
              end
            end

            def base_path
              @base_path ||= @content.fetch_path("servers", 0, "variables", "basePath", "default")
            end

            def paths
              @content["paths"]
            end

            def to_json(options = nil)
              content.to_json(options)
            end

            def routes
              @routes ||= begin
                paths.flat_map do |path, hash|
                  hash.collect do |verb, _details|
                    p = File.join(base_path, path).gsub(/{\w*}/, ":id")
                    {:path => p, :verb => verb.upcase}
                  end
                end
              end
            end

            private

            def validator_doc(opts = { :coerce_value => true, :datetime_coerce_class => DateTime })
              @validator_doc ||= ::OpenAPIParser.parse(content, opts)
            end
          end
        end
      end
    end
  end
end
