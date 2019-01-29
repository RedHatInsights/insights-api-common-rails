module ManageIQ
  module API
    module Common
      module Users
        IDENTITY_KEY = 'x-rh-identity'.freeze
        VALID_KEYS = %w(account_number user username email is_org_admin)

        def self.current
          Thread.current[:attr_current_user] = validate
        end

        def self.with_user(other_headers)
          # Not Implemented
          raise "Not Implemented"
        end

        def self.decode(options = nil, key = IDENTITY_KEY)
          headers = options ? options : ManageIQ::API::Common::Headers.current
          raise StandardError, "Requires a valid header object" unless headers

          val = headers.instance_variable_get(:@req).stringify_keys
          JSON.parse(Base64.decode64(val[key]))
        end

        def self.encode(val)
          if val.is_a?(Hash)
            hashed = val.stringify_keys
            Base64.strict_encode64(hashed.to_json)
          else
            raise StandardError, "Must be a Hash"
          end
        end

        private_class_method def self.validate(*options)
          other = options.include?('other') ? options.flatten[:other] : nil
          other ? check_user(decode(other)) : check_user(decode)
        end

        # Identity header to be validated
        #{
        #  "identity": {
        #    "account_number": "0369233",
        #    "type": "User",
        #    "user" : {
        #      "username": "jdoe",
        #      "email": "jdoe@acme.com",
        #      "first_name": "John",
        #      "last_name": "Doe",
        #      "is_active": true,
        #      "is_org_admin": false,
        #      "is_internal": false,
        #      "locale": "en_US"
        #    },
        #    "internal" : {
        #      "org_id": "3340851",
        #      "auth_type": "basic-auth",
        #      "auth_time": 6300
        #     }
        #  }
        private_class_method def self.check_user(user)
          identity_list = (user['identity'].keys + user['identity']['user'].keys)
          if user.keys.include?('identity') && user['identity'].keys.include?('user')
            return user if (identity_list & VALID_KEYS).sort == VALID_KEYS.sort
          end
          raise StandardError, "Not a valid User Hash"
        end
      end
    end
  end
end
