require "insights/api/common/graphql"

RSpec.describe Insights::API::Common::GraphQL, :type => :request do
  let!(:graphql_endpoint) { "/api/v2.0/graphql" }

  let!(:ext_tenant)   { rand(1000).to_s }
  let!(:tenant)       { Tenant.create!(:name => "tenant_a", :external_tenant => ext_tenant) }
  let!(:identity)     { Base64.encode64({'identity' => { 'account_number' => ext_tenant }}.to_json) }
  let!(:headers)      { { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity } }

  let!(:source_typeR) { SourceType.create(:name => "rhev_sample", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:source_typeV) { SourceType.create(:name => "vmware_sample", :product_name => "VmWare vCenter", :vendor => "vmware") }
  let!(:source_typeO) { SourceType.create(:name => "openstack_sample", :product_name => "OpenStack", :vendor => "redhat") }

  let!(:source_a1)    { Source.create!(:tenant => tenant, :uid => "1", :name => "source_a1", :source_type => source_typeR) }
  let!(:source_a2)    { Source.create!(:tenant => tenant, :uid => "2", :name => "source_a2", :source_type => source_typeR) }
  let!(:source_b1)    { Source.create!(:tenant => tenant, :uid => "3", :name => "source_b1", :source_type => source_typeR) }
  let!(:source_b2)    { Source.create!(:tenant => tenant, :uid => "4", :name => "source_b2", :source_type => source_typeR) }
  let!(:source_b3)    { Source.create!(:tenant => tenant, :uid => "5", :name => "source_b3", :source_type => source_typeR) }

  let!(:endpoint_a21) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "121", :role => "web_lb1") }
  let!(:endpoint_a22) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "122", :role => "web_lb2") }
  let!(:endpoint_a23) { Endpoint.create!(:tenant => tenant, :source => source_a2, :host => "source_a2.example.com", :port => "123", :role => "web_lb3") }

  let!(:endpoint_b21) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "221", :role => "web_lb1") }
  let!(:endpoint_b22) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "222", :role => "web_lb2") }
  let!(:endpoint_b23) { Endpoint.create!(:tenant => tenant, :source => source_b2, :host => "source_b2.example.com", :port => "223", :role => "web_lb3") }

  let!(:auth_a221)    { Authentication.create!(:tenant => tenant, :resource => endpoint_a22, :authtype => "userpassword", :username => "admin", :password => "secret") }
  let!(:auth_a222)    { Authentication.create!(:tenant => tenant, :resource => endpoint_a22, :authtype => "token") }

  let!(:auth_b221)    { Authentication.create!(:tenant => tenant, :resource => endpoint_b22, :authtype => "userpassword", :username => "admin", :password => "secret") }
  let!(:auth_b222)    { Authentication.create!(:tenant => tenant, :resource => endpoint_b22, :authtype => "token") }

  context "supports result sorting" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "via sort_by with a single attribute" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: { vendor: "asc" } ) {
            vendor
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| st["vendor"] })
        .to eq(%w[redhat redhat vmware])
    end

    it "via sort_by with a single attribute in descending order" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: { vendor: "desc" } ) {
            vendor
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| st["vendor"] })
        .to eq(%w[vmware redhat redhat])
    end

    it "via sort_by with a multiple attributes in mixed order" do
      post(graphql_endpoint, :headers => headers, :params => { "query" => '
        {
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: { vendor: null product_name: "desc" } ) {
            vendor
            product_name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| [st["vendor"], st["product_name"]] })
        .to eq([["redhat", "RedHat Virtualization"], ["redhat", "OpenStack"], ["vmware", "VmWare vCenter"]])
    end
  end
end
