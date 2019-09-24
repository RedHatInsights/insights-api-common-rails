class ApplicationController < ActionController::Base
  protect_from_forgery :with => :null_session

  include ManageIQ::API::Common::ApplicationControllerMixins::ApiDoc
  include ManageIQ::API::Common::ApplicationControllerMixins::Common
  include ManageIQ::API::Common::ApplicationControllerMixins::RequestBodyValidation
  include ManageIQ::API::Common::ApplicationControllerMixins::RequestPath
  include ManageIQ::API::Common::ApplicationControllerMixins::Parameters
end
