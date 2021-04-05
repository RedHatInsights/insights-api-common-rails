require "insights/api/common/graphql"

RSpec.describe Insights::API::Common::GraphQL::Generator do
  let!(:graphql_endpoint)    { "/api/v1.0/graphql" }
  let!(:graphql_endpoint_v2) { "/api/v2.0/graphql" }

  let!(:source_typeR) { SourceType.create(:name => "rhev_test", :product_name => "RedHat Virtualization", :vendor => "redhat") }
  let!(:source_typeO) { SourceType.create(:name => "openshift_test", :product_name => "RedHat OpenShift", :vendor => "redhat") }
  let!(:source_typeV) { SourceType.create(:name => "vmware_test", :product_name => "VmWare vCenter", :vendor => "vmware") }

  context "schema overlays" do
    before { ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V1x0") if ::Insights::API::Common::GraphQL::Api.const_defined?("V1x0", false) }
    after  { ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V1x0") }

    it "support base_query" do
      graphql_request = double
      allow(graphql_request).to receive(:original_url).and_return(graphql_endpoint)

      schema_overlay = {
        "^source_types$" => {
          "base_query" => lambda do |model_class, _args, _ctx|
            model_class.where(:vendor => "redhat")
          end
        }
      }

      graphql_query = '
        {
          source_types(sort_by: "name:asc") {
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
              "name": "openshift_test",
              "vendor": "redhat"
            },
            {
              "name": "rhev_test",
              "vendor": "redhat"
            }
          ]
        }'))
    end
  end

  context "schema overlays v2" do
    let(:graphql_schema) do
      <<~RUBY
        Schema = ::GraphQL::Schema.define do
          use ::GraphQL::Batch
          enable_preloading
          disable_introspection_entry_points

          query QueryType
        end
      RUBY
    end

    let(:application_name)                   { Rails.application.class.parent.name.underscore }
    let(:root_dir)                           { Dir.mktmpdir("root_dir") }
    let(:graphql_schema_pluggable)           { "#{root_dir}/lib/#{application_name}/api/graphql/templates" }
    let(:graphql_schema_pluggable_directory) { Pathname.new(graphql_schema_pluggable) }
    let(:schema_path)                        { graphql_schema_pluggable_directory.join("schema.erb") }

    %i[enabled_introspection disabled_introspection].each do |introspection|
      context "Introspection settings: #{introspection}" do
        before do
          ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V2x0") if ::Insights::API::Common::GraphQL::Api.const_defined?("V2x0", false)

          if introspection == :disabled_introspection
            allow(described_class).to receive(:root_dir).and_return(root_dir)
            FileUtils.mkpath(graphql_schema_pluggable_directory)
            File.write(schema_path, graphql_schema)
          end
        end

        after do
          ::Insights::API::Common::GraphQL::Api.send(:remove_const, "V2x0")

          FileUtils.rm_r(schema_path) if introspection == :disabled_introspection
        end

        it "support base_query" do
          graphql_request = double
          allow(graphql_request).to receive(:original_url).and_return(graphql_endpoint_v2)

          schema_overlay = {
            "^source_types$" => {
              "base_query" => lambda do |model_class, _args, _ctx|
                model_class.where(:vendor => "redhat")
              end
            }
          }

          graphql_query = '
            {
              source_types(sort_by: { name: "asc" }) {
                name
                vendor
              }
            }
          '

          graphql_api_schema = described_class.init_schema_v2(graphql_request, schema_overlay)
          if introspection == :disabled_introspection
            expect(graphql_api_schema.disable_introspection_entry_points).to be_truthy
          else
            expect(graphql_api_schema.disable_introspection_entry_points).to be_falsey
          end

          result = graphql_api_schema.execute(graphql_query, :variables => {})
          expect(result["data"]).to eq(JSON.parse('
            {
              "source_types": [
                {
                  "name": "openshift_test",
                  "vendor": "redhat"
                },
                {
                  "name": "rhev_test",
                  "vendor": "redhat"
                }
              ]
            }'))
        end
      end
    end
  end
end
