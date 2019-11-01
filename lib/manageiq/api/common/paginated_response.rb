module ManageIQ
  module API
    module Common
      class PaginatedResponse
        attr_reader :limit, :offset, :sort_by

        def initialize(base_query:, request:, limit: nil, offset: nil, sort_by: nil)
          @base_query = base_query
          @request    = request
          @limit      = (limit || 100).to_i.clamp(1, 1000)
          @offset     = (offset || 0).to_i.clamp(0, Float::INFINITY)
          @sort_by    = sort_by
        end

        def records
          @records ||= begin
            res = @base_query.order(:id).limit(limit).offset(offset)
            order_options = sort_by_options(res.klass)
            res = res.reorder(order_options) if order_options.present?
            res
          end
        end

        def response
          {
            "meta"  => metadata_hash,
            "links" => links_hash,
            "data"  => records
          }
        end

        private

        def metadata_hash
          @metadata_hash ||= {"count" => count, "limit" => limit, "offset" => offset}
        end

        def links_hash
          @links_hash ||= {
            "first" => link_to_first,
            "last"  => link_to_last,
            "prev"  => link_to_prev,
            "next"  => link_to_next,
          }.compact
        end

        def link_to_first
          link_with_new_offset(0)
        end

        def link_to_last
          link_with_new_offset(max_limit_multiplier.clamp(0, Float::INFINITY) * limit)
        end

        def link_to_prev
          return if offset == 0
          prev_offset = offset - limit

          link_with_new_offset(prev_offset.clamp(0, Float::INFINITY))
        end

        def link_to_next
          next_offset = limit + offset
          return if next_offset >= count

          link_with_new_offset(next_offset)
        end

        def link_with_new_offset(offset)
          URI::Generic.build(:path => request_uri.path, :query => query_hash_merge("offset" => offset.to_s)).to_s
        end

        def query_hash_merge(new_hash)
          parsed_query.merge(new_hash).to_query
        end

        def parsed_query
          @parsed_query ||= Rack::Utils.parse_query(request_uri.query)
        end

        def request_uri
          @request_uri ||= URI.parse(@request.original_url)
        end

        def max_limit_multiplier
          @max_limit_multiplier ||= ((count - 1) / limit)
        end

        def count
          @count ||= @base_query.count
        end

        def sort_by_options(model)
          @sort_by_options ||= begin
            Array(sort_by).collect do |selection|
              sort_attr, sort_order = selection.split(':')
              sort_order ||= "asc"
              arel = model.arel_attribute(sort_attr)
              arel = arel.asc  if sort_order == "asc"
              arel = arel.desc if sort_order == "desc"
              arel
            end
          end
        end
      end
    end
  end
end
