RSpec.describe("Serializing ApplicationRecord instances to JSON") do
  context "Encrypted attributes are not in the JSON response" do
    let(:base_class) { Class.new.tap { |c| c.prepend(OpenApi::Serializer) } }

    it "on a model that has encrypted columns" do
      model = Class.new(base_class) do
        def self.encrypted_columns
          ["secret"]
        end

        def to_hash
          {"a" => 1, "b" => 2, "secret" => "value"}
        end
      end

      expect(model.new.as_json).to eq("a" => 1, "b" => 2)
    end

    it "on a model that has encrypted columns" do
      model = Class.new(base_class) do
        def to_hash
          {"a" => 1, "b" => 2, "secret" => "value"}
        end
      end

      expect(model.new.as_json).to eq("a" => 1, "b" => 2, "secret" => "value")
    end
  end
end
