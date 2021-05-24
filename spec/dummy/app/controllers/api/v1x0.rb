module Api
  module V1x0
    class AuthenticationsController < ApplicationController
      def create
        params_for_create
        render :json => "OK".to_json
      end

      def update
        params_for_update
        render :json => "OK".to_json
      end
    end

    class RootController < ApplicationController
      def openapi
        render :json => {:things => "stuff"}.to_json
      end
    end

    class VmsController < ApplicationController
      def index
        render :json => {:things => "stuff"}.to_json
      end

      def show
        render :json => {:id => request_path_parts["primary_collection_id"]}.to_json
      end
    end

    class PersonsController < ApplicationController
      def create
        params_for_create
        render :json => "OK".to_json
      end

      def update
        params_for_update
        render :json => "OK".to_json
      end

      def index
        safe_params_for_list
        render :json => {:things => "stuff"}.to_json
      end
    end

    class ExtrasController < ApplicationController
      self.openapi_enabled = false

      def index
        safe_params_for_list
        render :json => "OK".to_json
      end
    end

    class ErrorsController < ApplicationController
      class SomethingHappened < StandardError; end

      def error
        raise StandardError, "something happened"
      end

      def error_nested
        raise ArgumentError, "something happened"
      rescue ArgumentError
        raise SomethingHappened, "something else happened"
      end

      def error_utf8
        raise StandardError, "something \xAE happened"
      end

      def http_error
        raise ActionCable::Connection::Authorization::UnauthorizedError
      end

      def api_client_error
        raise ApiClientError.new
      end

      def pundit_error
        raise Pundit::NotAuthorizedError.new("create?", SourceType)
      end
    end

    class GraphqlController < Api::V1::GraphqlController; end
    class SourcesController < Api::V1::SourcesController; end
    class SourceTypesController < Api::V1::SourceTypesController; end
  end
end

module Pundit
  class NotAuthorizedError < StandardError
    attr_accessor :query, :record, :policy

    def initialize(query, record, policy = nil)
      @query = query
      @record = record
      @policy = policy
    end
  end
end
