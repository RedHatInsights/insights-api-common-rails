describe Insights::API::Common::RBAC::UnshareResource do
  include_context "rbac_objects"
  let(:options) do
    { :permissions   => permissions,
      :group_uuids   => group_uuids,
      :app_name      => app_name,
      :resource_ids  => [resource_id1],
      :resource_name => "portfolios" }
  end
  let(:subject) { described_class.new(options) }
  let(:pagination_options) { { :limit => 500, :name => "catalog-portfolios-", :scope => "account" } }
  let(:group_pagination_options) { {:limit => Insights::API::Common::RBAC::Utilities::MAX_GROUPS_LIMIT} }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  shared_examples_for "#unshare" do
    it "remove resource definitions" do
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, group_pagination_options).and_return(groups)
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1, role2])
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_policies, {}).and_return(policies)
      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      allow(role1_detail).to receive(:access=)
      allow(api_instance).to receive(:update_role).and_return(role1_detail_updated)
      allow(api_instance).to receive(:delete_role)

      expect(subject.process.count).to eq(1)
    end
  end

  context "invalid group uuid" do
    let(:group_uuids) { %w[1] }
    it "raises exception if group id is invalid" do
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, group_pagination_options).and_return(groups)
      expect { subject.process }.to raise_exception(Insights::API::Common::InvalidParameter)
    end
  end

  context "with groups" do
    it_behaves_like "#unshare"
  end
end
