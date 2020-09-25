describe Insights::API::Common::CustomExceptions do
  describe ".custom_message with Pundit::NotAuthorizedError exception" do
    let(:record) { SourceType.new }
    let(:exception) { double(:class => "Pundit::NotAuthorizedError", :query => query, :record => record) }

    shared_examples_for "#test_message" do
      it "returns a customized message" do
        expect(Insights::API::Common::CustomExceptions.custom_message(exception)).to eq(
          "You are not authorized to create this source type"
        )
      end
    end

    context "when the query is String" do
      let(:query) { "create?" }

      it_behaves_like "#test_message"
    end

    context "when the query is Symbol" do
      let(:query) { :create? }

      it_behaves_like "#test_message"
    end
  end
end
