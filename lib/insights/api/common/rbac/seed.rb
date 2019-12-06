module Insights
  module API
    module Common
      module RBAC
        require 'rbac-api-client'

        class Seed
          def initialize(seed_file, user_file = nil)
            @acl_data = YAML.load_file(seed_file)
            @request = Insights::API::Common::Request.current || create_request(user_file)
          end

          def process
            Insights::API::Common::Request.with_request(@request) do
              create_groups
              create_roles
              add_roles_to_groups
            rescue RBACApiClient::ApiError => e
              Rails.logger.error("Exception when RBACApiClient::ApiError : #{e}")
              raise
            end
          end

          private

          def create_groups
            current = current_groups
            names = current.collect(&:name)
            group = RBACApiClient::Group.new
            Service.call(RBACApiClient::GroupApi) do |api_instance|
              @acl_data['groups'].each do |grp|
                next if names.include?(grp['name'])

                group.name = grp['name']
                group.description = grp['description']
                api_instance.create_group(group)
              end
            end
          end

          def current_groups
            Service.call(RBACApiClient::GroupApi) do |api|
              Service.paginate(api, :list_groups,  {}).to_a
            end
          end

          def create_roles
            current = current_roles
            names = current.collect(&:name)
            role_in = RBACApiClient::RoleIn.new
            Service.call(RBACApiClient::RoleApi) do |api_instance|
              @acl_data['roles'].each do |role|
                next if names.include?(role['name'])

                role_in.name = role['name']
                role_in.access = []
                role['access'].each do |obj|
                  access = RBACApiClient::Access.new
                  access.permission = obj['permission']
                  access.resource_definitions = create_rds(obj)
                  role_in.access << access
                end
                api_instance.create_roles(role_in)
              end
            end
          end

          def create_rds(obj)
            obj.fetch('resource_definitions', []).collect do |item|
              RBACApiClient::ResourceDefinition.new.tap do |rd|
                rd.attribute_filter = RBACApiClient::ResourceDefinitionFilter.new.tap do |rdf|
                  rdf.key = item['attribute_filter']['key']
                  rdf.value = item['attribute_filter']['value']
                  rdf.operation = item['attribute_filter']['operation']
                end
              end
            end
          end

          def add_new_role_to_group(api_instance, group_uuid, role_uuid)
            role_in = RBACApiClient::GroupRoleIn.new
            role_in.roles = [role_uuid]
            api_instance.add_role_to_group(group_uuid, role_in)
          end

          def role_exists_in_group?(api_instance, group_uuid, role_uuid)
            api_instance.list_roles_for_group(group_uuid).any? do |role|
              role.uuid == role_uuid
            end
          end

          def current_roles
            Service.call(RBACApiClient::RoleApi) do |api|
              Service.paginate(api, :list_roles, {}).to_a
            end
          end

          def add_roles_to_groups
            groups = current_groups
            roles = current_roles
            Service.call(RBACApiClient::GroupApi) do |api_instance|
              @acl_data['policies'].each do |link|
                group_uuid = find_uuid('Group', groups, link['group']['name'])
                role_uuid = find_uuid('Role', roles, link['role']['name'])
                next if role_exists_in_group?(api_instance, group_uuid, role_uuid)

                add_new_role_to_group(api_instance, group_uuid, role_uuid)
              end
            end
          end

          def find_uuid(type, data, name)
            result = data.detect { |item| item.name == name }
            raise "#{type} #{name} not found in RBAC service" unless result

            result.uuid
          end

          def create_request(user_file)
            raise "File #{user_file} not found" unless File.exist?(user_file)

            user = YAML.load_file(user_file)
            {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
          end
        end
      end
    end
  end
end
