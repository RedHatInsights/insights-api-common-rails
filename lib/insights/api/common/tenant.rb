module Insights
  module API
    module Common
      class Tenant
        def initialize(identity)
          @identity = identity["identity"]
        end

        def tenant
          result = identity&.dig("account_number")
          raise IdentityError, "Tenant key doesn't exist" if result.nil?
          result
        end

        private

        attr_reader :identity
      end
    end
  end
end
