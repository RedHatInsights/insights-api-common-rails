module ManageIQ
  module API
    module Common
      module GraphQL
        module Types
          DateTime = ::GraphQL::ScalarType.define do
            name "DateTime"
            description "An ISO-8601 encoded UTC date string."

            coerce_input ->(value, _ctx) { Time.zone.parse(value) }
          end
        end
      end
    end
  end
end
