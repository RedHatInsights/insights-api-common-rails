module Insights
  module API
    module Common
      class ErrorDocument
        def add(status = 400, message)
          @status = status
          safe_message = message.to_s.encode('UTF-8', :invalid => :replace, :undef => :replace)
          errors << {"status" => status, "detail" => safe_message}
          self
        end

        def errors
          @errors ||= []
        end

        def status
          @status
        end

        def blank?
          errors.blank?
        end

        def to_h
          {"errors" => errors}
        end
      end
    end
  end
end
