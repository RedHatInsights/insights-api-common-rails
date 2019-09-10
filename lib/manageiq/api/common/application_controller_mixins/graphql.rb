module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module Graphql
          def api_version
            "v#{::ManageIQ::API::Common::GraphQL.version(request)}"
          end
        end
      end
    end
  end
end
