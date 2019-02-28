module ManageIQ
  module API
    module Common
      module Headers
        FORWARDABLE_HEADER_KEYS = %w(X-Request-ID x-rh-identity).freeze
        def self.current=(val)
          validate_headers(val) if val
          Thread.current[:attr_current_headers] = val
        end

        def self.current
          Thread.current[:attr_current_headers]
        end

        def self.with_headers(headers)
          saved_headers = current
          self.current = headers
          yield current
        ensure
          self.current = saved_headers
        end

        def self.current_forwardable
          raise ManageIQ::API::Common::HeadersNotSet, "Current header have not been set" unless Thread.current[:attr_current_headers]
          current.to_h.slice(*FORWARDABLE_HEADER_KEYS)
        end

        private_class_method def self.validate_headers(val)
          raise ArgumentError, 'Not an ActionDispatch::Http::Headers Class' unless val.kind_of?(ActionDispatch::Http::Headers)
          true
        end
      end
    end
  end
end
