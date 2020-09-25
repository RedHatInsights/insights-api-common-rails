RSpec.describe("Insights::API::Common::Filter", :type => :request) do
  let(:external_tenant) { rand(1000).to_s }
  let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
  let(:source_type)     { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }

  def create_source(attrs = {})
    Source.create!(attrs.merge(:tenant => tenant, :source_type => source_type))
  end

  def expect_success(collection, query, *results)
    get(URI.escape("/api/v1.0/#{collection}?#{query}"))

    expect(response).to(
      have_attributes(
        :parsed_body => a_hash_including("data" => results.collect { |i| a_hash_including("id" => i.id) }),
        :status      => 200
      )
    )
  end

  def expect_failure(collection, query, *errors)
    get(URI.escape("/api/v1.0/#{collection}?#{query}"))

    expect(response).to(
      have_attributes(
        :parsed_body => {
          "errors" => errors.collect { |e| {"detail" => e, "status" => "400"} }
        },
        :status      => 400
      )
    )
  end

  def expect_success_ordered_objects(collection, query, results)
    get(URI.escape("/api/v1.0/#{collection}?#{query}"))

    expect(response.status).to(eq(200))

    results = results.collect(&:stringify_keys)
    attrs = results.first.keys

    expect(response.parsed_body["data"].collect { |res| res.slice(*attrs) }).to(eq(results))
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

    it("key:eq single")          { expect_success("sources", "filter[name][eq]=#{source_1.name}", source_1) }
    it("key:eq array")           { expect_success("sources", "filter[name][eq][]=#{source_1.name}&filter[name][eq][]=#{source_3.name}", source_1, source_3) }

    it("key:eq_i single")        { expect_success("sources", "filter[name][eq_i]=#{source_1.name}", source_1, source_2) }
    it("key:eq_i array")         { expect_success("sources", "filter[name][eq_i][]=#{source_1.name}&filter[name][eq_i][]=#{source_3.name}", source_1, source_2, source_3, source_4) }

    it("key:contains_i single")  { expect_success("sources", "filter[name][contains_i]=a", source_1, source_2) }
    it("key:contains_i array")   { expect_success("sources", "filter[name][contains_i][]=s&filter[name][contains_i][]=a", source_1, source_2) }

    it("key:starts_with_i")      { expect_success("sources", "filter[name][starts_with_i]=s", source_1, source_2, source_3, source_4, source_7, source_8) }

    it("key:ends_with_i")        { expect_success("sources", "filter[name][ends_with_i]=b", source_3, source_4) }

    it("key:starts_with")        { expect_success("sources", "filter[name][starts_with]=source", source_1, source_3) }

    it("key:ends_with")          { expect_success("sources", "filter[name][ends_with]=b", source_3) }

    it("key:starts_with_i %")    { expect_success("sources", "filter[name][starts_with_i]=%s", source_5, source_6) }
    it("key:ends_with_i %")      { expect_success("sources", "filter[name][ends_with_i]=f%", source_7, source_8) }

    it("key:eq array")           { expect_success("sources", "filter[id][]=#{source_7.id}&filter[id][]=#{source_8.id}", source_7, source_8) }
    it("key:eq(explicit) array") { expect_success("sources", "filter[id][eq][]=#{source_7.id}&filter[id][eq][]=#{source_8.id}", source_7, source_8) }

    it("key:gt")                 { expect_success("sources", "filter[id][gt]=#{source_1.id}", *Source.where(Source.arel_table[:id].gt(source_1.id))) }

    it("key:gte")                { expect_success("sources", "filter[id][gte]=#{source_1.id}", *Source.where(Source.arel_table[:id].gteq(source_1.id))) }

    it("key:lt")                 { expect_success("sources", "filter[id][lt]=#{source_8.id}", *Source.where(Source.arel_table[:id].lt(source_8.id))) }

    it("key:lte")                { expect_success("sources", "filter[id][lte]=#{source_8.id}", *Source.where(Source.arel_table[:id].lteq(source_8.id))) }
  end

  context "allows filtering on extra (undocumented) attributes listed in the controller" do
    let!(:source_1) { create_source(:name => "source_a", :undocumented => "abc")  }
    let!(:source_2) { create_source(:name => "Source_A", :undocumented => "xyz")  }
    let!(:source_3) { create_source(:name => "source_b", :undocumented => "abc")  }
    let!(:source_4) { create_source(:name => "Source_B", :undocumented => "xyz")  }
    let!(:source_5) { create_source(:name => "%source_d") }
    let!(:source_6) { create_source(:name => "%Source_D") }
    let!(:source_7) { create_source(:name => "Source_f%") }
    let!(:source_8) { create_source(:name => "Source_F%") }

    it("key:eq single")   { expect_success("sources", "filter[undocumented][eq]=#{source_1.undocumented}", source_1, source_3) }
    it("key:eq array")    { expect_success("sources", "filter[undocumented][eq][]=#{source_1.undocumented}&filter[undocumented][eq][]=#{source_2.undocumented}", source_1, source_2, source_3, source_4) }

    it("key:eq_i single") { expect_success("sources", "filter[undocumented][eq_i]=ABC", source_1, source_3) }
    it("key:eq_i array")  { expect_success("sources", "filter[undocumented][eq_i][]=ABC&filter[undocumented][eq_i][]=XYZ", source_1, source_2, source_3, source_4) }
  end

  context "sorted results via sort_by" do
    let!(:rhev)      { SourceType.create(:name => "rhev_sample", :product_name => "RedHat Virtualization", :vendor => "redhat") }
    let!(:openstack) { SourceType.create(:name => "openstack_sample", :product_name => "OpenStack", :vendor => "redhat") }
    let!(:vmware)    { SourceType.create(:name => "vmware_sample", :product_name => "OpenStack", :vendor => "vmware") }

    it("with single attribute and default order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by=vendor",
                                     [
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"},
                                       {:vendor => "vmware"}
                                     ])
    end

    it("with single attribute and order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by=vendor:desc",
                                     [
                                       {:vendor => "vmware"},
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"}
                                     ])
    end

    it("with multiple attributes and default order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[]=vendor&sort_by[]=name",
                                     [
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                       {:vendor => "vmware", :name => "vmware_sample"}
                                     ])
    end

    it("with multiple attributes and only some with order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[]=vendor:desc&sort_by[]=name",
                                     [
                                       {:vendor => "vmware", :name => "vmware_sample"},
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                     ])
    end

    it("with multiple attributes and all with order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[]=vendor:asc&sort_by[]=name:desc",
                                     [
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "vmware", :name => "vmware_sample"}
                                     ])
    end

    it("returns a bad_request if the sort_by attribute is not a string or array") do
      expect_failure("source_types", "sort_by[attribute]=asc", "ArgumentError: Invalid sort_by parameter specified \"{\"attribute\"=>\"asc\"}\"")
    end

    it("returns a bad_request if the single sort_by attribute is illegal") do
      expect_failure("source_types", "sort_by=Capital^#", "ArgumentError: Invalid sort_by directive specified \"Capital^#\"")
    end

    it("returns a bad_request if the single sort_by attribute order is missing") do
      expect_failure("source_types", "sort_by=name:", "ArgumentError: Invalid sort_by directive specified \"name:\"")
    end

    it("returns a bad_request if the single sort_by attribute order is invalid") do
      expect_failure("source_types", "sort_by=name:bogus", "ArgumentError: Invalid sort_by directive specified \"name:bogus\"")
    end

    it("returns a bad_request one of the multiple sort_by attributes is malformed") do
      expect_failure("source_types", "sort_by[]=Capital^#", "ArgumentError: Invalid sort_by directive specified \"Capital^#\"")
    end

    it("returns a bad_request if the single sort_by attribute order is missing") do
      expect_failure("source_types", "sort_by[]=name&sort_by[]=vendor:", "ArgumentError: Invalid sort_by directive specified \"vendor:\"")
    end

    it("returns a bad_request if the single sort_by attribute order is invalid") do
      expect_failure("source_types", "sort_by[]=name&sort_by[]=vendor:bogus", "ArgumentError: Invalid sort_by directive specified \"vendor:bogus\"")
    end
  end
end
