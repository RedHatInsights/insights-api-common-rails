describe Insights::API::Common::OpenApi::Serializer do
  describe "#as_json" do
    class TestSourceType < SourceType
      include Insights::API::Common::OpenApi::Serializer

      def self.presentation_name
        "SourceType"
      end

      attribute :expensive_computation

      def expensive_computation
        "1"
      end
    end

    class SourceTypeEncrypted < TestSourceType
      def self.encrypted_columns
        ["vendor"]
      end
    end

    context "when there are arguments passed through" do
      context "when the arguments contain the prefixes key" do
        let(:args) { {:prefixes => ["api/#{version}/", "application"]} }
        let(:time) { Time.now }

        context "when the version is 1.0" do
          let(:version) { "v1.0" }

          context "when the class does not have encrypted columns" do
            let(:model) { TestSourceType.new(:updated_at => time, :vendor => "test") }

            it "does not attempt to include attributes not in the api doc" do
              expect(model).not_to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["updated_at", "vendor"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["vendor"]).to eq("test")
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { SourceTypeEncrypted.new(:updated_at => time, :vendor => "test") }

            it "does not attempt to include attributes not in the api doc" do
              expect(model).not_to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["updated_at"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
            end
          end
        end

        context "when the version is 2.0" do
          let(:version) { "v2.0" }

          context "when the class does not have encrypted columns" do
            let(:model) { TestSourceType.new(:updated_at => time, :vendor => "test") }

            it "includes attributes in the api doc" do
              expect(model).to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["expensive_computation", "updated_at", "vendor"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["vendor"]).to eq("test")
              expect(result["expensive_computation"]).to eq("1")
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { SourceTypeEncrypted.new(:updated_at => time, :vendor => "test") }

            it "includes attributes in the api doc" do
              expect(model).to receive(:expensive_computation)
              model.as_json(args)
            end

            it "removes nil values, returns an iso date format, and stringifies ids" do
              result = model.as_json(args)
              expect(result.keys).to match_array(["expensive_computation", "updated_at"])
              expect(result["updated_at"].to_i).to eq(time.iso8601.to_i)
              expect(result["expensive_computation"]).to eq("1")
            end
          end
        end

        context "when the arugments do not contain the prefixes key" do
          let(:args) { {:template => "show"} }

          context "when the class does not have encrypted columns" do
            let(:model) { TestSourceType.new }

            it "returns all attributes" do
              expect(model.as_json(args)).to eq(
                "created_at"            => nil,
                "expensive_computation" => "1",
                "id"                    => nil,
                "name"                  => nil,
                "product_name"          => nil,
                "vendor"                => nil,
                "updated_at"            => nil,
                "schema"                => nil
              )
            end
          end

          context "when the class has encrypted columns" do
            let(:model) { SourceTypeEncrypted.new }

            it "returns all attributes except the encrypted ones" do
              expect(model.as_json(args)).to eq(
                "created_at"            => nil,
                "expensive_computation" => "1",
                "id"                    => nil,
                "name"                  => nil,
                "product_name"          => nil,
                "updated_at"            => nil,
                "schema"                => nil
              )
            end
          end
        end
      end
    end

    context "when there are no arguments passed through" do
      context "when the class does not have encrypted columns" do
        let(:model) { TestSourceType.new }

        it "returns all attributes" do
          expect(model.as_json).to eq(
            "created_at"            => nil,
            "expensive_computation" => "1",
            "id"                    => nil,
            "name"                  => nil,
            "product_name"          => nil,
            "vendor"                => nil,
            "updated_at"            => nil,
            "schema"                => nil
          )
        end
      end

      context "when the class has encrypted columns" do
        let(:model) { SourceTypeEncrypted.new }

        it "returns all attributes except the encrypted ones" do
          expect(model.as_json).to eq(
            "created_at"            => nil,
            "expensive_computation" => "1",
            "id"                    => nil,
            "name"                  => nil,
            "product_name"          => nil,
            "updated_at"            => nil,
            "schema"                => nil
          )
        end
      end
    end
  end
end
