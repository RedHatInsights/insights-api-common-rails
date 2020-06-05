describe Insights::API::Common::CustomExceptions do
  describe ".custom_message" do
    context "when the exception is a Pundit::NotAuthorizedError" do
      let(:record) { SourceType.new }
      let(:exception) { double(:class => "Pundit::NotAuthorizedError", :query => "create?", :record => record) }

      it "returns a customized message" do
        expect(Insights::API::Common::CustomExceptions.custom_message(exception)).to eq(
          "You are not authorized to create this source type"
        )
      end
    end
  end
end
