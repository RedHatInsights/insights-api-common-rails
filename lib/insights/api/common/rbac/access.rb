module Insights
  module API
    module Common
      module RBAC
        class Access
          attr_reader :acl
          DEFAULT_LIMIT = 500
          ADMIN_SCOPE = "admin"
          GROUP_SCOPE = "group"
          USER_SCOPE = "user"

          def initialize(app_name_filter = ENV["APP_NAME"])
            @app_name_filter = app_name_filter
          end

          def process
            Service.call(RBACApiClient::AccessApi) do |api|
              @acls ||= Service.paginate(api, :get_principal_access, {:limit => DEFAULT_LIMIT}, @app_name_filter).to_a
            end
            self
          end

          def scopes(resource, verb, app_name = ENV['APP_NAME'])
            regexp = create_regexp(app_name, resource, verb)
            @acls.each_with_object([]) do |item, memo|
              if regexp.match?(item.permission)
                memo << all_scopes(item)
              end
            end.flatten
          end

          def accessible?(resource, verb, app_name = ENV['APP_NAME'])
            regexp = create_regexp(app_name, resource, verb)
            @acls.any? { |item| regexp.match?(item.permission) }
          end

          def admin_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, ADMIN_SCOPE)
          end

          def group_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, GROUP_SCOPE)
          end

          def user_scope?(resource, verb, app_name = ENV['APP_NAME'])
            scope?(app_name, resource, verb, USER_SCOPE)
          end

          def self.enabled?
            ENV['BYPASS_RBAC'] != "true"
          end

          private

          def scope?(app_name, resource, verb, scope)
            regexp = create_regexp(app_name, resource, verb)
            @acls.any? do |item|
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

          def all_scopes(item)
            item.resource_definitions.each_with_object([]) do |rd, memo|
              if rd.attribute_filter.key == 'scope' &&
                rd.attribute_filter.operation == 'equal'
                memo << rd.attribute_filter.value
              end
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
