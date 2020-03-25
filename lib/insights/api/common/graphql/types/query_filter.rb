module Insights
  module API
    module Common
      module GraphQL
        module Types
          QueryFilter = ::GraphQL::ScalarType.define do
            name "QueryFilter"
            description "The Query Filter"

            coerce_input ->(value, _ctx) { JSON.parse(value.to_json) }
          end
        end
      end
    end
  end
end
