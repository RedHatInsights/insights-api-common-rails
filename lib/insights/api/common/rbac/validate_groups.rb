module Insights
  module API
    module Common
      module RBAC
        class ValidateGroups
          def initialize(group_uuids)
            @group_uuids = group_uuids
          end

          def process
            return unless Insights::API::Common::RBAC::Access.enabled?

            Service.call(RBACApiClient::GroupApi) do |api|
              uuids = SortedSet.new
              Service.paginate(api, :list_groups, {:uuid => @group_uuids.to_a}).each { |group| uuids << group.uuid }
              missing = @group_uuids - uuids
              raise Insights::API::Common::InvalidParameter, "The following group uuids are missing #{missing.to_a.join(",")}" unless missing.empty?
            end
          end
        end
      end
    end
  end
end
