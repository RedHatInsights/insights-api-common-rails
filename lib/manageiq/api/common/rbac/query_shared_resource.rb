module ManageIQ
  module API
    module Common
      module RBAC
        class QuerySharedResource
          require 'rbac-api-client'

          include Utilities
          attr_accessor :share_info

          def initialize(options)
            @app_name = options[:app_name]
            @resource_id = options[:resource_id]
            @resource_name = options[:resource_name]
            @share_info = []
            @roles = RBAC::Roles.new("#{@app_name}-#{@resource_name}-#{@resource_id}")
          end

          def process
            build_share_info
            self
          end

          private

          def build_share_info
            @roles.with_each_role do |role|
              _id, group_uuid = parse_ids_from_name(role.name)
              group = get_group(group_uuid)
              @share_info << { 'group_name'  => group.name,
                               'group_uuid'  => group.uuid,
                               'permissions' => role.access.collect(&:permission)}
            end
          end

          def get_group(uuid)
            Service.call(RBACApiClient::GroupApi) do |api_instance|
              api_instance.get_group(uuid)
            end
          end
        end
      end
    end
  end
end
