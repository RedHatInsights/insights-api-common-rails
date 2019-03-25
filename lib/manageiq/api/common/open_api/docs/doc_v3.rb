module OpenApi
  class Docs
    class DocV3
      attr_reader :content

      def initialize(content)
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
        @base_path ||= @content["servers"].first["variables"]["basePath"]["default"]
      end

      def paths
        @content["paths"]
      end

      def routes
        @routes ||= Docs.path_routes(base_path, paths)
      end
    end
  end
end
