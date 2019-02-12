module ManageIQ
  module API
    module Common
      class User
        IDENTITY_KEY = 'x-rh-identity'.freeze

        def self.current
          Thread.current[:attr_current_user]
        end

        def self.current=(user_header)
          Thread.current[:attr_current_user] = new(user_header)
        end

        def self.with_logged_in_user(user_header)
          alternate_user = new(user_header)
          yield alternate_user
        ensure
          alternate_user = nil
        end

        def initialize(user_header)
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
          decoded_hash = decode
          raise StandardError "#{key} doesn't exist" unless decoded_hash['identity']['user'].has_key?(key.to_s)
          decoded_hash['identity']['user'][key.to_s]
        end
      end
    end
  end
end
