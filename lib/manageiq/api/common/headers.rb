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

        def self.decode(key)
          header = HeaderScope.current || nil
          if header
            val = header.instance_variable_get(:@req)
            JSON.parse(Base64.decode64(val[key]))
          end
        end

        def self.encode(val, key)
          Base64.strict_encode64(val[key].to_json)
        end

        def self.validate_headers(val)
          if val.is_a?(ActionDispatch::Http::Headers)
            return
          else
            raise StandardError, 'Not a Header Class'
          end
        end
      end
    end
  end
end
