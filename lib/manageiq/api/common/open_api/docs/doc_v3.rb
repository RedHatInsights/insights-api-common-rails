require "more_core_extensions/core_ext/hash"
require "more_core_extensions/core_ext/array"


module ManageIQ
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

            def version
              @version ||= Gem::Version.new(content.fetch_path("info", "version"))
            end

            def parameters
              @parameters ||= OpenApi::Docs::ComponentCollection.new(self, "components/parameters")
            end

            def schemas
              @schemas ||= OpenApi::Docs::ComponentCollection.new(self, "components/schemas")
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
          end
        end
      end
    end
  end
end
