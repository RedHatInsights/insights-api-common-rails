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

  context "pundit error" do
    it "returns a customized error message" do
      get("/api/v1.0/pundit_error", :headers => headers)
      expect(response.status).to eq(403)
      expect(error.first["detail"]).to match(/You are not authorized to perform the create action for this source type/)
    end
  end

  context "utf-8 conversion error" do
    it "returns the error message" do
      get "/api/v1.0/error_utf8", :headers => headers
      expect(response.status).to eq(400)
      expect(error.first["detail"]).to match(/StandardError/)
    end
  end

  context "api_client_error" do
    context "with response body" do
      let(:response_header) { { 'Content-Type' => 'application/json' } }
      let(:api_client_exception) do
        ApiClientError.new(:code            => 200,
                           :response_body   => response_body.to_json,
                           :response_header => response_header)
      end
      let(:response_body) do 
        {'errors' => [{'status' => '400', 'detail' => 'Sherrif Woody rejects rescue mission'},
                      {'status' => '404', 'detail' => 'Buzz is missing'}]}
      end

      before do
        allow(ApiClientError).to receive(:new).and_return(api_client_exception)
      end
      it "returns a properly formatted error doc" do
        get("/api/v1.0/api_client_error", :headers => headers)

        expect(error.count).to eq(2)
        expect(error.first['status']).to eq('400')
        expect(error.second['status']).to eq('404')
        expect(error.first['detail']).to eq('Sherrif Woody rejects rescue mission')
        expect(error.second['detail']).to eq('Buzz is missing')
      end
    end

    context "with invalid response body" do
      let(:response_header) { { 'Content-Type' => 'application/json' } }
      let(:api_client_exception) do
        ApiClientError.new(:code            => 503,
                           :response_body   => response_body,
                           :response_header => response_header)
      end
      let(:response_body) { "@" }

      before do
        allow(ApiClientError).to receive(:new).and_return(api_client_exception)
      end
      it "returns a properly formatted error doc" do
        get("/api/v1.0/api_client_error", :headers => headers)

        expect(error.count).to eq(1)
        expect(error.first['status']).to eq('503')
        expect(error.first['detail']).to match(/Error message/)
      end
    end

    context "no response body" do
      let(:api_client_exception) { ApiClientError.new(:message => 'test') }
      before do
        allow(ApiClientError).to receive(:new).and_return(api_client_exception)
      end
      it "returns a formatted error doc with classname" do
        get("/api/v1.0/api_client_error", :headers => headers)

        expect(error.count).to eq(1)
        expect(error.first['status']).to eq('400')
        expect(error.first['detail']).to eq("ApiClientError: test")
      end
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
