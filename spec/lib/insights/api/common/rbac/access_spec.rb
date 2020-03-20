describe Insights::API::Common::RBAC::Access do
  include_context "rbac_objects"

  let(:verb) { "read" }
  let(:rbac_access) { described_class.new }
  let(:access_obj) { rbac_access.process }
  let(:api_instance) { double }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:opts) { { :limit => described_class::DEFAULT_LIMIT } }

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

  it "checks admin scope" do
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, opts, app_name).and_return([admin_scope])
    expect(access_obj.accessible?(resource, 'read')).to be_truthy
    expect(access_obj.admin_scope?(resource, 'read')).to be_truthy
    expect(access_obj.user_scope?(resource, 'read')).to be_falsey
    expect(access_obj.group_scope?(resource, 'read')).to be_falsey
  end

  it "checks user scope" do
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, opts, app_name).and_return([user_scope])

    expect(access_obj.accessible?(resource, 'read', app_name)).to be_truthy
    expect(access_obj.user_scope?(resource, 'read', app_name)).to be_truthy
  end

  it "checks group scope" do
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, opts, app_name).and_return([group_scope])
    expect(access_obj.accessible?(resource, 'read', app_name)).to be_truthy
    expect(access_obj.group_scope?(resource, 'read')).to be_truthy
  end
end
