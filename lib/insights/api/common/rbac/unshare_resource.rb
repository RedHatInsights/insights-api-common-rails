module Insights
  module API
    module Common
      module RBAC
        require 'rbac-api-client'

        class UnshareResource < ShareResource
          attr_accessor :count

          def initialize(options)
            @count = 0
            super
          end

          private

          def manage_roles_for_group(group_uuid)
            @resource_ids.each do |resource_id|
              name = unique_name(resource_id, group_uuid)
              role = @roles.find(name)
              next unless role

              role.access = @acls.remove(role.access, resource_id, @permissions)
              role.access.present? ? @roles.update(role) : cleanup_shares(group_uuid, role)
              @count += 1
            end
          end

          def cleanup_shares(group_uuid, role)
            @roles.delete(role)
            delete_role_from_group(group_uuid, role)
          end

          def delete_role_from_group(group_uuid, role)
            Service.call(RBACApiClient::GroupApi) do |api_instance|
              api_instance.delete_role_from_group(group_uuid, role.uuid)
            end
          end
        end
      end
    end
  end
end
