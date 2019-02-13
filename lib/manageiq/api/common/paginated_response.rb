module ManageIQ
  module API
    module Common
      class PaginatedResponse
        attr_reader :limit, :offset

        def initialize(base_query:, request:, limit: nil, offset: nil)
          @base_query = base_query
          @request    = request
          @limit      = (limit || 100).to_i.clamp(1, 1000)
          @offset     = (offset || 0).to_i.clamp(0, Float::INFINITY)
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
          @metadata_hash ||= {"count" => count}
        end

        def links_hash
          @links_hash ||= {
            "first" => link_to_first,
            "last"  => link_to_last,
            "prev"  => link_to_prev,
            "next"  => link_to_next,
          }
        end

        def link_to_first
          link_with_new_offset(0)
        end

        def link_to_last
          link_with_new_offset(max_limit_multiplier.clamp(0, Float::INFINITY) * limit)
        end

        def link_to_prev
          return if current_limit_multiplier == 0

          link_with_new_offset((current_limit_multiplier - 1) * limit)
        end

        def link_to_next
          next_limit_multiplier = current_limit_multiplier + 1
          return if next_limit_multiplier > max_limit_multiplier

          link_with_new_offset(next_limit_multiplier * limit)
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

        def current_limit_multiplier
          @current_limit_multiplier ||= offset / limit
        end

        def max_limit_multiplier
          @max_limit_multiplier ||= ((count - 1) / limit)
        end

        def count
          @count ||= @base_query.count
        end

        def records
          @records ||= @base_query.order(:id).limit(limit).offset(offset)
        end
      end
    end
  end
end
