module Insights
  module API
    module Common
      class Routing
        attr_reader :route_mapper

        def initialize(route_mapper)
          @route_mapper = route_mapper
        end

        def redirect_major_version(version, prefix, via: [:delete, :get, :options])
          route_mapper.match(
            "/#{version.split('.').first}/*path(.:format)",
            :format => false,
            :via    => via,
            :to     => route_mapper.redirect(
              :path      => "/#{prefix}/#{version}/%{path}",
              :only_path => true,
              :status    => 302
            )
          )
        end
      end
    end
  end
end
