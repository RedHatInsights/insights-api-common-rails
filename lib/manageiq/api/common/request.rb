module ManageIQ
  module API
    module Common
      class RequestNotSet < ArgumentError
        def initialize
          super("Current request has not been set")
        end
      end

      class Request
        FORWARDABLE_HEADER_KEYS = %w(X-Request-ID x-rh-identity).freeze

        def self.current
          Thread.current[:current_request]
        end

        def self.current!
          current || raise(RequestNotSet)
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
          current!.forwardable
        end

        attr_reader :headers, :original_url

        def initialize(headers:, original_url:, **kwargs)
          headers = from_hash(headers) if headers.kind_of?(Hash)
          @headers, @original_url = headers, original_url
        end

        def user
          @user ||= User.new
        end

        def to_h
          {:headers => forwardable, :original_url => original_url}
        end

        def forwardable
          FORWARDABLE_HEADER_KEYS.each_with_object({}) do |key, hash|
            hash[key] = @headers[key] if @headers.key?(key)
          end
        end

        private

        def from_hash(hash)
          ActionDispatch::Http::Headers.from_hash({}).tap do |headers|
            hash.each { |k, v| headers.add(k, v) }
          end
        end
      end
    end
  end
end
