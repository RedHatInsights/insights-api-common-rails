RSpec.describe "Insights::API::Common::ApplicationController Body", :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }

  before { stub_const("ENV", "BYPASS_TENANCY" => true) }
  let(:default_params) { { "authtype" => "openshift" } }

  context "when there is an invalid body" do
    let(:default_as) { :text }

    it "returns a 400" do
      post("/api/v1.0/authentications", :headers => {"CONTENT_TYPE" => "application/text"}, :params => "{")

      expect(response.status).to eq(400)
    end
  end

  it "unpermitted key" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("garbage" => "abc"))

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "OpenAPIParser::NotExistPropertyDefinition: #/components/schemas/Authentication does not define properties: garbage", "status" => 400}])
  end

  it "permitted key, good value" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("username" => "abc"))

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, bad value" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("username" => 1))

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "OpenAPIParser::ValidateError: #/components/schemas/Authentication/properties/username expected string, but received Integer: 1", "status" => 400}])
  end

  it "permitted key, array" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("array" => [1]))

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, hash" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("hash" => {"a" => 1}))

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, hash nested" do
    post("/api/v1.0/authentications", :headers => headers, :params => default_params.merge("hash" => {"a" => {1 => {}}}))

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "required property is missing" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"username" => "abc"})

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "OpenAPIParser::NotExistRequiredKey: #/components/schemas/Authentication missing required parameters: authtype", "status" => 400}])
  end

  it "empty body" do
    post("/api/v1.0/authentications", :headers => headers)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "OpenAPIParser::NotExistRequiredKey: #/components/schemas/Authentication missing required parameters: authtype", "status" => 400}])
  end
end
