describe ManageIQ::API::Common::ApplicationControllerMixins::RequestPath do
  let(:test_class) do
    Class.new do
      include ManageIQ::API::Common::ApplicationControllerMixins::RequestPath

      def initialize(request_uri)
        @request_uri = request_uri
      end

      def request
        self
      end

      def env
        {"REQUEST_URI" => @request_uri}
      end
    end
  end

  context "#subcollection?" do
    it "valid paths" do
      expect(test_class.new("/aaa/bbb/v1.0/primary").subcollection?).to eq(false)
      expect(test_class.new("/aaa/v1.0/primary").subcollection?).to     eq(false)
      expect(test_class.new("/v1.0/primary").subcollection?).to         eq(false)
      expect(test_class.new("/v1.0/primary/").subcollection?).to        eq(false)
      expect(test_class.new("/v1.0/primary/1").subcollection?).to       eq(false)
      expect(test_class.new("/v1.0/primary/1/").subcollection?).to      eq(false)
      expect(test_class.new("/v1.0/primary/1/sub").subcollection?).to   eq(true)
      expect(test_class.new("/v1.0/primary/1/sub/").subcollection?).to  eq(true)
    end

    it "invalid paths" do
      expect(test_class.new("/v1.0/primary/abc/sub").subcollection?).to eq(false)
      expect(test_class.new("/primary/abc/sub").subcollection?).to      eq(false)
    end
  end

  context "#request_path_parts" do
    it "valid paths" do
      expect(test_class.new("/aaa/bbb/v1.0/primary").request_path_parts).to eq("full_version_string" => "v1.0", "primary_collection_id" => nil, "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/aaa/v1.0/primary").request_path_parts).to     eq("full_version_string" => "v1.0", "primary_collection_id" => nil, "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/v1.0/primary").request_path_parts).to         eq("full_version_string" => "v1.0", "primary_collection_id" => nil, "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/v1.0/primary/").request_path_parts).to        eq("full_version_string" => "v1.0", "primary_collection_id" => nil, "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/v1.0/primary/1").request_path_parts).to       eq("full_version_string" => "v1.0", "primary_collection_id" => "1", "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/v1.0/primary/1/").request_path_parts).to      eq("full_version_string" => "v1.0", "primary_collection_id" => "1", "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/v1.0/primary/1/sub").request_path_parts).to   eq("full_version_string" => "v1.0", "primary_collection_id" => "1", "primary_collection_name" => "primary", "subcollection_name" => "sub")
      expect(test_class.new("/v1.0/primary/1/sub/").request_path_parts).to  eq("full_version_string" => "v1.0", "primary_collection_id" => "1", "primary_collection_name" => "primary", "subcollection_name" => "sub")
    end

    it "invalid paths" do
      expect(test_class.new("/v1.0/primary/abc/sub").request_path_parts).to eq("full_version_string" => "v1.0", "primary_collection_id" => nil, "primary_collection_name" => "primary", "subcollection_name" => nil)
      expect(test_class.new("/primary/1/sub").request_path_parts).to        eq({})
    end
  end
end
