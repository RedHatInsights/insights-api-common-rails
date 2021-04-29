Rails.application.routes.draw do
  mount Insights::API::Common::Engine => "/insights-api-common"

  routing_helper = Insights::API::Common::Routing.new(self)

  get "/health", :to => "status#health"

  scope :as => :api, :module => "api", :path => "api" do
    routing_helper.redirect_major_version("v0.1", "api")

    namespace :v2x0, :path => "v2.0" do
      get "/error",        :to => "errors#error"
      get "/error_nested", :to => "errors#error_nested"
      get "/http_error", :to => "errors#http_error"
      get "/api_client_error", :to => "errors#api_client_error"
      get "/pundit_error", :to => "errors#pundit_error"
      get "/openapi.json", :to => "root#openapi"
      post "graphql" => "graphql#query"
      resources :applications, :only => [:index]
      resources :application_types, :only => [:index]
      resources :authentications, :only => [:create, :update]
      resources :vms, :only => [:index, :show]
      resources :persons, :only => [:index, :create, :show, :update]
      resources :sources, :only => [:index] do
        resources :tasks, :only => [:index]
      end
      resources :source_types, :only => [:index]
      resources :tasks, :only => [:index, :show]
      resources :extras, :only => [:index]
    end

    namespace :v1x0, :path => "v1.0" do
      get "/error",        :to => "errors#error"
      get "/error_nested", :to => "errors#error_nested"
      get "/http_error", :to => "errors#http_error"
      get "/api_client_error", :to => "errors#api_client_error"
      get "/pundit_error", :to => "errors#pundit_error"
      get "/openapi.json", :to => "root#openapi"
      post "graphql" => "graphql#query"
      resources :authentications, :only => [:create, :update]
      resources :vms, :only => [:index, :show]
      resources :persons, :only => [:index, :create, :show, :update]
      resources :sources, :only => [:index]
      resources :source_types, :only => [:index]
      resources :extras, :only => [:index]
    end

    namespace :v0x1, :path => "v0.1" do
      get "/openapi.json", :to => "root#openapi"
      resources :vms, :only => [:index]
    end

    namespace :v0x0, :path => "v0.0" do
    end
  end
end
