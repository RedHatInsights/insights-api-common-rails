RSpec.describe "Insights::API::Common::ApplicationController Exception Handling", :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:error) { JSON.parse(response.body)["errors"] }

  before do
    stub_const("ENV", "BYPASS_TENANCY" => true)
    ActionDispatch::ExceptionWrapper.rescue_responses.merge!("Api::V1x0::ErrorsController::SomethingHappened" => 200)
  end

  context "when there is only one exception" do
    it "returns a properly formatted error doc" do
      get("/api/v1.0/error", :headers => headers)

      expect(response.status).to eq(400)
      expect(error.first["detail"]).to match(/StandardError/)
    end
  end

  context "when there is only one http exception" do
    it "returns a properly formatted error doc" do
      get("/api/v1.0/http_error", :headers => headers)

      expect(response.status).to eq(403)
      expect(error.first["status"]).to eq("403")
      expect(error.first["detail"]).to match(/UnauthorizedError/)
    end
  end

  context "when there are multiple exceptions" do
    before do
      get("/api/v1.0/error_nested", :headers => headers)
    end

    it "returns a properly formatted error doc" do
      expected_response = {
        "errors" => [
          {"status" => "200", "detail" => "Api::V1x0::ErrorsController::SomethingHappened: something else happened"},
          {"status" => "400", "detail" => "ArgumentError: something happened"}
        ]
      }

      expect(JSON.parse(response.body)).to eq expected_response
      expect(response.status).to eq(200)
    end

    it "uses the last response code as the status" do
      expect(response).to have_http_status 200
    end
  end

  context "when there is configured rescue_response" do
    before { ActionDispatch::ExceptionWrapper.rescue_responses.merge!("StandardError" => "201") }
    after {  ActionDispatch::ExceptionWrapper.rescue_responses.delete("StandardError") }

    it "returns the configured error" do
      get("/api/v1.0/error", :headers => headers)

      expect(error.first["status"]).to eq "201"
      expect(response.status).to eq(201)
    end
  end
end
