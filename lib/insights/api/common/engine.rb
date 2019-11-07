module Insights
  module API
    module Common
      class Engine < ::Rails::Engine
        isolate_namespace Insights::API::Common

        config.autoload_paths << root.join("lib").to_s

        initializer :load_inflections do
          Insights::API::Common::Inflections.load_inflections
        end

        initializer :patch_option_redirect_routing do
          require 'action_dispatch/routing/redirection'
          ActionDispatch::Routing::OptionRedirect.prepend(Insights::API::Common::OptionRedirectEnhancements)
        end
      end
    end
  end
end
