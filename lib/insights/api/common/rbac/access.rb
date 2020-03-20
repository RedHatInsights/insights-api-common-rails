module Insights
  module API
    module Common
      module RBAC
        class Access
          attr_reader :acl
          DEFAULT_LIMIT = 500
          def initialize(app_name_filter = ENV["APP_NAME"])
            @app_name_filter = app_name_filter
          end

          def process
            Service.call(RBACApiClient::AccessApi) do |api|
              @acl ||= Service.paginate(api, :get_principal_access, {:limit => DEFAULT_LIMIT}, @app_name_filter).to_a
            end
            self
          end

          def accessible?(resource, verb, app_name = ENV['APP_NAME'])
            regexp = create_regexp(app_name, resource, verb)
            @acl.any? { |item| regexp.match?(item.permission) }
          end

          def admin_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, "admin")
          end

          def group_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, "group")
          end

          def user_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, "user")
          end

          def self.enabled?
            ENV['BYPASS_RBAC'] != "true"
          end

          private

          def scope?(app_name, resource, verb, scope)
            regexp = create_regexp(app_name, resource, verb)
            @acl.any? do |item|
              regexp.match?(item.permission) && scope_matches?(item, scope)
            end
          end

          def scope_matches?(item, scope)
            item.resource_definitions.any? do |rd|
              rd.attribute_filter.key == 'scope' &&
                rd.attribute_filter.operation == 'equal' &&
                rd.attribute_filter.value == scope
            end
          end

          def create_regexp(app_name, resource, verb)
            Regexp.new("(#{Regexp.escape(app_name)}):(#{Regexp.escape(resource)}):(#{Regexp.escape(verb)})")
          end
        end
      end
    end
  end
end
