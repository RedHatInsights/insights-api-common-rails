# Encoded Identity header user keys/values
#{
#  "identity": {
#    "account_number": "0369233",
#    "type": "User",
#    "user" : {
#      "username": "jdoe",
#      "email": "jdoe@acme.com",
#      "first_name": "John",
#      "last_name": "Doe",
#      "is_active": true,
#      "is_org_admin": false,
#      "is_internal": false,
#      "locale": "en_US"
#    },
#    "internal" : {
#      "org_id": "3340851",
#      "auth_type": "basic-auth",
#      "auth_time": 6300
#     }
#  }
describe ManageIQ::API::Common::User do
  let(:encoded) { {"x-rh-identity"=>"eyJpZGVudGl0eSI6eyJhY2NvdW50X251bWJlciI6IjAzNjkyMzMiLCJ0eXBlIjoiVXNlciIsInVzZXIiOnsidXNlcm5hbWUiOiJqZG9lIiwiZW1haWwiOiJqZG9lQGFjbWUuY29tIiwiZmlyc3RfbmFtZSI6IkpvaG4iLCJsYXN0X25hbWUiOiJEb2UiLCJpc19hY3RpdmUiOnRydWUsImlzX29yZ19hZG1pbiI6ZmFsc2UsImlzX2ludGVybmFsIjpmYWxzZSwibG9jYWxlIjoiZW5fVVMifSwiaW50ZXJuYWwiOnsib3JnX2lkIjoiMzM0MDg1MSIsImF1dGhfdHlwZSI6ImJhc2ljLWF1dGgiLCJhdXRoX3RpbWUiOjYzMDB9fX0="} }
  let(:header_good) { ActionDispatch::Http::Headers.new(encoded) }
  let(:header_bad)  { ActionDispatch::Http::Headers.new({:blah => "blah" }) }

  context "set current user" do

    it "sets if the user is valid" do
      ManageIQ::API::Common::Headers.current = header_good
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        expect(user.first_name).to eq "John"
        expect(user.last_name).to eq "Doe"
        expect(user.email).to eq "jdoe@acme.com"
      end
    end

    it "raises an exception if the user is invalid" do
      ManageIQ::API::Common::Headers.current = header_bad
      expect { ManageIQ::API::Common::User.with_logged_in_user { |_x| } }.to raise_exception(StandardError)
    end

    it "raises an exception if current header is invalid" do
      Thread.current[:attr_current_headers] = nil
      expect { ManageIQ::API::Common::User.with_logged_in_user  { |_x| }}.to raise_exception(StandardError)
    end
  end

  context "decode Base64 encoded header" do
    before { ManageIQ::API::Common::Headers.current = header_good }

    it "returns a hash of the entire identity" do
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        expect(user.send(:decode)).to be_a(Hash)
        expect(user.send(:decode).fetch('identity')).to be_truthy
      end
    end
  end

  context "setting Thread.current[:attr_current_user]" do
    before { ManageIQ::API::Common::Headers.current = header_good }
    it "sets key [:attr_current_user] while inside the block" do
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        expect(Thread.current[:attr_current_user]).to be_a(ManageIQ::API::Common::User)
      end
    end

    it "nils key [:attr_current_user] after executing inside the block" do
      ManageIQ::API::Common::User.with_logged_in_user { |user| }
      expect(Thread.current[:attr_current_user]).to be_nil
    end
  end

  context "setting a different user" do
    let(:encoded_two) { {"x-rh-identity"=>"eyJpZGVudGl0eSI6eyJhY2NvdW50X251bWJlciI6IjIyMjIyIiwidHlwZSI6IlVzZXIiLCJ1c2VyIjp7InVzZXJuYW1lIjoiZnJlZGRvZSIsImVtYWlsIjoiZmRvZUBhY21lLmNvbSIsImZpcnN0X25hbWUiOiJGcmVkIiwibGFzdF9uYW1lIjoiRG9lIiwiaXNfYWN0aXZlIjp0cnVlLCJpc19vcmdfYWRtaW4iOmZhbHNlLCJpc19pbnRlcm5hbCI6ZmFsc2UsImxvY2FsZSI6ImVuX1VTIn0sImludGVybmFsIjp7Im9yZ19pZCI6Ijk5OTk5IiwiYXV0aF90eXBlIjoiYmFzaWMtYXV0aCIsImF1dGhfdGltZSI6NjMwMH19fQ==" } }
    before { ManageIQ::API::Common::Headers.current = header_good }

    it "decodes another user if one is passed in" do
      ManageIQ::API::Common::User.with_logged_in_user(encoded_two) do |user_two|
        expect(user_two.first_name).to eq "Fred"
        expect(user_two.last_name).to eq "Doe"
        expect(user_two.email).to eq "fdoe@acme.com"
      end
    end
  end

  context "user methods" do
    before { ManageIQ::API::Common::Headers.current = header_good }

    let(:user_keys)   { %w(account_number username email first_name last_name is_active is_org_admin is_internal locale org_id auth_type auth_time) }
    let(:user_values) { ['0369233', 'jdoe', 'jdoe@acme.com', 'John', 'Doe', true, false, false, 'en_US', '3340851', 'basic-auth', 6300] }
    let(:bad_user)    { %w(fred barney type) }

    it "dynamically assigns getters for user header Hash keys" do
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        user_keys.each do |key|
          expect(user.respond_to?(key)).to be_truthy
        end
      end
    end

    it "raises an exception for keys that do not exist" do
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        bad_user.each do |key|
          expect(user.respond_to?(key)).to be_falsey
        end
      end
    end

    it "applies the values associated to each key in the hash" do
      ManageIQ::API::Common::User.with_logged_in_user do |user|
        user_keys.each_with_index do |key, index|
          expect(user.send(key)).to eq user_values[index]
        end
      end
    end
  end
end
