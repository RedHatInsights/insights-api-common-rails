module Insights
  module API
    module Common
      class System
        def initialize(identity)
          @system = identity.dig("identity", "system")
        end

        def cn
          system["cn"]
        end

        private

        attr_reader :system
      end
    end
  end
end
