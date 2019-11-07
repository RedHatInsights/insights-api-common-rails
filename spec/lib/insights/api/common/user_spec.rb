describe Insights::API::Common::User do
  let(:encoded) { encoded_user_hash }
  let(:request_bad) { { :headers => {:blah => 'blah' }, :original_url => 'whatever' } }
  let(:request_good) do
    { :headers => { 'x-rh-identity' => encoded }, :original_url => 'whatever' }
  end

  around do |example|
    Insights::API::Common::Request.with_request(request_good) { example.call }
  end

  it "raises an exception if Request.current is not set" do
    Insights::API::Common::Request.current = nil
    expect { Insights::API::Common::Request.current.user.username }.to raise_exception(NoMethodError)
  end

  context "user getter methods" do
    let(:user_keys)   { %w(username email first_name last_name active? org_admin? internal? locale tenant) }
    let(:user_values) { ['jdoe', 'jdoe@acme.com', 'John', 'Doe', true, false, false, 'en_US', '0369233'] }
    let(:bad_user)    { %w(fred barney type) }
    let(:user)        { Insights::API::Common::Request.current.user }
    let(:other_user)  { default_user_hash }

    it "returns values for user methods" do
      user_keys.each do |key|
        expect(user.respond_to?(key)).to be_truthy
      end
    end

    it "raises an exception for keys that do not exist" do
      bad_user.each do |key|
        expect { user.send(key) }.to raise_exception(NoMethodError)
      end
    end

    it "applies the values associated to each key in the hash" do
      user_keys.each_with_index do |key, index|
        expect(user.send(key)).to eq user_values[index]
      end
    end
  end
end

describe Insights::API::Common::User do
  let(:other_user)  { default_user_hash }
  let(:request_bad) do
    other_user['identity']['user'].delete('last_name')
    { :headers => { 'x-rh-identity' => encoded_user_hash(other_user) }, :original_url => 'whatever' }
  end

  around do |example|
    Insights::API::Common::Request.with_request(request_bad) { example.call }
  end

  context "user bad hash" do
    it "raises an exception when a user method does not respond" do
      expect { Insights::API::Common::Request.current.user.last_name }.to raise_exception(Insights::API::Common::IdentityError)
    end
  end
end
