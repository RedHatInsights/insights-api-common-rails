module ManageIQ
  module API
    module Common
      module ApplicationControllerMixins
        module Graphql
          def api_version
            "v#{::ManageIQ::API::Common::GraphQL.version(request)}"
          end

          def api_doc
            @api_doc ||= ::ManageIQ::API::Common::OpenApi::Docs.instance[api_version[1..-1].sub(/x/, ".")]
          end
        end
      end
    end
  end
end
