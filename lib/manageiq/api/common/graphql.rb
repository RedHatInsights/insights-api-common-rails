require "manageiq/api/common/graphql/generator"

require "manageiq/api/common/graphql/types/big_int"
require "manageiq/api/common/graphql/types/date_time"
require "manageiq/api/common/graphql/types/query_filter"

module ManageIQ
  module API
    module Common
      module GraphQL
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
