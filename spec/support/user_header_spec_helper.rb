module UserHeaderSpecHelper
  DEFAULT_USER = {
    "identity" => {
      "account_number" => "0369233",
      "type"           => "User",
      "user"     =>  {
        "username"     => "jdoe",
        "email"        => "jdoe@acme.com",
        "first_name"   => "John",
        "last_name"    => "Doe",
        "is_active"    => true,
        "is_org_admin" => false,
        "is_internal"  => false,
        "locale"       => "en_US"
      },
      "internal" => {
        "org_id"    => "3340851",
        "auth_type" => "basic-auth",
        "auth_time" => 6300
      }
    }
  }.freeze

  def default_account_number
    default_user_hash["identity"]["account_number"]
  end

  def encode(val)
    if val.kind_of?(Hash)
      hashed = val.stringify_keys
      Base64.strict_encode64(hashed.to_json)
    else
      raise StandardError, "Must be a Hash"
    end
  end

  def encoded_user_hash(hash = nil)
    encode(hash || DEFAULT_USER)
  end

  def default_user_hash
    Marshal.load(Marshal.dump(DEFAULT_USER))
  end
end
