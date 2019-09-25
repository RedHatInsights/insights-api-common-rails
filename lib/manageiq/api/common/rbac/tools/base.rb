module ManageIQ
  module API
    module Common
      module RBAC
        module Tools
          class Base
            def initialize(options)
              @options = options.dup
              @debug = options[:debug]
              @request = create_request(@options[:user_file])
            end

            def user_output
              # rubocop:disable Rails/Output
              @debug ? (puts @user) : print_details(:user)
              # rubocop:enable Rails/Output
            end

            def list_output(obj)
              # rubocop:disable Rails/Output
              @debug ? (puts obj) : print_details(self.class.name.demodulize.downcase.to_sym, obj)
              # rubocop:enable Rails/Output
            end

            def process
              ManageIQ::API::Common::Request.with_request(@request) do
                list
              end
            end

            def create_request(user_file)
              raise "File #{user_file} not found" unless File.exist?(user_file)

              @user = YAML.load_file(user_file)
              {:headers => {'x-rh-identity' => Base64.strict_encode64(@user.to_json)}, :original_url => '/'}
            end
          end
        end
      end
    end
  end
end
