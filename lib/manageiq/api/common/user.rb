module ManageIQ
  module API
    module Common
      class User
        attr_reader :identity

        IDENTITY_KEY = 'x-rh-identity'.freeze
        VALID_USER_HEADER_KEYS = %w(account_number user username email is_org_admin)

        def self.with_logged_in_user(user = nil)
          yield Thread.current[:attr_current_user] = new(user)
        ensure
          Thread.current[:attr_current_user] = nil
        end

        def initialize(user = nil)
          @current = user || ManageIQ::API::Common::Headers.current
          user_hash = validate
          @identity = user_hash['identity']
          build_methods
          self
        end

        private

        def decode(key = IDENTITY_KEY)
          raise StandardError, "Requires a valid header or user hash" unless @current
          if @current.is_a?(ActionDispatch::Http::Headers)
            val = @current.instance_variable_get(:@req).stringify_keys
          else
            val = @current.stringify_keys
          end
          JSON.parse(Base64.decode64(val[key]))
        end

        def validate
          check_user(decode)
        end

        def check_user(user)
          identity_list = (user['identity'].keys + user['identity']['user'].keys)
          if user.keys.include?('identity') && user['identity'].keys.include?('user')
            return user if (identity_list & VALID_USER_HEADER_KEYS) == VALID_USER_HEADER_KEYS
          end
          raise StandardError, "Not a valid user header hash"
        end

        def build_methods
          user = flattened_header
          user.keys.each do |key|
            self.class.send(:define_method, :"#{key}") do
              user[key]
            end
          end
        end

        def flattened_header
          user_hash = @identity['user']
          user_hash.merge!(@identity['internal'])['account_number'] = @identity['account_number']
          user_hash
        end
      end
    end
  end
end
