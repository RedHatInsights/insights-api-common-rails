module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module OpenapiEnabled
          def self.included(other)
            other.class_attribute :openapi_enabled, :default => true
          end
        end
      end
    end
  end
end
