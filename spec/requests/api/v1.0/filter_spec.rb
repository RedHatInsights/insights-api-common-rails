RSpec.describe("::ManageIQ::API::Common::Filter", :type => :request) do
  let(:external_tenant) { rand(1000).to_s }
  let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
  let(:source_type)     { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }

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

  def expect_success_ordered_objects(query, results)
    get(URI.escape("/api/v1.0/source_types?#{query}"))

    expect(response.status).to(eq(200))

    response.parsed_body["data"].each do |object|
      expect(object).to(include(results.shift.deep_stringify_keys))
    end
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

    it("key:eq single")         { expect_success("filter[name][eq]=#{source_1.name}", source_1) }
    it("key:eq array")          { expect_success("filter[name][eq][]=#{source_1.name}&filter[name][eq][]=#{source_3.name}", source_1, source_3) }

    it("key:eq_i single")        { expect_success("filter[name][eq_i]=#{source_1.name}", source_1, source_2) }
    it("key:eq_i array")         { expect_success("filter[name][eq_i][]=#{source_1.name}&filter[name][eq_i][]=#{source_3.name}", source_1, source_2, source_3, source_4) }

    it("key:contains_i single")  { expect_success("filter[name][contains_i]=a", source_1, source_2) }
    it("key:contains_i array")   { expect_success("filter[name][contains_i][]=s&filter[name][contains_i][]=a", source_1, source_2) }

    it("key:starts_with_i")      { expect_success("filter[name][starts_with_i]=s", source_1, source_2, source_3, source_4, source_7, source_8) }

    it("key:ends_with_i")        { expect_success("filter[name][ends_with_i]=b", source_3, source_4) }

    it("key:starts_with")      { expect_success("filter[name][starts_with]=source", source_1, source_3) }

    it("key:ends_with")        { expect_success("filter[name][ends_with]=b", source_3) }

    it("key:starts_with_i %")    { expect_success("filter[name][starts_with_i]=%s", source_5, source_6) }
    it("key:ends_with_i %")      { expect_success("filter[name][ends_with_i]=f%", source_7, source_8) }

    it("key:eq array")           { expect_success("filter[id][]=#{source_7.id}&filter[id][]=#{source_8.id}", source_7, source_8) }
    it("key:eq(explicit) array") { expect_success("filter[id][eq][]=#{source_7.id}&filter[id][eq][]=#{source_8.id}", source_7, source_8) }

    it("key:gt")                 { expect_success("filter[id][gt]=#{source_1.id}", *Source.where(Source.arel_table[:id].gt(source_1.id))) }

    it("key:gte")                { expect_success("filter[id][gte]=#{source_1.id}", *Source.where(Source.arel_table[:id].gteq(source_1.id))) }

    it("key:lt")                 { expect_success("filter[id][lt]=#{source_8.id}", *Source.where(Source.arel_table[:id].lt(source_8.id))) }

    it("key:lte")                { expect_success("filter[id][lte]=#{source_8.id}", *Source.where(Source.arel_table[:id].lteq(source_8.id))) }
  end

  context "sorted results via sort_by" do
    let!(:rhev)      { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }
    let!(:openstack) { SourceType.create(:name => "openstack", :product_name => "OpenStack", :vendor => "redhat") }
    let!(:vmware)    { SourceType.create(:name => "vmware", :product_name => "OpenStack", :vendor => "vmware") }

    it("with single attribute and default order") do
      expect_success_ordered_objects("sort_by[]=vendor",
                                     [
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"},
                                       {:vendor => "vmware"}
                                     ])
    end

    it("with single attribute and order") do
      expect_success_ordered_objects("sort_by[]=vendor:desc",
                                     [
                                       {:vendor => "vmware"},
                                       {:vendor => "redhat"},
                                       {:vendor => "redhat"}
                                     ])
    end

    it("with multiple attributes and default order") do
      expect_success_ordered_objects("sort_by[]=vendor&sort_by[]=name",
                                     [
                                       {:vendor => "redhat", :name => "openstack"},
                                       {:vendor => "redhat", :name => "rhev"},
                                       {:vendor => "vmware", :name => "vmware"}
                                     ])
    end

    it("with multiple attributes and only some with order") do
      expect_success_ordered_objects("sort_by[]=vendor:desc&sort_by[]=name",
                                     [
                                       {:vendor => "vmware", :name => "vmware"},
                                       {:vendor => "redhat", :name => "openstack"},
                                       {:vendor => "redhat", :name => "rhev"},
                                     ])
    end

    it("with multiple attributes and all with order") do
      expect_success_ordered_objects("sort_by[]=vendor:asc&sort_by[]=name:desc",
                                     [
                                       {:vendor => "redhat", :name => "rhev"},
                                       {:vendor => "redhat", :name => "openstack"},
                                       {:vendor => "vmware", :name => "vmware"}
                                     ])
    end
  end
end
