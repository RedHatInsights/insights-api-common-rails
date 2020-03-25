describe Insights::API::Common::Filter do
  let(:this) { described_class }

  context "compact_filter method" do
    it "compacts association filter specifications of string" do
      parameters  = {"association" => {"attribute" => "value"}}
      expectation = {"association.attribute" => "value"}

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "compacts association filter specifications of array" do
      parameters  = {"association" => {"attribute" => {"eq" => ["value1", "value2"]}}}
      expectation = {"association.attribute" => {"eq" => ["value1", "value2"]}}

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "does not compact filter if filter hash key is a string operator" do
      parameters  = {"attribute" => {"eq" => ["value1", "value2"]}}
      expectation = {"attribute" => {"eq" => ["value1", "value2"]}}

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "does not compact filter if filter hash key is an integer operator" do
      parameters  = {"attribute" => {"lt" => 5}}
      expectation = {"attribute" => {"lt" => 5}}

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "does not compact filter if filter has multiple keys with integer or string operators" do
      parameters  = {"id" => {"gt"=>"3"}, "name" => {"starts_with"=>"test"}}
      expectation = {"id" => {"gt"=>"3"}, "name" => {"starts_with"=>"test"}}

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "compacts only association attributes in a compound filter hash" do
      parameters = {
        "id"           => {"gt" => "3"},
        "name"         => {"starts_with" => "test"},
        "source_types" => {"name" => {"eq" => "redhat"}}
      }
      expectation = {
        "id"                => {"gt" => "3"},
        "name"              => {"starts_with" => "test"},
        "source_types.name" => {"eq" => "redhat"},
      }

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end

    it "compacts multiple association attributes in a compund filter hash" do
      parameters = {
        "id"           => {"gt" => "3"},
        "name"         => {"starts_with" => "test"},
        "source_types" => {
          "name" => {"eq" => "redhat"},
          "id"   => {"eq" => ["3", "6", "9"]}
        }
      }
      expectation = {
        "id"                => {"gt" => "3"},
        "name"              => {"starts_with" => "test"},
        "source_types.name" => {"eq" => "redhat"},
        "source_types.id"   => {"eq" => ["3", "6", "9"]}
      }

      expect(this.public_send(:compact_filter, parameters)).to(eq(expectation))
    end
  end
end
