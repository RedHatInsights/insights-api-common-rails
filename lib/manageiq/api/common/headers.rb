module HeaderScope
  thread_mattr_accessor :current
end

module ManageIQ
  module API
    module Common
      module Headers

        def self.current=(val)
          validate_headers(val)
          HeaderScope.current = val
        end

        def self.current
          HeaderScope.current
        end

        def self.decode(headers, key)
          validate_headers(headers)
          val = headers.instance_variable_get(:@req).stringify_keys
          JSON.parse(Base64.decode64(val[key]))
        end

        def self.encode(val, key)
          if val.is_a?(Hash)
            hashed = val.stringify_keys
            Base64.strict_encode64(hashed[key].to_json)
          else
            raise StandardError, "Must be a Hash"
          end
        end

        def self.validate_headers(val)
          if val.is_a?(ActionDispatch::Http::Headers)
            true
          else
            raise StandardError, 'Not an ActionDispatch::Http::Headers Class'
          end
        end
      end
    end
  end
end
