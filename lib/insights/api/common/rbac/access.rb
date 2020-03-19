module Insights
  module API
    module Common
      module RBAC
        class Access
          attr_reader :acl
          DEFAULT_LIMIT = 500
          def initialize(resource, verb, app_name = ENV["APP_NAME"])
            @resource = resource
            @verb     = verb
            @app_name = app_name
          end

          def process
            regexp = create_regexp(@app_name, @resource, @verb) if @app_name && @resource && @verb
            Service.call(RBACApiClient::AccessApi) do |api|
              @acl ||= Service.paginate(api, :get_principal_access, {:limit => DEFAULT_LIMIT}, @app_name).select do |item|
                regexp ? regexp.match?(item.permission) : true
              end
            end
            self
          end

          def accessible?
            @acl.any?
          end

          def is_accessible?(app_name, resource, verb)
            regexp = create_regexp(app_name, resource, verb)
            @acl.any? { |item| regexp.match?(item.permission) }
          end

          def admin_scope?(app_name, resource, verb)
            scope?(app_name, resource, verb, "admin")
          end

          def group_scope?(app_name, resource, verb)
            scope?(app_name, resource, verb, "group")
          end

          def user_scope?(app_name, resource, verb)
            scope?(app_name, resource, verb, "user")
          end

          def id_list
            ids.include?('*') ? [] : ids
          end

          def owner_scoped?
            ids.include?('*') ? false : owner_scope_filter?
          end

          def self.enabled?
            ENV['BYPASS_RBAC'] != "true"
          end

          private

          def ids
            @ids ||= @acl.each_with_object([]) do |item, ids|
              item.resource_definitions.each do |rd|
                next unless rd.attribute_filter.key == 'id'
                next unless rd.attribute_filter.operation == 'equal'

                ids << rd.attribute_filter.value
              end
            end
          end

          def owner_scope_filter?
            @acl.any? do |item|
              item.resource_definitions.any? do |rd|
                rd.attribute_filter.key == 'owner' &&
                  rd.attribute_filter.operation == 'equal' &&
                  rd.attribute_filter.value == '{{username}}'
              end
            end
          end

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
