module ManageIQ
  module API
    module Common
      module RBAC
        module Tools
          class Group < Base
            private

            def list
              user_output
              ManageIQ::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
                ManageIQ::API::Common::RBAC::Service.paginate(api, :list_groups, {}).each do |group|
                  list_output(group)
                end
              end
            end

            def print_details(opts, object = nil)
              # rubocop:disable Rails/Output
              case opts
              when :user
                puts "Policies for tenant: #{@user['identity']['account_number']} org admin user: #{@user['identity']['user']['username']}"
                puts
              when :group
                puts "\nGroup Name: #{object.name}"
                puts "Description: #{object.description}"
                puts "UUID: #{object.uuid}"
              end
              # rubocop:enable Rails/Output
            end
          end
        end
      end
    end
  end
end
