module Insights
  module API
    module Common
      module OpenApi
        class Docs
          class ObjectDefinition < Hash
            def all_attributes
              properties.map { |key, val| all_attributes_recursive(key, val) }
            end

            def read_only_attributes
              properties.select { |k, v| v["readOnly"] == true }.keys
            end

            def required_attributes
              self["required"]
            end

            def properties
              self["properties"]
            end

            private

            def all_attributes_recursive(key, value)
              if value["properties"]
                {
                  key => value["properties"].map { |k, v| all_attributes_recursive(k, v) }
                }
              else
                key
              end
            end
          end
        end
      end
    end
  end
end
