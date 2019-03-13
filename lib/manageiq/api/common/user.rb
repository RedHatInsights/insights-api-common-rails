module ManageIQ
  module API
    module Common
      class IdentityError < StandardError; end

      class User
        def initialize(identity)
          @identity = identity
        end

        %w[
          username
          email
          first_name
          is_active
          is_org_admin
          is_internal
          last_name
          locale
        ].each do |m|
          define_method(m.start_with?("is_") ? "#{m[3..-1]}?" : m) do
            find_user_key(m)
          end
        end

        def tenant
          find_tenant_key
        end

        private

        attr_reader :identity

        def find_user_key(key)
          result = identity.dig('identity', 'user', key.to_s)
          raise IdentityError, "#{key} doesn't exist" if result.nil?
          result
        end

        def find_tenant_key
          result = identity.dig('identity', 'account_number')
          raise IdentityError, "Tenant key doesn't exist" if result.nil?
          result
        end
      end
    end
  end
end
