describe ManageIQ::API::Common::Request do
  let(:request_good) do
    headers = ActionDispatch::Http::Headers.from_hash({})
    ActionDispatch::Request.new(headers)
  end

  let(:request_hash) do
    { :headers => {'x-rh-identity' => encoded_user_hash}, :original_url => '' }
  end

  let(:request_bad) { { :headers => {:blah => 'blah' }, :original_url => 'whatever' } }
  let(:random_str)  { rand(10.000).to_s }

  context "user" do
    it "returns a lazy loaded user instance" do
      described_class.with_request(request_good) do |instance|
        expect(instance.user).to be_a(ManageIQ::API::Common::User)
      end
    end

    it 'returns a lazy loaded user instance with a correctly formatted Hash' do
      described_class.with_request(request_hash) do |instance|
        expect(instance).to be_a(ManageIQ::API::Common::Request)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end
  end

  context "set current headers" do
    it 'sets if the class is correct' do
      described_class.with_request(request_good) do |instance|
        expect(instance).to be_a(ManageIQ::API::Common::Request)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'sets if the class is a correctly formatted Hash' do
      described_class.with_request(request_hash) do |instance|
        expect(instance).to be_a(ManageIQ::API::Common::Request)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'raises an exception if the class is incorrect' do
      expect do
        described_class.with_request(random_str) {}
      end.to raise_exception(ArgumentError)
    end
  end

  describe ".current_forwardable" do
    it "x-rh-identity" do
      described_class.with_request(request_hash) do
        hash = described_class.current_forwardable
        expect(hash).to eq('x-rh-identity' => encoded_user_hash)
      end
    end

    it "raises exception when headers not set" do
      ManageIQ::API::Common::Request.current = nil
      expect do
        described_class.current_forwardable
      end.to raise_exception(ManageIQ::API::Common::HeadersNotSet)
    end
  end

  describe ".to_h" do
    it "contains header and original_url" do
      described_class.with_request(request_hash) do
        hash = described_class.current.to_h
        expect(hash).to eq(:headers => {'x-rh-identity' => encoded_user_hash}, :original_url => "")
      end
    end
  end
end
