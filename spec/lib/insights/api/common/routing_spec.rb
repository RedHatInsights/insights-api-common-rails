RSpec.describe Insights::API::Common::Routing, :type => :request do
  let(:expected_version) { "v0.1" }
  let(:major_version) { "v1" }

  describe("/api/v0") do
    it "sanity test for a regular resource" do
      get("/api/#{expected_version}/vms")
      expect(response.status).to eq(200)
      expect(response.headers["Location"]).to be_nil
    end

    it "redirects to the latest minor version of a resource" do
      get("/api/v0/vms")
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/api/#{expected_version}/vms")
    end

    it "preserves the openapi.json file extension when using a redirect" do
      get("/api/v0/openapi.json")
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/api/#{expected_version}/openapi.json")
    end

    it "preserves the openapi.json file extension when not using a redirect" do
      get("/api/#{expected_version}/openapi.json")
      expect(response.status).to eq(200)
      expect(response.headers["Location"]).to be_nil
    end

    it "does not allow redirects to a POST endpoint" do
      expect { post("/api/#{major_version}/graphql") }.to raise_exception(ActionController::RoutingError)
    end
  end
end
