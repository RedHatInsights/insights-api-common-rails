module ManageIQ
  module API
    module Common
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::API::Common

        config.autoload_paths << root.join("lib").to_s

        initializer :load_inflections do
          ManageIQ::API::Common::Inflections.load_inflections
        end

        initializer :patch_option_redirect_routing do
          require 'action_dispatch/routing/redirection'
          ActionDispatch::Routing::OptionRedirect.prepend(ManageIQ::API::Common::OptionRedirectEnhancements)
        end
      end
    end
  end
end
