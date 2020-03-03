RSpec.describe("Insights::API::Common::PaginatedResponseV2", :type => :request) do
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
    get(URI.escape("/api/v2.0/#{collection}?#{query}"))

    expect(response).to(
      have_attributes(
        :parsed_body => a_hash_including("data" => results.collect { |i| a_hash_including("id" => i.id) }),
        :status      => 200
      )
    )
  end

  def expect_failure(collection, query, *errors)
    get(URI.escape("/api/v2.0/#{collection}?#{query}"))

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
    get(URI.escape("/api/v2.0/#{collection}?#{query}"))

    expect(response.status).to(eq(200))

    results = results.collect(&:stringify_keys)
    attrs = results.first.keys

    expect(response.parsed_body["data"].collect { |res| res.slice(*attrs) }).to(eq(results))
  end

  context "sorted results via sort_by" do
    let!(:rhev)      { SourceType.create(:name => "rhev_sample", :product_name => "RedHat Virtualization", :vendor => "redhat") }
    let!(:openstack) { SourceType.create(:name => "openstack_sample", :product_name => "OpenStack", :vendor => "redhat") }
    let!(:vmware)    { SourceType.create(:name => "vmware_sample", :product_name => "OpenStack", :vendor => "vmware") }

    it("with single attribute and default order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]=asc",
                                     [
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"},
                                       {:vendor => "vmware"}
                                     ])
    end

    it("with single attribute and order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]=desc",
                                     [
                                       {:vendor => "vmware"},
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"}
                                     ])
    end

    it("with multiple attributes and default order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]=asc&sort_by[name]=asc",
                                     [
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                       {:vendor => "vmware", :name => "vmware_sample"}
                                     ])
    end

    it("with multiple attributes and only some with order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]=desc&sort_by[name]=asc",
                                     [
                                       {:vendor => "vmware", :name => "vmware_sample"},
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                     ])
    end

    it("with multiple attributes and all with order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]=asc&sort_by[name]=desc",
                                     [
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "vmware", :name => "vmware_sample"}
                                     ])
    end

    it("with multiple attributes and one with missing order") do
      expect_success_ordered_objects("source_types", "filter[name][ends_with]=sample&sort_by[vendor]&sort_by[name]=desc",
                                     [
                                       {:vendor => "redhat", :name => "rhev_sample"},
                                       {:vendor => "redhat", :name => "openstack_sample"},
                                       {:vendor => "vmware", :name => "vmware_sample"}
                                     ])
    end

    it("returns a bad_request if the sort_by parameter is not an object") do
      expect_failure("source_types", "sort_by=name:asc", "ArgumentError: Invalid sort_by parameter specified \"name:asc\"")
    end

    it("returns a bad_request if the single sort_by attribute is illegal") do
      expect_failure("source_types", "sort_by[Capital^#]=", "ArgumentError: Invalid sort_by directive specified \"Capital^#=\"")
    end

    it("returns a bad_request if the single sort_by attribute order is invalid") do
      expect_failure("source_types", "sort_by[name]=bogus", "ArgumentError: Invalid sort_by directive specified \"name=bogus\"")
    end

    it("returns a bad_request if one of the multiple sort_by attributes is malformed") do
      expect_failure("source_types", "sort_by[Capital^#]=&sort_by[name]=asc", "ArgumentError: Invalid sort_by directive specified \"Capital^#=\"")
    end

    it("returns a bad_request if one of the multiple sort_by order is invalid") do
      expect_failure("source_types", "sort_by[name]=asc&sort_by[vendor]=bogus", "ArgumentError: Invalid sort_by directive specified \"vendor=bogus\"")
    end
  end

  context "sorted results via sort_by against associations" do
    before do
      @source_s1 = Source.create!(:tenant => tenant, :name => "source_s1", :source_type => source_type)
      @source_s2 = Source.create!(:tenant => tenant, :name => "source_s2", :source_type => source_type)
      @source_s3 = Source.create!(:tenant => tenant, :name => "source_s3", :source_type => source_type)
    end

    it "succeeds with single association attribute in ascending order" do
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][display_name]=",
                                     [
                                       {:name => "source_s2"},
                                       {:name => "source_s1"},
                                       {:name => "source_s3"}
                                     ])
    end

    it "succeeds with single association attribute in descending order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][display_name]=desc",
                                     [
                                       {:name => "source_s2"},
                                       {:name => "source_s3"},
                                       {:name => "source_s1"}
                                     ])
    end

    it "succeeds with an association attribute and direct attribute in mixed order" do
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][display_name]=asc&sort_by[name]=desc",
                                     [
                                       {:name => "source_s2"},
                                       {:name => "source_s3"},
                                       {:name => "source_s1"}
                                     ])
    end

    it "succeeds based on an association count" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][__count]=&sort_by[name]=",
                                     [
                                       {:name => "source_s3"},
                                       {:name => "source_s1"},
                                       {:name => "source_s2"}
                                     ])
    end

    it "succeeds based on an association count in reverse order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][__count]=desc",
                                     [
                                       {:name => "source_s2"},
                                       {:name => "source_s1"},
                                       {:name => "source_s3"}
                                     ])
    end

    it "succeeds based on an association count with a secondary attribute" do
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][__count]=&sort_by[name]=",
                                     [
                                       {:name => "source_s1"},
                                       {:name => "source_s3"},
                                       {:name => "source_s2"}
                                     ])
    end

    it "succeeds based on an association count with a secondary attribute in reverse order" do
      Application.create(:application_type => catalog_apptype, :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => topo_apptype,    :source => @source_s2, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s1, :tenant => tenant)
      Application.create(:application_type => cost_apptype,    :source => @source_s3, :tenant => tenant)

      expect_success_ordered_objects("sources", "filter[name][starts_with]=source_s&sort_by[application_types][__count]&sort_by[name]=desc",
                                     [
                                       {:name => "source_s3"},
                                       {:name => "source_s1"},
                                       {:name => "source_s2"}
                                     ])
    end
  end
end
