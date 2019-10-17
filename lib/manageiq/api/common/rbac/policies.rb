module ManageIQ
  module API
    module Common
      module RBAC
        class Policies
          def initialize(prefix)
            @prefix = prefix
          end

          def add_policy(policy_name, description, group_name, role_uuid)
            Service.call(RBACApiClient::PolicyApi) do |api_instance|
              policy_in = RBACApiClient::PolicyIn.new
              policy_in.name = policy_name
              policy_in.description = description
              policy_in.group = group_name
              policy_in.roles = [role_uuid]
              api_instance.create_policies(policy_in)
            end
          end

          # delete all policies that contains the role.
          def delete_policy(role)
            Service.call(RBACApiClient::PolicyApi) do |api_instance|
              Service.paginate(api_instance, :list_policies, :name => @prefix).each do |policy|
                api_instance.delete_policy(policy.uuid) if policy.roles.map(&:uuid).include?(role.uuid)
              end
            end
          end
        end
      end
    end
  end
end
