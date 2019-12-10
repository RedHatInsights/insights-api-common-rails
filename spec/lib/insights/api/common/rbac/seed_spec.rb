describe Insights::API::Common::RBAC::Seed do
  include_context "rbac_seed_objects"
  let(:seed_file) { File.join('.', 'spec/data/test_seed.yml') }
  let(:user_file) { File.join('.', 'spec/data/user.yml') }
  let(:subject) { described_class.new(seed_file, user_file) }
  let(:request) { nil }

  shared_examples_for "#process" do
    context "nothing exists" do
      before do
        allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return([], [group1])
        allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {}).and_return([], [role1])

        allow(api_instance).to receive(:create_roles).and_return(role1)
        allow(api_instance).to receive(:create_group).and_return(group1)
        allow(RBACApiClient::GroupRoleIn).to receive(:new).and_return(role1_in)
      end

      it "makes an API request to #list_roles_for_group to return empty roles" do
        Insights::API::Common::Request.with_request(request) do
          expect(api_instance).to receive(:add_role_to_group).with(group1.uuid, role1_in).and_return([role1_detail])
          expect(api_instance).to receive(:list_roles_for_group).with(group1.uuid).and_return([])

          subject.process
        end
      end
    end

    context "all data exists" do
      before do
        allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
        allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {}).and_return(roles)
        allow(api_instance).to receive(:create_roles).and_return(role1)
      end

      it "makes an API request to #list_roles_for_group to return the correct role" do
        Insights::API::Common::Request.with_request(request) do
          expect(api_instance).to receive(:list_roles_for_group).with(group1.uuid).and_return([role1_detail])

          subject.process
        end
      end
    end
  end

  context "#process" do
    before do
      allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
      allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    end

    context "no request" do
      let(:user_file) { File.join('.', 'spec/data/user.yml') }
      let(:request) { nil }

      it_behaves_like "#process"
    end

    context "with_request" do
      let(:user_file) { nil }
      let(:request) { default_request }

      it_behaves_like "#process"
    end

    context "no user file" do
      let(:user_file) { File.join('.', 'does_not_exist') }
      let(:request) { nil }
      it "raises an exception" do
        expect { subject.process }.to raise_exception(RuntimeError, /not found/)
      end
    end

    context "api_error" do
      let(:user_file) { File.join('.', 'spec/data/user.yml') }
      let(:request) { nil }

      it "raises an exception" do
        allow(Insights::API::Common::RBAC::Service).to receive(:paginate).and_raise(RBACApiClient::ApiError.new('Kaboom'))
        expect { subject.process }.to raise_exception(RBACApiClient::ApiError, /Kaboom/)
      end
    end
  end
end
