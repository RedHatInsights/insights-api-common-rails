module ManageIQ
  module API
    module Common
      class Request
        FORWARDABLE_HEADER_KEYS = %w(X-Request-ID x-rh-identity).freeze

        def self.current
          Thread.current[:current_request]
        end

        def self.current=(request)
          Thread.current[:current_request] =
            case request
            when ActionDispatch::Request
              new(:headers => request.headers, :original_url => request.original_url)
            when Hash
              new(request)
            when nil
              request
            else
              raise ArgumentError, 'Not an ActionDispatch::Http::Headers Class or Hash, or nil'
            end
        end

        def self.with_request(request)
          saved = current
          self.current = request
          yield current
        ensure
          self.current = saved
        end

        def self.current_forwardable
          raise ManageIQ::API::Common::HeadersNotSet, "Current headers have not been set" unless current
          FORWARDABLE_HEADER_KEYS.each_with_object({}) do |key, hash|
            hash[key] = current.headers[key] if current.headers.key?(key)
          end
        end

        attr_reader :headers, :original_url

        def initialize(headers:, original_url:, **kwargs)
          headers = ActionDispatch::Http::Headers.from_hash(headers) if headers.kind_of?(Hash)
          @headers, @original_url = headers, original_url
        end

        def user
          @user ||= User.new
        end

        def to_h
          {:headers => headers.to_h, :original_url => original_url}
        end
      end
    end
  end
end
