module Api
  module V2x0
    class RootController < ApplicationController
      def openapi
        render :json => {:things => "stuff"}.to_json
      end
    end

    class AuthenticationsController < Api::V1x0::AuthenticationsController; end
    class VmsController             < Api::V1x0::VmsController; end
    class PersonsController         < Api::V1x0::PersonsController; end
    class ExtrasController          < Api::V1x0::ExtrasController; end
    class ErrorsController          < Api::V1x0::ErrorsController; end
    class GraphqlController         < Api::V2::GraphqlController; end
    class SourcesController         < Api::V2::SourcesController; end
    class SourceTypesController     < Api::V2::SourceTypesController; end
  end
end
