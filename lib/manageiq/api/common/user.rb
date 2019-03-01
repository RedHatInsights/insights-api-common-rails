module ManageIQ
  module API
    module Common
      class User
        IDENTITY_KEY = 'x-rh-identity'.freeze

        def username
          validate_and_return(__method__)
        end

        def email
          validate_and_return(__method__)
        end

        def first_name
          validate_and_return(__method__)
        end

        def last_name
          validate_and_return(__method__)
        end

        def is_active?
          validate_and_return(:is_active)
        end

        def is_org_admin?
          validate_and_return(:is_org_admin)
        end

        def is_internal?
          validate_and_return(:is_internal)
        end

        def locale
          validate_and_return(__method__)
        end

        def tenant
          find_tenant_key
        end

        private

        def decode
          hashed = ManageIQ::API::Common::Request.current.to_h
          user_hash = hashed[:headers][IDENTITY_KEY]
          JSON.parse(Base64.decode64(user_hash))
        end

        def validate_and_return(key)
          find_user_key(decode, key)
        end

        def find_user_key(hash, key)
          result = hash.dig('identity', 'user', key.to_s)
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
