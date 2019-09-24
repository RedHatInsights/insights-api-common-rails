module ManageIQ
  module API
    module Common
      class ApiError < StandardError
        attr_reader :errors

        def initialize(status, detail)
          @errors = ErrorDocument.new.add(status, detail)
        end

        def status
          @errors.status
        end

        def add(status, detail)
          @errors.add(status, detail)
        end
      end
    end
  end
end
