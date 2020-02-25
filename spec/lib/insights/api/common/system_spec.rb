describe Insights::API::Common::User do
  let(:encoded) { encoded_system_hash }
  let(:request_bad) { { :headers => {:blah => 'blah' }, :original_url => 'whatever' } }
  let(:request_good) do
    { :headers => { 'x-rh-identity' => encoded }, :original_url => 'whatever' }
  end

  around do |example|
    Insights::API::Common::Request.with_request(request_good) { example.call }
  end

  it "raises an exception if Request.current is not set" do
    Insights::API::Common::Request.current = nil
    expect { Insights::API::Common::Request.current.system.cn }.to raise_exception(NoMethodError)
  end

  context "system getter methods" do
    let(:system)      { Insights::API::Common::Request.current.system }

    it "#cn" do
      expect(system.cn).to eq(default_system_cn)
    end

    it "raises an exception for keys that do not exist" do
      expect { system.username }.to raise_exception(NoMethodError)
    end
  end
end
