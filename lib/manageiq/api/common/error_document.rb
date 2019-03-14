module TopologicalInventory
  module Api
    class ErrorDocument
      def add(status = 400, message)
        @status = status
        errors << {"status" => status, "detail" => message}
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
