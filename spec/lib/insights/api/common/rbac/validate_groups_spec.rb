describe Insights::API::Common::RBAC::ValidateGroups do
  let(:meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
  let(:groups) { RBACApiClient::GroupPagination.new(:meta => meta, :links => nil, :data => [group_out]) }
  let(:group_out) { RBACApiClient::GroupOut.new(:name => "group1", :uuid => "123") }
  let(:group_uuids) { SortedSet.new(["123"]) }
  let(:request_url) { "http://rbac/api/rbac/v1/groups/?limit=10&offset=0&uuid=123" }

  subject { described_class.new(group_uuids) }

  before do
    stub_const("ENV", "RBAC_URL" => "http://rbac")
    stub_request(:get, request_url)
      .to_return(
        :status  => 200,
        :body    => groups.to_json,
        :headers => default_headers
      )

    allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(rbac_enabled?)
  end

  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  describe "#process" do
    context "when rbac is enabled" do
      let(:rbac_enabled?) { true }

      context "when there are group uuids missing" do
        let(:group_uuids) { SortedSet.new(["123", "456"]) }
        let(:request_url) { "http://rbac/api/rbac/v1/groups/?limit=10&offset=0&uuid=123,456" }

        it "throws an error" do
          expect { subject.process }.to raise_error(
            Insights::API::Common::InvalidParameter,
            /group uuids are missing 456/
          )
        end
      end

      context "when there are not group uuids missing" do
        it "validates the groups without an error" do
          subject.process
          expect(a_request(:get, request_url)).to have_been_made
        end

        it "returns nil" do
          expect(subject.process).to eq(nil)
        end
      end
    end

    context "when rbac is not enabled" do
      let(:rbac_enabled?) { false }

      it "does not validate the groups" do
        subject.process
        expect(a_request(:get, request_url)).not_to have_been_made
      end

      it "returns nil" do
        expect(subject.process).to eq(nil)
      end
    end
  end
end
