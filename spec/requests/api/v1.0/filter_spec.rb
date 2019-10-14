RSpec.describe("::ManageIQ::API::Common::Filter", :type => :request) do
  let(:external_tenant) { rand(1000).to_s }
  let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
  let(:source_type)     { SourceType.create(:name => "rhex", :product_name => "RedHat Virtualization", :vendor => "redhat") }

  def create_source(attrs = {})
    Source.create!(attrs.merge(:tenant => tenant, :source_type => source_type))
  end

  def expect_success(query, *results)
    get(URI.escape("/api/v1.0/sources?#{query}"))

    expect(response).to(
      have_attributes(
        :parsed_body => a_hash_including("data" => results.collect { |i| a_hash_including("id" => i.id) }),
        :status      => 200
      )
    )
  end

  context "case insensitive strings" do
    let!(:source_1) { create_source(:name => "source_a")  }
    let!(:source_2) { create_source(:name => "Source_A")  }
    let!(:source_3) { create_source(:name => "source_b")  }
    let!(:source_4) { create_source(:name => "Source_B")  }
    let!(:source_5) { create_source(:name => "%source_d") }
    let!(:source_6) { create_source(:name => "%Source_D") }
    let!(:source_7) { create_source(:name => "Source_f%") }
    let!(:source_8) { create_source(:name => "Source_F%") }

    it("key:eq_i single")        { expect_success("filter[name][eq_i]=#{source_1.name}", source_1, source_2) }
    it("key:eq_i array")         { expect_success("filter[name][eq_i][]=#{source_1.name}&filter[name][eq_i][]=#{source_3.name}", source_1, source_2, source_3, source_4) }

    it("key:contains_i single")  { expect_success("filter[name][contains_i]=a", source_1, source_2) }
    it("key:contains_i array")   { expect_success("filter[name][contains_i][]=s&filter[name][contains_i][]=a", source_1, source_2) }

    it("key:starts_with_i")      { expect_success("filter[name][starts_with_i]=s", source_1, source_2, source_3, source_4, source_7, source_8) }
    it("key:ends_with_i")        { expect_success("filter[name][ends_with_i]=b", source_3, source_4) }

    it("key:starts_with_i %")    { expect_success("filter[name][starts_with_i]=%s", source_5, source_6) }
    it("key:ends_with_i %")      { expect_success("filter[name][ends_with_i]=f%", source_7, source_8) }
  end
end
