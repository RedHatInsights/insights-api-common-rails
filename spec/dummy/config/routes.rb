Rails.application.routes.draw do
  mount ManageIQ::API::Common::Engine => "/manageiq-api-common"

  routing_helper = ManageIQ::API::Common::Routing.new(self)

  scope :as => :api, :module => "api", :path => "api" do
    routing_helper.redirect_major_version("v0.1", "api")

    namespace :v1x0, :path => "v1.0" do
      get "/openapi.json", :to => "root#openapi"
      post "graphql" => "graphql#query"
      resources :authentications, :only => [:create]
      resources :vms, :only => [:index]
    end

    namespace :v0x1, :path => "v0.1" do
      get "/openapi.json", :to => "root#openapi"
      resources :vms, :only => [:index]
    end

    namespace :v0x0, :path => "v0.0" do
    end
  end
end
