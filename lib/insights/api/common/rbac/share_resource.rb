module Insights
  module API
    module Common
      module RBAC
        class ShareResource
          require 'rbac-api-client'
          include Utilities

          def initialize(options)
            @app_name = options[:app_name]
            @resource_name = options[:resource_name]
            @permissions = options[:permissions]
            @resource_ids = options[:resource_ids]
            @group_uuids = SortedSet.new(options[:group_uuids])
            @acls = RBAC::ACL.new
          end

          def process
            validate_groups
            @roles = RBAC::Roles.new("#{@app_name}-#{@resource_name}-", 'account')
            @group_uuids.each { |uuid| manage_roles_for_group(uuid) }
            self
          end

          private

          def manage_roles_for_group(group_uuid)
            @resource_ids.each do |resource_id|
              name = unique_name(resource_id, group_uuid)
              role = @roles.find(name)
              role ? update_existing_role(role, resource_id) : add_new_role(name, group_uuid, resource_id)
            end
          end

          def update_existing_role(role, resource_id)
            role.access = @acls.add(role.access, resource_id, @permissions)
            @roles.update(role) if role.access.present?
          end

          def add_new_role(name, group_uuid, resource_id)
            acls = @acls.create(resource_id, @permissions)
            role = @roles.add(name, acls)
            add_role_to_group(group_uuid, role.uuid)
          end

          def add_role_to_group(group_uuid, role_uuid)
            Service.call(RBACApiClient::GroupApi) do |api_instance|
              role_in = RBACApiClient::GroupRoleIn.new
              role_in.roles = [role_uuid]
              api_instance.add_role_to_group(group_uuid, role_in)
            end
          end
        end
      end
    end
  end
end
