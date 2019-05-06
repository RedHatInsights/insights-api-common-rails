module ManageIQ
  module API
    module Common
      class RequestNotSet < ArgumentError
        def initialize
          super("Current request has not been set")
        end
      end

      class Request
        REQUEST_ID_KEY = "x-rh-insights-request-id".freeze
        IDENTITY_KEY   = 'x-rh-identity'.freeze
        FORWARDABLE_HEADER_KEYS = [REQUEST_ID_KEY, IDENTITY_KEY].freeze
        OPTIONAL_AUTH_PATHS = [
          %r{\A/api/v[0-9]+(\.[0-9]+)?/openapi.json\z},
          %r{\A/api/[^/]+/v[0-9]+(\.[0-9]+)?/openapi.json\z}
        ].freeze

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
            when Request, nil
              request
            else
              raise ArgumentError, 'Not a ManageIQ::API::Common::Request or ActionDispatch::Request Class, Hash, or nil'
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

        def initialize(headers:, original_url:, **_kwargs)
          headers = from_hash(headers) if headers.kind_of?(Hash)
          @headers, @original_url = headers, original_url
        end

        def request_id
          headers.fetch(REQUEST_ID_KEY, nil)
        end

        def identity
          @identity ||= JSON.parse(Base64.decode64(headers.fetch(IDENTITY_KEY)))
        rescue KeyError
          raise IdentityError, "x-rh-identity not found"
        end

        def user
          @user ||= User.new(identity)
        end

        def entitlement
          @entitlement ||= Entitlement.new(identity)
        end

        def to_h
          {:headers => forwardable, :original_url => original_url}
        end

        def forwardable
          FORWARDABLE_HEADER_KEYS.each_with_object({}) do |key, hash|
            hash[key] = headers[key] if headers.key?(key)
          end
        end

        def required_auth?
          !optional_auth?
        end

        def optional_auth?
          uri_path = URI.parse(original_url).path
          OPTIONAL_AUTH_PATHS.any? { |optional_auth_path_regex| optional_auth_path_regex.match(uri_path) }
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
