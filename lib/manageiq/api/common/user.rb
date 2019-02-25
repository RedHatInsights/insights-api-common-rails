module ManageIQ
  module API
    module Common
      class User
        IDENTITY_KEY = 'x-rh-identity'.freeze

        def self.raw_current=(raw_current)
          Thread.current[:attr_raw_current] = raw_current
        end

        def self.raw_current
          Thread.current[:attr_raw_current]
        end

        def self.current
          raise "Current User has not been set" unless Thread.current[:attr_current_user]
          Thread.current[:attr_current_user]
        end

        def self.current=(user)
          raise StandardError, "Must be a ManageIQ::API::Common::User" unless user.is_a?(ManageIQ::API::Common::User)
          Thread.current[:attr_current_user] = user
        end

        def self.from_header(raw_header)
          self.raw_current = raw_header
          raw_header.nil? ? Thread.current[:attr_current_user] = nil : self.current = new(raw_current)
        end

        def self.with_logged_in_user(user_header)
          self.from_header(user_header)
          yield self.current
        ensure
          Thread.current[:attr_current_user] = nil
        end

        def initialize(user_header)
          raise StandardError, "Must pass in a valid Header or User Hash"  unless user_header.present?
          @user = user_header
        end

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
          result = decode.dig('identity','account_number')
          raise StandardError "Tenant key doesn't exist" if result.nil?
          result
        end

        private

        def decode
          if @user.is_a?(ActionDispatch::Http::Headers)
            val = @user.instance_variable_get(:@req).stringify_keys
          else
            val = @user.stringify_keys
          end
          JSON.parse(Base64.decode64(val[IDENTITY_KEY]))
        rescue NoMethodError => e
          raise ArgumentError, "Not a valid user hash: #{e.message}"
        end

        def validate_and_return(key)
          find_user_key(decode, key)
        end

        def find_user_key(hash, key)
          result = hash.dig('identity', 'user', key.to_s)
          raise StandardError "#{key} doesn't exist" if result.nil?
          result
        end
      end
    end
  end
end
