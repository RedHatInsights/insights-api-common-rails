describe Insights::API::Common::PaginatedResponseV2 do
  context "compact_parameter method" do
    let(:base_query) { double("AR:Clause", :count => 100) }
    let(:request)    { double("Request", :original_url => "http://example.com/api/v2.0/graphql") }
    let(:this)       { described_class.new(:base_query => base_query, :request => request) }

    it "supports compound attribute specifications" do
      parameters  = {"association" => {"attribute" => "value"}, "direct_attribute" => "value2"}
      expectation = [["association.attribute", "value"], ["direct_attribute", "value2"]]

      expect(this.public_send(:compact_parameter, parameters)).to(eq(expectation))
    end

    it "supports multiple association specifications" do
      parameters  = {"association" => {"attribute" => "value"}, "association2" => {"attribute2" => "value2"}}
      expectation = [["association.attribute", "value"], ["association2.attribute2", "value2"]]

      expect(this.public_send(:compact_parameter, parameters)).to(eq(expectation))
    end

    it "supports association specification with multiple attributes" do
      parameters  = {"association" => {"attribute1" => "value1", "attribute2" => "value2"}}
      expectation = [["association.attribute1", "value1"], ["association.attribute2", "value2"]]

      expect(this.public_send(:compact_parameter, parameters)).to(eq(expectation))
    end

    it "supports compound multiple association specifications" do
      parameters = {
        "association"      => {"attribute1" => "value1", "attribute2" => "value2"},
        "direct_attribute" => "value3",
        "association2"     => {"attribute4" => "value4", "attribute5" => "value5"}
      }
      expectation = [
        ["association.attribute1", "value1"], ["association.attribute2", "value2"],
        ["direct_attribute", "value3"],
        ["association2.attribute4", "value4"], ["association2.attribute5", "value5"]
      ]

      expect(this.public_send(:compact_parameter, parameters)).to(eq(expectation))
    end
  end
end
