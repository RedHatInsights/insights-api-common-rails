module OpenApi
  class Docs
    class ObjectDefinition < Hash
      def all_attributes
        self["properties"].keys
      end

      def required_attributes
        self["required"]
      end
    end
  end
end
