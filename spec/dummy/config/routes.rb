Rails.application.routes.draw do
  mount ManageIQ::API::Common::Engine => "/manageiq-api-common"
end
