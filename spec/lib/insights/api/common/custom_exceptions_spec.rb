describe Insights::API::Common::CustomExceptions do
  describe ".custom_message with Pundit::NotAuthorizedError exception" do
    let(:record) { SourceType.new }
    let(:exception) { double(:class => "Pundit::NotAuthorizedError", :query => query, :record => record, :policy => policy) }

    context "when a custom error message exists on the policy" do
      let(:query) { "create?" }
      let(:policy) { double(:error_message => "This custom error message says 'no', you can't do that") }

      it "returns a customized message" do
        expect(Insights::API::Common::CustomExceptions.custom_message(exception)).to eq(
          "This custom error message says 'no', you can't do that"
        )
      end
    end

    context "when a custom error message does not exist on the policy" do
      let(:policy) { nil }

      shared_examples_for "#test_message" do
        it "returns a customized message" do
          expect(Insights::API::Common::CustomExceptions.custom_message(exception)).to eq(
            "You are not authorized to perform the create action for this source type"
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
end
