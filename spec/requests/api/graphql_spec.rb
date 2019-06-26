require "manageiq/api/common/graphql"

RSpec.describe ManageIQ::API::Common::GraphQL, :type => :request do
  let!(:source_type) { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:ext_tenant1) { rand(1000).to_s }
  let!(:tenant1)   { Tenant.create!(:name => "tenant_a", :external_tenant => ext_tenant1) }
  let!(:identity1) { Base64.encode64({'identity' => { 'account_number' => ext_tenant1 }}.to_json) }
  let!(:headers)   { { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity1 } }

  let!(:source_a1)   { Source.create!(:tenant_id => tenant1.id, :uid => "1", :name => "source_a1", :source_type => source_type) }
  let!(:source_a2)   { Source.create!(:tenant_id => tenant1.id, :uid => "2", :name => "source_a2", :source_type => source_type) }
  let!(:source_b1)   { Source.create!(:tenant_id => tenant1.id, :uid => "3", :name => "source_b1", :source_type => source_type) }
  let!(:source_b2)   { Source.create!(:tenant_id => tenant1.id, :uid => "4", :name => "source_b2", :source_type => source_type) }
  let!(:source_b3)   { Source.create!(:tenant_id => tenant1.id, :uid => "5", :name => "source_b3", :source_type => source_type) }

  let!(:graphql_source_query) { { "query" => "{ sources { id name } }" }.to_json }

  context "querying sources" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "with no offset or limit returns all sources" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources {
            uid
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "1",
              "name": "source_a1"
            },
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            },
            {
              "uid": "4",
              "name": "source_b2"
            },
            {
              "uid": "5",
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors limit parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(limit: 2) {
            uid
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "1",
              "name": "source_a1"
            },
            {
              "uid": "2",
              "name": "source_a2"
            }
          ]
        }'))
    end

    it "honors offset parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(offset: 1) {
            uid
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            },
            {
              "uid": "4",
              "name": "source_b2"
            },
            {
              "uid": "5",
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors offset and limit parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(offset: 1, limit: 2) {
            uid
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "uid": "2",
              "name": "source_a2"
            },
            {
              "uid": "3",
              "name": "source_b1"
            }
          ]
        }'))
    end

    it "honors filter parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b"}}) {
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b1"
            },
            {
              "name": "source_b2"
            },
            {
              "name": "source_b3"
            }
          ]
        }'))
    end

    it "honors filter and limit parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { ends_with: "2"}}, limit: 1) {
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_a2"
            }
          ]
        }'))
    end

    it "honors filter with offset and limit parameter" do
      post("/api/v1.0/graphql", :headers => headers, :params => { "query" => '
        {
          sources(filter: { name: { starts_with: "source_b"}}, offset: 1, limit: 1) {
            name
          }
        }' }.to_json)

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_b2"
            }
          ]
        }'))
    end
  end
end
