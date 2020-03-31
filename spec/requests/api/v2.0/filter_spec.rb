RSpec.describe("Insights::API::Common::Filter", :type => :request) do
  let(:external_tenant) { rand(1000).to_s }
  let(:tenant)          { Tenant.create!(:name => "default", :external_tenant => external_tenant) }
  let(:source_type)     { SourceType.create(:name => "rhev", :product_name => "RedHat Virtualization", :vendor => "redhat") }

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

  context "allows filtering on association attributes" do
    let!(:rhev)      { SourceType.create(:name => "rhev_sample",      :product_name => "RedHat Virtualization", :vendor => "redhat") }
    let!(:openstack) { SourceType.create(:name => "openstack_sample", :product_name => "OpenStack",             :vendor => "redhat") }
    let!(:openshift) { SourceType.create(:name => "openshift_sample", :product_name => "OpenShift",             :vendor => "redhat") }

    let!(:source_rhev)       { Source.create!(:name => "rhev_source_sample",      :tenant => tenant, :source_type => rhev)      }
    let!(:source_openstack)  { Source.create!(:name => "openstack_source_sample", :tenant => tenant, :source_type => openstack) }
    let!(:source_openshift)  { Source.create!(:name => "openshift_source_sample", :tenant => tenant, :source_type => openshift) }

    it("succeeds on a single association attribute value") do
      expect_success("sources", "filter[source_type][name][eq]=#{rhev.name}", source_rhev)
    end

    it("succeeds on multiple association attribute values") do
      expect_success("sources", "filter[source_type][name][eq][]=#{openstack.name}&filter[source_type][name][eq][]=#{openshift.name}", source_openstack, source_openshift)
    end

    it("succeeds with a non string association attribute value") do
      expect_success("sources", "filter[source_type][id][gt]=#{openstack.id}", *Source.left_outer_joins(:source_type).where(SourceType.arel_table[:id].gt(openstack.id)))
    end
  end
end
