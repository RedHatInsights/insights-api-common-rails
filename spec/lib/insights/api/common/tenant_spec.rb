describe Insights::API::Common::Tenant do
  let(:encoded)     { encoded_user_hash }
  let(:request_bad) { { :headers => {:blah => 'blah' }, :original_url => 'whatever' } }
  let(:request_good) do
    { :headers => { 'x-rh-identity' => encoded }, :original_url => 'whatever' }
  end

  around do |example|
    Insights::API::Common::Request.with_request(request_good) { example.call }
  end

  it "raises an exception if Request.current is not set" do
    Insights::API::Common::Request.current = nil
    expect { Insights::API::Common::Request.current.tenant }.to raise_exception(NoMethodError)
  end

  context "tenant getter methods" do
    let(:tenant)        { Insights::API::Common::Request.current.tenant }

    it "#tenant" do
      expect(tenant).to eq(default_account_number)
    end
  end
end
