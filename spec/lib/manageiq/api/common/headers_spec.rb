describe ManageIQ::API::Common::Headers do
  let(:header_good) { ActionDispatch::Http::Headers.new({:blah => 'blah'}) }
  let(:header_bad)  { {:blah => 'blah' } }
  # Encoded string: { 'identity' => { 'is_org_admin':true, 'org_id':111 } }
  let(:encoded_key) { { 'x-rh-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWUsIm9yZ19pZCI6MTExfX0=' } }
  context "set current headers" do
    it 'sets if the class is correct' do
      expect(ManageIQ::API::Common::Headers.current = header_good).to be_a(ActionDispatch::Http::Headers)
    end

    it 'raises an exception if the class is incorrect' do
      expect { ManageIQ::API::Common::Headers.current = header_bad }.to raise_exception(StandardError)
    end
  end

  describe "#{described_class}#decode" do
    it "returns a hash representation of a Base64 encoded key" do
      header = ActionDispatch::Http::Headers.new(encoded_key)
      identity = described_class.decode(header, 'x-rh-identity')
      expect(identity).to be_a Hash
      expect(identity['identity']['is_org_admin']).to be_truthy
    end
  end

  describe "#{described_class}#encode" do
    it "returns a Base64 representation of a hash key" do
      headers = { 'x-auth-identity' => { 'identity' => { 'is_org_admin' => false } } }
      encoded = described_class.encode(headers, 'x-auth-identity')
      expect(encoded).to be_a String
      expect(encoded).to eq "eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0="
    end
  end
end
