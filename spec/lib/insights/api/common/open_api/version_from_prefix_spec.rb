describe Insights::API::Common::OpenApi::VersionFromPrefix do
  class TestClass
    include Insights::API::Common::OpenApi::VersionFromPrefix
  end

  let(:model) { TestClass.new }

  it "properly detects the version to serialize for" do
    expect(model.api_version_from_prefix("api/v0.0/")).to eq("0.0")
    expect(model.api_version_from_prefix("api/v0.0/something")).to eq("0.0")
    expect(model.api_version_from_prefix("api/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("/api/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("a/b/v/v0.1/something")).to eq("0.1")
    expect(model.api_version_from_prefix("/a/b/v/v0.1/something")).to eq("0.1")
  end
end
