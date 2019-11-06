require "insights/api/common/graphql"

module Api
  module V1
    class GraphqlController < ApplicationController
      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema(request)
        variables = ::Insights::API::Common::GraphQL.ensure_hash(params[:variables])
        result = graphql_api_schema.execute(
          params[:query],
          :variables => variables
        )
        render :json => result
      end
    end
  end
end
