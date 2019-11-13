RSpec.describe "Insights::API::Common::ApplicationController Parameters", :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }

  before { stub_const("ENV", "BYPASS_TENANCY" => true) }

  context "GET" do
    it "extra parameters fail" do
      get("/api/v1.0/persons", :params => {'limit' => 10, 'offset' => 0, 'notneeded' => 'yes'})
      expect(response.status).to eq(400)
    end

    it "valid parameters" do
      get("/api/v1.0/persons", :params => {'limit' => 10, 'offset' => 0})
      expect(response.status).to eq(200)
    end

    it "non openapi controller fails" do
      get("/api/v1.0/extras", :params => {'limit' => 10, 'offset' => 0, 'notneeded' => 'yes'})
      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['errors'][0]['detail']).to eq('ArgumentError: Openapi not enabled')
    end
  end

  context "POST" do
    it "valid parameters" do
      body = { 'name' => 'fred', 'zip' => '07825', 'age' => 45 }
      post("/api/v1.0/persons", :headers => headers, :params => body)
      expect(response.status).to eq(200)
    end

    it "extra parameters fail" do
      body = { 'extra' => 1, 'name' => 'fred', 'zip' => '07825', 'age' => 45 }
      post("/api/v1.0/persons", :headers => headers, :params => body)
      expect(response.status).to eq(400)
    end
  end

  context "POST with writeonly set" do
    it "readOnly parameters fail" do
      body = { "active" => "yes" }
      post("/api/v1.0/users?writeonly=true", :headers => headers, :params => body)
      expect(response.status).to eq(400)
    end

    it "looks up requestBody schema parameters" do
      body = { "reference_number" => "123" }
      post("/api/v1.0/users?writeonly=true", :headers => headers, :params => body)
      expect(response.status).to eq(200)
    end
  end

  context "PATCH" do
    it "valid parameters" do
      body = { 'name' => 'fred', 'zip' => '07825', 'age' => 45 }
      patch("/api/v1.0/persons/10", :headers => headers, :params => body)
      expect(response.status).to eq(200)
    end

    it "extra parameters fail" do
      body = { 'extra' => 1, 'name' => 'fred', 'zip' => '07825', 'age' => 45 }
      patch("/api/v1.0/persons/10", :headers => headers, :params => body)
      expect(response.status).to eq(400)
    end

    it "valid nested parameters" do
      body = { 'name' => 'fred', 'zip' => '07825', 'age' => 45, 'nested' => {'props' => 'abcd'} }
      patch("/api/v1.0/persons/10", :headers => headers, :params => body)
      expect(response.status).to eq(200)
    end

    it "readOnly parameters fail" do
      body = { "active" => "yes" }
      patch("/api/v1.0/users/10", :headers => headers, :params => body)
      expect(response.status).to eq(400)
    end
  end
end
