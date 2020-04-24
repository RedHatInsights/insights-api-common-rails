describe Insights::API::Common::OpenApi::VersionFromPrefix do
  let(:test_class) do
    Class.new do
      include Insights::API::Common::OpenApi::VersionFromPrefix
    end
  end

  let(:model) { test_class.new }

  it "properly detects the version to serialize for" do
    expect(model.api_version_from_prefix("api/v0.0/")).to eq("0.0")
    expect(model.api_version_from_prefix("api/v0.0/something")).to eq("0.0")
    expect(model.api_version_from_prefix("api/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("/api/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("a/b/v/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("/a/b/v/v0.1/something")).to eq("0.1")
  end
end
