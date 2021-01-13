module Insights
  module API
    module Common
      class CustomExceptions
        CUSTOM_EXCEPTION_LIST = %w[Pundit::NotAuthorizedError].freeze

        def self.custom_message(exception)
          case exception.class.to_s
          when "Pundit::NotAuthorizedError"
            exception.policy.try(:error_message) ||
              "You are not authorized to perform the #{exception.query.to_s.delete_suffix('?')} action for this #{exception.record.model_name.human.downcase}"
          end
        end
      end
    end
  end
end
