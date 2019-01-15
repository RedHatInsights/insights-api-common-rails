module ManageIQ
  module API
    module Common
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::API::Common

        config.autoload_paths << root.join("lib").to_s

        initializer :load_inflections do
          ManageIQ::API::Common::Inflections.load_inflections
        end
      end
    end
  end
end
