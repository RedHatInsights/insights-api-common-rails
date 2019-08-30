module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module Common
          def self.included(other)
            other.extend(self::ClassMethods)
          end

          private

          def model
            self.class.send(:model)
          end

          module ClassMethods
            private

            def model
              @model ||= controller_name.classify.constantize
            end
          end
        end
      end
    end
  end
end
