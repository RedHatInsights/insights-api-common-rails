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
    expect(response.parsed_body).to eq("errors" => [{"detail" => "Insights::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError: ID is invalid", "status" => 400}])
  end

  it "invalid ID (mixed integer and string characters)" do
    get("/api/v1.0/vms/123abc", :headers => headers)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "Insights::API::Common::ApplicationControllerMixins::RequestPath::RequestPathError: ID is invalid", "status" => 400}])
  end
end
