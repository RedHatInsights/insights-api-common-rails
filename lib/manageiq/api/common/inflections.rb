module ManageIQ
  module API
    module Common
      module Inflections
        def self.load_inflections
          @loaded ||= begin
            load_common_inflections
            true
          end
        end

        def self.load_common_inflections
          # Add new inflection rules using the following format
          # (all these examples are active by default):
          # ActiveSupport::Inflector.inflections do |inflect|
          #   inflect.plural /^(ox)$/i, '\1en'
          #   inflect.singular /^(ox)en/i, '\1'
          #   inflect.irregular 'person', 'people'
          #   inflect.uncountable %w( fish sheep )
          # end
          ActiveSupport::Inflector.inflections do |inflect|
            inflect.acronym('ManageIQ')
          end
        end
      end
    end
  end
end
