describe ManageIQ::API::Common::Entitlement do
  let(:encoded) { encoded_user_hash }
  let(:request_good) do
    { :headers => { 'x-rh-identity' => encoded }, :original_url => 'whatever' }
  end

  around do |example|
    ManageIQ::API::Common::Request.with_request(request_good) { example.call }
  end

  context "entitlement getter methods" do
    let(:entitlement_keys) { %w[insights openshift hybrid_cloud smart_management ansible migrations] }
    let(:bad_entitlement)  { %w[fred barney type] }
    let(:entitlement)      { ManageIQ::API::Common::Request.current.entitlement }
    let(:other_user)       { default_user_hash }

    it "returns values for entitlement methods" do
      entitlement_keys.each do |key|
        expect(entitlement.respond_to?("#{key}?")).to be_truthy
      end
    end

    it "raises an exception for keys that do not exist" do
      bad_entitlement.each do |key|
        expect { entitlement.send("#{key}?") }.to raise_exception(NoMethodError)
      end
    end
  end
end
