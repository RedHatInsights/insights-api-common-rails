module ManageIQ
  module API
    module Common
      class User
        IDENTITY_KEY = 'x-rh-identity'.freeze

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

        def decode
          hashed = Request.current!.to_h
          user_hash = hashed[:headers][IDENTITY_KEY]
          JSON.parse(Base64.decode64(user_hash))
        end

        def find_user_key(key)
          result = decode.dig('identity', 'user', key.to_s)
          raise ManageIQ::API::Common::HeaderIdentityError, "#{key} doesn't exist" if result.nil?
          result
        end

        def find_tenant_key
          result = decode.dig('identity', 'account_number')
          raise ManageIQ::API::Common::HeaderIdentityError, "Tenant key doesn't exist" if result.nil?
          result
        end
      end
    end
  end
end
