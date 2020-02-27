require "insights/api/common/graphql"

RSpec.describe Insights::API::Common::GraphQL::Generator do
  let!(:graphql_endpoint) { "/api/v2.0/graphql" }

  let!(:source_typeR) { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:source_typeV) { SourceType.create(:name => "vmware", :product_name => "VmWare vCenter", :vendor => "vmware") }

  context "schema overlays" do
    before { ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V2x0") if ::Insights::API::Common::GraphQL::Api.const_defined?("V2x0", false) }
    after  { ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V2x0") }

    it "support base_query" do
      graphql_request = double
      allow(graphql_request).to receive(:original_url).and_return(graphql_endpoint)

      schema_overlay = {
        "^source_types$" => {
          "base_query" => lambda do |model_class, _ctx|
            model_class.where(:vendor => "redhat")
          end
        }
      }

      graphql_query = '
        {
          source_types {
            name
            vendor
          }
        }
      '

      graphql_api_schema = described_class.init_schema(graphql_request, schema_overlay)
      result = graphql_api_schema.execute(graphql_query, :variables => {})

      expect(result["data"]).to eq(JSON.parse('
        {
          "source_types": [
            {
              "name": "rhev",
              "vendor": "redhat"
            }
          ]
        }'))
    end
  end
end
