module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module RequestParameterValidation
          def self.included(other)
            other.include(OpenapiEnabled)
          end
        end
      end
    end
  end
end
