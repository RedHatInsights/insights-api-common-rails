module Insights
  module API
    module Common
      module GraphQL
        class AssociationLoader < ::GraphQL::Batch::Loader
          attr_reader :model, :association_name, :graphql_options, :args

          def initialize(model, association_name, graphql_options, args = {})
            @model            = model
            @association_name = association_name
            @graphql_options  = graphql_options
            @args             = args
          end

          def cache_key(record)
            record.object_id
          end

          def perform(records)
            records.each { |record| fulfill(record, read_association(record)) }
          end

          private

          def read_association(record)
            recs = GraphQL::AssociatedRecords.new(record.public_send(association_name))
            recs = GraphQL.search_options(recs, args)
            if graphql_options[:use_pagination_v2] == true
              PaginatedResponseV2.new(
                :base_query => recs, :request => nil, :limit => args[:limit], :offset => args[:offset]
              ).records
            else
              PaginatedResponse.new(
                :base_query => recs, :request => nil, :limit => args[:limit], :offset => args[:offset]
              ).records
            end
          end
        end
      end
    end
  end
end
