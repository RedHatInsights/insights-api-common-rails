module ManageIQ
  module API
    module Common
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::API::Common
      end
    end
  end
end
