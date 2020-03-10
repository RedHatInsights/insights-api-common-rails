require "insights/api/common/graphql"

module Api
  module V2
    class GraphqlController < ApplicationController
      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema_v2(request)
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
