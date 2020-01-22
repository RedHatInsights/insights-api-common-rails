RSpec.describe("Insights::API::Common::Filter", :type => :request) do
  let(:external_tenant) { rand(1000).to_s }
  let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
  let(:source_type)     { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }

  let!(:catalog_apptype) { ApplicationType.create(:name => "/insights/platform/catalog", :display_name => "Catalog") }
  let!(:cost_apptype)    { ApplicationType.create(:name => "/insights/platform/cost-management", :display_name => "Cost Management") }
  let!(:topo_apptype)    { ApplicationType.create(:name => "/insights/platform/topological-inventory", :display_name => "Topological Inventory") }

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
          "errors" => errors.collect { |e| {"detail" => e, "status" => 400} }
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

    it("returns a bad_request if the single sort_by attribute is illegal") do
      expect_failure("source_types", "sort_by=Capital^#", "OpenAPIParser::NotOneOf: Capital^# isn't one of in #/components/parameters/QuerySortBy/schema")
    end

    it("returns a bad_request if the single sort_by attribute order is missing") do
      expect_failure("source_types", "sort_by=name:", "OpenAPIParser::NotOneOf: name: isn't one of in #/components/parameters/QuerySortBy/schema")
    end

    it("returns a bad_request if the single sort_by attribute order is invalid") do
      expect_failure("source_types", "sort_by=name:bogus", "OpenAPIParser::NotOneOf: name:bogus isn't one of in #/components/parameters/QuerySortBy/schema")
    end

    it("returns a bad_request one of the multiple sort_by attributes is malformed") do
      expect_failure("source_types", "sort_by[]=Capital^#", "OpenAPIParser::NotOneOf: [\"Capital^#\"] isn't one of in #/components/parameters/QuerySortBy/schema")
    end

    it("returns a bad_request if the single sort_by attribute order is missing") do
      expect_failure("source_types", "sort_by[]=name&sort_by[]=vendor:", "OpenAPIParser::NotOneOf: [\"name\", \"vendor:\"] isn't one of in #/components/parameters/QuerySortBy/schema")
    end

    it("returns a bad_request if the single sort_by attribute order is invalid") do
      expect_failure("source_types", "sort_by[]=name&sort_by[]=vendor:bogus", "OpenAPIParser::NotOneOf: [\"name\", \"vendor:bogus\"] isn't one of in #/components/parameters/QuerySortBy/schema")
    end
  end

  context "sorted results via sort_by against association attributes" do
    before do
      @source_s1 = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_type)
      @source_s2 = Source.create!(:tenant => tenant, :name => "source_s2", :source_type => source_type)
      @source_s3 = Source.create!(:tenant => tenant, :name => "source_s3", :source_type => source_type)
    end

    it "succeeds with single association attribute in ascending order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by=application_types.display_name",
                                     [
                                       {:name => "source_s1"},
                                       {:name => "source_s2"},
                                       {:name => "source_s3"}
                                     ])
    end

    it "succeeds with single association attribute in descending order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by=application_types.display_name:desc",
                                     [
                                       {:name => "source_s3"},
                                       {:name => "source_s2"},
                                       {:name => "source_s1"}
                                     ])
    end

    it "succeeds with an association attribute and direct attribute in mixed order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype ,   :source => @source_s2, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[]=name:desc&sort_by[]=application_types.display_name:asc",
                                     [
                                       {:name => "source_s3"},
                                       {:name => "source_s2"},
                                       {:name => "source_s1"}
                                     ])
    end

    it "succeeds based on an association count" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype ,   :source => @source_s2, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[]=application_types.@count&sort_by[]=application_types.display_name",
                                     [
                                       {:name => "source_s3"},
                                       {:name => "source_s1"},
                                       {:name => "source_s2"}
                                     ])
    end

    it "succeeds based on an association count in reverse order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype ,   :source => @source_s2, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[]=application_types.@count:desc",
                                     [
                                       {:name => "source_s2"},
                                       {:name => "source_s1"},
                                       {:name => "source_s3"}
                                     ])
    end
  end
end
