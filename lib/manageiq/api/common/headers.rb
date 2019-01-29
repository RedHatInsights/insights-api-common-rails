module ManageIQ
  module API
    module Common
      module Headers
        def self.current=(val)
          validate_headers(val)
          Thread.current[:attr_current_headers] = val
        end

        def self.current
          Thread.current[:attr_current_headers]
        end

        private_class_method def self.validate_headers(val)
          raise ArgumentError, 'Not an ActionDispatch::Http::Headers Class' unless val.is_a?(ActionDispatch::Http::Headers)
          true
        end
      end
    end
  end
end
