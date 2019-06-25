require "manageiq/api/common/graphql"

RSpec.describe ManageIQ::API::Common::GraphQL, :type => :request do
  let!(:source_type) { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:ext_tenant1) { rand(1000).to_s }
  let!(:tenant1)   { Tenant.create!(:name => "tenant_a", :external_tenant => ext_tenant1) }
  let!(:identity1) { Base64.encode64({'identity' => { 'account_number' => ext_tenant1 }}.to_json) }
  let!(:headers)   { { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity1 } }

  let!(:source_a)   { Source.create!(:tenant_id => tenant1.id, :uid => "12", :name => "source_a", :source_type => source_type) }
  let!(:source_b)   { Source.create!(:tenant_id => tenant1.id, :uid => "34", :name => "source_b", :source_type => source_type) }
  let!(:source_c)   { Source.create!(:tenant_id => tenant1.id, :uid => "56", :name => "source_c", :source_type => source_type) }
  let!(:source_d)   { Source.create!(:tenant_id => tenant1.id, :uid => "78", :name => "source_d", :source_type => source_type) }

  let!(:graphql_source_query) { { "query" => "{ sources { id name } }" }.to_json }

  context "querying sources" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "with no offset or limit returns all sources" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => "
        {
          sources {
            uid
            name
          }
        }" }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "12",
              "name": "source_a"
            },
            {
              "uid": "34",
              "name": "source_b"
            },
            {
              "uid": "56",
              "name": "source_c"
            },
            {
              "uid": "78",
              "name": "source_d"
            }
          ]
        }'))
    end
  end
end
