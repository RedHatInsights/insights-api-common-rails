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

  let!(:catalog_apptype) { ApplicationType.create(:name => "/insights/platform/catalog", :display_name => "Catalog") }
  let!(:cost_apptype)    { ApplicationType.create(:name => "/insights/platform/cost-management", :display_name => "Cost Management") }
  let!(:topo_apptype)    { ApplicationType.create(:name => "/insights/platform/topological-inventory", :display_name => "Topological Inventory") }

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
          source_types(filter: { name: { ends_with: "sample" } }, sort_by: { vendor: null, product_name: "desc" } ) {
            vendor
            product_name
          }
        }' })

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]["source_types"].collect { |st| [st["vendor"], st["product_name"]] })
        .to eq([["redhat", "RedHat Virtualization"], ["redhat", "OpenStack"], ["vmware", "VmWare vCenter"]])
    end
  end

  context "supports sort_by with association attributes" do
    before do
      stub_const("ENV", "BYPASS_TENANCY" => nil)

      @source_s1 = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_typeR)
      @source_s2 = Source.create!(:tenant => tenant, :name => "source_s2", :source_type => source_typeR)
      @source_s3 = Source.create!(:tenant => tenant, :name => "source_s3", :source_type => source_typeR)
    end

    it "sorting with an association attribute in ascending order" do
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { display_name: null } }) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Cost Management" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting with an association attribute in descending order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { display_name: "desc" } } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "display_name": "Cost Management" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            }
          ]
        }'))
    end

    it "sorting with an association attribute and direct attribute in mixed order" do
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s" } }, sort_by: { application_types: { display_name: "asc" }, name: "desc" } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "display_name": "Cost Management" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Cost Management" }
              ]
            }
          ]
        }'))
    end
  end

  context "supports sort_by with multiple association attributes" do
    before do
      stub_const("ENV", "BYPASS_TENANCY" => nil)

      source_s1 = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_typeR)
      source_s2 = Source.create!(:tenant => tenant, :name => "source_s2", :source_type => source_typeR)
      source_s3 = Source.create!(:tenant => tenant, :name => "source_s3", :source_type => source_typeR)

      top1_apptype = ApplicationType.create(:name => "/topological-inventory", :display_name => "Topological Inventory")
      cat1_apptype = ApplicationType.create(:name => "/catalog1", :display_name => "Catalog")
      cat2_apptype = ApplicationType.create(:name => "/catalog2", :display_name => "Catalog")

      Application.create(:application_type => cat1_apptype, :source => source_s1, :tenant => tenant)
      Application.create(:application_type => cat2_apptype, :source => source_s2, :tenant => tenant)
      Application.create(:application_type => top1_apptype, :source => source_s3, :tenant => tenant)
    end

    it "sorting with multiple association attribute in ascending order" do
      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s" } }, sort_by: { application_types: { display_name: "asc",  name: "asc" }} ) {
            name
            application_types {
              name
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s1",
              "application_types": [
                { "name": "/catalog1", "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "name": "/catalog2", "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "name": "/topological-inventory", "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting with multiple association attribute with mixed order" do
      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s" } }, sort_by: { application_types: { display_name: "desc",  name: "asc" }} ) {
            name
            application_types {
              name
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s3",
              "application_types": [
                { "name": "/topological-inventory", "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "name": "/catalog1", "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "name": "/catalog2", "display_name": "Catalog" }
              ]
            }
          ]
        }'))
    end
  end

  context "supports sort_by with association count" do
    before do
      stub_const("ENV", "BYPASS_TENANCY" => nil)

      @source_s1 = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_typeR)
      @source_s2 = Source.create!(:tenant => tenant, :name => "source_s2", :source_type => source_typeR)
      @source_s3 = Source.create!(:tenant => tenant, :name => "source_s3", :source_type => source_typeR)
    end

    it "sorting based on an association count" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s" } }, sort_by: { application_types: { __count: null }, name: null } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s3",
              "application_types": [
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting based on an association count in reverse order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { __count: "desc" } } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
              ]
            }
          ]
        }'))
    end

    it "sorting based on an association count with secondary field" do
      @source_s4 = Source.create!(:tenant => tenant, :name => "source_s4", :source_type => source_typeR)

      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { __count: null }, name: null } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s3",
              "application_types": [
              ]
            },
            {
              "name": "source_s4",
              "application_types": [
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting based on a direct association count with descending secondary field" do
      @source_s4 = Source.create!(:tenant => tenant, :name => "source_s4", :source_type => source_typeR)

      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { applications: { __count: "asc" }, name: "desc" } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s4",
              "application_types": [
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting based on an association count with secondary field" do
      @source_s4 = Source.create!(:tenant => tenant, :name => "source_s4", :source_type => source_typeR)

      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { __count: null }, name: null } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s3",
              "application_types": [
              ]
            },
            {
              "name": "source_s4",
              "application_types": [
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
                { "display_name": "Catalog" }
              ]
            },
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            }
          ]
        }'))
    end

    it "sorting based on a direct association count in reverse order with secondary attribute in descending order" do
      @source_s4 = Source.create!(:tenant => tenant, :name => "source_s4", :source_type => source_typeR)

      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s4, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { applications: { __count: "desc" }, name: "desc" } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Catalog" },
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s4",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
              ]
            }
          ]
        }'))
    end

    it "sorting based on an association count in reverse order with secondary attribute in descending order" do
      @source_s4 = Source.create!(:tenant => tenant, :name => "source_s4", :source_type => source_typeR)

      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s4, :tenant => tenant)

      post(graphql_endpoint, :headers => headers, :params => {"query" => '
        {
          sources(filter: { name: { starts_with: "source_s"}}, sort_by: { application_types: { __count: "desc" }, name: "desc" } ) {
            name
            application_types {
              display_name
            }
          }
        }'})

      expect(response.status).to eq(200)
      expect(response.parsed_body["data"]).to eq(JSON.parse('
        {
          "sources": [
            {
              "name": "source_s2",
              "application_types": [
                { "display_name": "Catalog" },
                { "display_name": "Cost Management" },
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s4",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s3",
              "application_types": [
                { "display_name": "Topological Inventory" }
              ]
            },
            {
              "name": "source_s1",
              "application_types": [
              ]
            }
          ]
        }'))
    end
  end
end
