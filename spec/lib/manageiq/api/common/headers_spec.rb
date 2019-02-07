describe ManageIQ::API::Common::Headers do
  let(:header_good) do
    ActionDispatch::Http::Headers.from_hash(:blah           => 'blah',
                                            'x-rh-identity' => 'abc')
  end
  let(:header_bad) { {:blah => 'blah' } }

  context "set current headers" do
    it 'sets if the class is correct' do
      described_class.with_headers(header_good) do |instance|
        expect(instance).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'raises an exception if the class is incorrect' do
      expect do
        described_class.with_headers(header_bad) {}
      end.to raise_exception(ArgumentError)
    end
  end

  context "get forwardable headers" do
    it "x-rh-identity" do
      described_class.with_headers(header_good) do
        hash = described_class.current_forwardable
        expect(hash).to eq('x-rh-identity' => 'abc')
      end
    end

    it "raises exception when headers not set" do
      expect do
        described_class.current_forwardable
      end.to raise_exception(ManageIQ::API::Common::HeadersNotSet)
    end
  end

  context "Base64 encoding" do
    it 'returns a Base64 representation of a hash' do
      headers = { 'x-rh-auth-identity' => { 'identity' => { 'is_org_admin' => false } } }

      encoded = described_class.encode(headers['x-rh-auth-identity'])
      expect(encoded).to be_a String
      expect(encoded).to eq "eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0="
    end
  end
end
