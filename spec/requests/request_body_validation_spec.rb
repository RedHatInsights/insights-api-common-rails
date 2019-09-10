RSpec.describe "ManageIQ::API::Common::ApplicationController Body", :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }

  before { stub_const("ENV", "BYPASS_TENANCY" => true) }

  it "empty body" do
    post("/api/v1.0/authentications", :headers => headers, :params => "")

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "Failed to parse request body, expected JSON", "status" => 400}])
  end

  it "unpermitted key" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"garbage" => "abc"}.to_json)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "properties garbage are not defined in #/components/schemas/Authentication", "status" => 400}])
  end

  it "permitted key, good value" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"username" => "abc"}.to_json)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, bad value" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"username" => 1}.to_json)

    expect(response.status).to eq(400)
    expect(response.parsed_body).to eq("errors" => [{"detail" => "1 class is Integer but it's not valid string in #/components/schemas/Authentication/properties/username", "status" => 400}])
  end

  it "permitted key, array" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"array" => [1]}.to_json)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, hash" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"hash" => {"a" => 1}}.to_json)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end

  it "permitted key, hash nested" do
    post("/api/v1.0/authentications", :headers => headers, :params => {"hash" => {"a" => {1 => {}}}}.to_json)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq("OK")
  end
end
