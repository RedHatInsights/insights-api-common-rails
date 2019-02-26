module ManageIQ
  module API
    module Common
      module Headers
        FORWARDABLE_HEADER_KEYS = %w(X-Request-ID x-rh-identity)
        def self.current=(val)
          validate_headers(val)
          Thread.current[:attr_current_headers] = val
        end

        def self.current
          Thread.current[:attr_current_headers]
        end

        def self.forwardable_headers
          raise "Current Headers has not been set" unless Thread.current[:attr_current_headers]
          Thread.current[:attr_current_headers].to_h.slice(*FORWARDABLE_HEADER_KEYS)
        end

        private_class_method def self.validate_headers(val)
          raise ArgumentError, 'Not an ActionDispatch::Http::Headers Class' unless val.is_a?(ActionDispatch::Http::Headers)
          true
        end
      end
    end
  end
end
