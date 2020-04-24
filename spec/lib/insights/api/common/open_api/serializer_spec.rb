describe Insights::API::Common::OpenApi::Serializer do
  describe "#as_json" do
    class Endpoint < ApplicationRecord
      include Insights::API::Common::OpenApi::Serializer

      attribute :expensive_computation

      def expensive_computation
        "1"
      end
    end

    class EndpointEncrypted < Endpoint
      def self.presentation_name
        "Endpoint"
      end

      def self.encrypted_columns
        ["role"]
      end
    end

    context "when there are arguments passed through" do
      context "when the arguments contain the prefixes key" do
        let(:args) { {:prefixes => ["api/#{version}/", "application"]} }
        let(:time) { Time.now }

        context "when the version is 1.0" do
          let(:version) { "v1.0" }

          context "when the class does not have encrypted columns" do
            let(:model) { Endpoint.new(:updated_at => time, :source_id => 123, :role => "test") }

            it "does not attempt to include attributes not in the api doc" do
              expect(model).not_to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["default", "updated_at", "source_id", "role"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["source_id"]).to eq("123")
              expect(result["role"]).to eq("test")
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { EndpointEncrypted.new(:updated_at => time, :source_id => 123, :role => "test") }

            it "does not attempt to include attributes not in the api doc" do
              expect(model).not_to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["default", "updated_at", "source_id"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["source_id"]).to eq("123")
            end
          end
        end

        context "when the version is 2.0" do
          let(:version) { "v2.0" }

          context "when the class does not have encrypted columns" do
            let(:model) { Endpoint.new(:updated_at => time, :source_id => 123, :role => "test") }

            it "includes attributes in the api doc" do
              expect(model).to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["default", "expensive_computation", "updated_at", "source_id", "role"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["source_id"]).to eq("123")
              expect(result["role"]).to eq("test")
              expect(result["expensive_computation"]).to eq("1")
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { EndpointEncrypted.new(:updated_at => time, :source_id => 123, :role => "test") }

            it "includes attributes in the api doc" do
              expect(model).to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["default", "expensive_computation", "updated_at", "source_id"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["source_id"]).to eq("123")
              expect(result["expensive_computation"]).to eq("1")
            end
          end
        end

        context "when the arugments do not contain the prefixes key" do
          let(:args) { {:template => "show"} }

          context "when the class does not have encrypted columns" do
            let(:model) { Endpoint.new }

            it "returns all attributes" do
              expect(model.as_json(args)).to eq(
                "certificate_authority" => nil,
                "created_at"            => nil,
                "default"               => false,
                "expensive_computation" => "1",
                "host"                  => nil,
                "id"                    => nil,
                "path"                  => nil,
                "port"                  => nil,
                "role"                  => nil,
                "scheme"                => nil,
                "source_id"             => nil,
                "tenant_id"             => nil,
                "updated_at"            => nil,
                "verify_ssl"            => nil
              )
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { EndpointEncrypted.new }

            it "returns all attributes except the encrypted ones" do
              expect(model.as_json(args)).to eq(
                "certificate_authority" => nil,
                "created_at"            => nil,
                "default"               => false,
                "expensive_computation" => "1",
                "host"                  => nil,
                "id"                    => nil,
                "path"                  => nil,
                "port"                  => nil,
                "scheme"                => nil,
                "source_id"             => nil,
                "tenant_id"             => nil,
                "updated_at"            => nil,
                "verify_ssl"            => nil
              )
            end
          end
        end
      end
    end

    context "when there are no arguments passed through" do
      context "when the class does not have encrypted columns" do
        let(:model) { Endpoint.new }

        it "returns all attributes" do
          expect(model.as_json).to eq(
            "certificate_authority" => nil,
            "created_at"            => nil,
            "default"               => false,
            "expensive_computation" => "1",
            "host"                  => nil,
            "id"                    => nil,
            "path"                  => nil,
            "port"                  => nil,
            "role"                  => nil,
            "scheme"                => nil,
            "source_id"             => nil,
            "tenant_id"             => nil,
            "updated_at"            => nil,
            "verify_ssl"            => nil
          )
        end
      end

      context "when the class has encrypted columns" do
        let(:model) { EndpointEncrypted.new }

        it "returns all attributes except the encrypted ones" do
          expect(model.as_json).to eq(
            "certificate_authority" => nil,
            "created_at"            => nil,
            "default"               => false,
            "expensive_computation" => "1",
            "host"                  => nil,
            "id"                    => nil,
            "path"                  => nil,
            "port"                  => nil,
            "scheme"                => nil,
            "source_id"             => nil,
            "tenant_id"             => nil,
            "updated_at"            => nil,
            "verify_ssl"            => nil
          )
        end
      end
    end
  end
end
