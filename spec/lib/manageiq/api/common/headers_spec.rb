describe ManageIQ::API::Common::Headers do
  let(:header_good) { ActionDispatch::Http::Headers.new({:blah => 'blah'}) }
  let(:header_bad)  { {:blah => 'blah' } }
  context "set current headers" do
    it 'sets if the class is correct' do
      expect(ManageIQ::API::Common::Headers.current = header_good).to be_a(ActionDispatch::Http::Headers)
    end

    it 'raises an exception if the class is incorrect' do
      expect { ManageIQ::API::Common::Headers.current = header_bad }.to raise_exception(ArgumentError)
    end
  end
end
