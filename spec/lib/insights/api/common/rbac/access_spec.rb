describe Insights::API::Common::RBAC::Access do
  include_context "rbac_objects"

  let(:verb) { "read" }
  let(:rbac_access) { described_class.new }
  let(:access_obj) { rbac_access.process }
  let(:api_instance) { double }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:result) { instance_double(RBACApiClient::AccessPagination, :data => data) }

  before do
    stub_const("ENV", "APP_NAME" => app_name)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  it "rbac is enabled by default" do
    expect(described_class.enabled?).to be_truthy
  end

  it "rbac is disabled with ENV var BYPASS_RBAC=true" do
    stub_const("ENV", "BYPASS_RBAC" => "true")
    expect(described_class.enabled?).to be_falsey
  end

  context "admin scope" do
    let(:data) { [admin_scope] }
    it "checks admin scope" do
      allow(api_instance).to receive(:get_principal_access).with(app_name).and_return(result)
      expect(access_obj.accessible?(resource, 'read')).to be_truthy
      expect(access_obj.admin_scope?(resource, 'read')).to be_truthy
      expect(access_obj.user_scope?(resource, 'read')).to be_falsey
      expect(access_obj.group_scope?(resource, 'read')).to be_falsey
    end
  end

  context "user scope" do
    let(:data) { [user_scope] }
    it "checks user scope" do
      allow(api_instance).to receive(:get_principal_access).with(app_name).and_return(result)
      expect(access_obj.accessible?(resource, 'read', app_name)).to be_truthy
      expect(access_obj.user_scope?(resource, 'read', app_name)).to be_truthy
    end
  end

  context "group scope" do
    let(:data) { [group_scope] }
    it "checks group scope" do
      allow(api_instance).to receive(:get_principal_access).with(app_name).and_return(result)
      expect(access_obj.accessible?(resource, 'read', app_name)).to be_truthy
      expect(access_obj.group_scope?(resource, 'read')).to be_truthy
    end
  end

  context "multiple scopes" do
    let(:data) { [admin_scope, group_scope] }
    it "collects scopes" do
      allow(api_instance).to receive(:get_principal_access).with(app_name).and_return(result)

      expect(access_obj.scopes(resource, 'read')).to match_array(%w(admin group))
    end
  end
end
