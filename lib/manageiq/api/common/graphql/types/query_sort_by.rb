module ManageIQ
  module API
    module Common
      module GraphQL
        module Types
          QuerySortBy = ::GraphQL::ScalarType.define do
            name "QuerySortBy"
            description "The Query SortBy"

            coerce_input ->(value, _ctx) { JSON.parse(value.to_json) }
          end
        end
      end
    end
  end
end
