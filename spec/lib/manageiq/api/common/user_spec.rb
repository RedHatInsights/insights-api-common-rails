describe ManageIQ::API::Common::User do
  let(:encoded) { { "x-rh-identity" => encoded_user_hash } }
  let(:header_good) { ActionDispatch::Http::Headers.new(encoded) }
  let(:header_bad)  { ActionDispatch::Http::Headers.new({:blah => "blah" }) }

  context "with_logged_in_user" do

    it "sets if the user is valid" do
      ManageIQ::API::Common::User.with_logged_in_user(header_good) do |user|
        expect(user.first_name).to eq "John"
        expect(user.last_name).to eq "Doe"
        expect(user.email).to eq "jdoe@acme.com"
      end
    end

    it "raises an exception if the user hash is invalid" do
      expect { ManageIQ::API::Common::User.with_logged_in_user(header_bad) { |x| x.username } }.to raise_exception(StandardError)
    end
  end

  context "decode Base64 encoded header" do
    it "returns a hash of the entire identity" do
      ManageIQ::API::Common::User.with_logged_in_user(header_good) do |user|
        expect(user.send(:decode)).to be_a(Hash)
        expect(user.send(:decode).fetch('identity')).to be_truthy
      end
    end
  end

  context "setting ManageIQ::API::Common::User.current" do
    it "sets key Thread.current[:attr_current_user] " do
      ManageIQ::API::Common::User.current = header_good
      expect(Thread.current[:attr_current_user]).to be_a(ManageIQ::API::Common::User)
      expect(ManageIQ::API::Common::User.current.username).to eq "jdoe"
    end

    it "raises an exception if a method doesn't exist" do
      ManageIQ::API::Common::User.current = header_bad
      expect(Thread.current[:attr_current_user]).to be_a(ManageIQ::API::Common::User)
      expect { ManageIQ::API::Common::User.current.username }.to raise_exception(ArgumentError)
    end
  end

  context "setting a different user" do
    let(:other_user) { default_user_hash }

    it "decodes another user if one is passed in" do
      other_user["identity"]["user"].merge!({ "first_name" => "Fred", "email" => "fdoe@acme.com"})
      encoded_two = { "x-rh-identity" => encoded_user_hash(other_user) }

      ManageIQ::API::Common::User.with_logged_in_user(encoded_two) do |user_two|
        expect(user_two.first_name).to eq "Fred"
        expect(user_two.last_name).to eq "Doe"
        expect(user_two.email).to eq "fdoe@acme.com"
      end
    end
  end

  context "user methods" do
    before do
      ManageIQ::API::Common::Headers.current = header_good
      ManageIQ::API::Common::User.current = ManageIQ::API::Common::Headers.current
    end

    let(:user_keys)   { %w(username email first_name last_name is_active? is_org_admin? is_internal? locale) }
    let(:user_values) { ['jdoe', 'jdoe@acme.com', 'John', 'Doe', true, false, false, 'en_US'] }
    let(:bad_user)    { %w(fred barney type) }
    let(:user)        { ManageIQ::API::Common::User.current }
    let(:other_user)  { default_user_hash }

    it "returns values for user methods" do
      user_keys.each do |key|
        expect(user.respond_to?(key)).to be_truthy
      end
    end

    it "raises an exception for keys that do not exist" do
      bad_user.each do |key|
        expect(user.respond_to?(key)).to be_falsey
      end
    end

    it "applies the values associated to each key in the hash" do
      user_keys.each_with_index do |key, index|
        expect(user.send(key)).to eq user_values[index]
      end
    end

    it "raises an exception when a user method does not respond" do
      other_user.delete('lastname')
      ManageIQ::API::Common::User.current = other_user
      expect { ManageIQ::API::Common::User.current.lastname }.to raise_exception(StandardError)
    end
  end
end
