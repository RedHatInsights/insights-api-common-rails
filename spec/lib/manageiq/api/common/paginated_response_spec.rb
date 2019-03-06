describe ManageIQ::API::Common::PaginatedResponse do
  context "values of limit" do
    it "unspecified defaults to 100" do
      expect(described_class.new(base_query: nil, request: nil).limit).to eq(100)
    end

    it "minimum is 1" do
      expect(described_class.new(base_query: nil, request: nil, limit: 0).limit).to eq(1)
    end

    it "maximum is 1000" do
      expect(described_class.new(base_query: nil, request: nil, limit: 1_000_000).limit).to eq(1_000)
    end
  end

  context "values of offset" do
    it "unspecified defaults to 0" do
      expect(described_class.new(base_query: nil, request: nil).offset).to eq(0)
    end

    it "minimum is 0" do
      expect(described_class.new(base_query: nil, request: nil, offset: -100).offset).to eq(0)
    end
  end

  context "metainformation" do
    let(:base_query) { double("AR:Clause", :count => count) }
    let(:request) { double("Request", :original_url => "http://example.com/resource?param1=true&limit=#{limit}") }
    let(:count) { 6 }
    let(:limit) { 2 }
    let(:offset) { 2 }

    context "contains correct count, limit and offset" do
      it "first page" do
        expect(described_class.new(base_query: base_query, request: request, limit: limit).send(:metadata_hash)).to eq(
          "count" => count, "limit" => limit, "offset" => 0
        )
      end

      it "second page" do
        expect(described_class.new(base_query: base_query, request: request, limit: limit, offset: offset).send(:metadata_hash)).to eq(
          "count" => count, "limit" => limit, "offset" => offset
        )
      end
    end
  end

  context "private links methods" do
    let(:base_query) { double("AR:Clause", :count => count) }
    let(:request) { double("Request", :original_url => "http://example.com/resource?param1=true&limit=#{limit}") }

    def url_with_offset(offset)
      "/resource?limit=#{limit}&offset=#{offset}&param1=true"
    end

    context "number of records evenly divisible by limit" do
      let(:count) { 6 }
      let(:limit) { 2 }
      let(:first_url) { url_with_offset(0) }
      let(:last_url)  { url_with_offset(4) }

      it "first page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 2).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "next" => url_with_offset(2)
        )
      end

      it "second page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 2, offset: 2).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "next" => url_with_offset(4), "prev" => first_url
        )
      end

      it "third page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 2, offset: 4).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "prev" => url_with_offset(2)
        )
      end
    end

    context "number of records not evenly divisible by limit" do
      let(:count) { 31 }
      let(:limit) { 10 }
      let(:first_url) { url_with_offset(0) }
      let(:last_url)  { url_with_offset(30) }

      it "first page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 10).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "next" => url_with_offset(10)
        )
      end

      it "second page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 10, offset: 10).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "next" => url_with_offset(20), "prev" => first_url
        )
      end

      it "third page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 10, offset: 20).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "next" => last_url, "prev" => url_with_offset(10)
        )
      end

      it "fourth page" do
        expect(described_class.new(base_query: base_query, request: request, limit: 10, offset: 30).send(:links_hash)).to eq(
          "first" => first_url, "last" => last_url, "prev" => url_with_offset(20)
        )
      end
    end
  end
end
