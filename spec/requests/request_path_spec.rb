RSpec.describe "Insights::API::Common::ApplicationController Request path", :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }

  before { stub_const("ENV", "BYPASS_TENANCY" => true) }

  it "no ID" do
    get("/api/v1.0/vms", :headers => headers)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("things" => "stuff")
  end

  it "valid ID" do
    get("/api/v1.0/vms/123", :headers => headers)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("id" => "123")
  end

  it "invalid ID (only string characters)" do
    get("/api/v1.0/vms/abc", :headers => headers)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "Insights::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError: ID is invalid", "status" => "400"}])
  end

  it "invalid ID (mixed integer and string characters)" do
    get("/api/v1.0/vms/123abc", :headers => headers)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "Insights::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError: ID is invalid", "status" => "400"}])
  end

  context "when object id pattern is different" do
    let(:external_tenant) { rand(1000).to_s }
    let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
    let(:source_type)     { SourceType.create(:name => "AnsibleTower", :product_name => "RedHat AnsibleTower", :vendor => "redhat") }

    before do
      @source = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_type)
      @task = Task.create!(:tenant => tenant, :source => @source, :name => "Task_t1", :state => "pending")
    end

    it "valid ID" do
      get "/api/v2.0/tasks/#{@task.id}"
      get "/api/v2.0/sources/#{@source.id}/tasks"

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"].count).to eq(1)
      expect(response.parsed_body["data"].first["id"]).to eq(@task.id)
    end
  end
end
