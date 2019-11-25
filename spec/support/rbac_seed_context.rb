RSpec.shared_context "rbac_seed_objects" do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolios" }
  let(:permissions) { ["#{app_name}:#{resource}:read"] }
  let(:resource_id1) { "99" }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'Test Group', :uuid => "123") }
  let(:role1) { instance_double(RBACApiClient::RoleOut, :name => "Test Role", :uuid => "67899") }
  let(:role1_in) { RBACApiClient::GroupRoleIn.new }

  let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid, :access => [access1]) }
  let(:groups) { [group1] }
  let(:roles) { [role1] }
  let(:filter1) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => resource_id1) }
  let(:resource_def1) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => filter1) }
  let(:access1) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:group_uuids) { [group1.uuid] }
  let(:api_instance) { double }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
end
