class ApplicationController < ActionController::Base
  protect_from_forgery :with => :null_session

  include ManageIQ::API::Common::ApplicationControllerMixins::ApiDoc
  include ManageIQ::API::Common::ApplicationControllerMixins::Common
  include ManageIQ::API::Common::ApplicationControllerMixins::InputValidation
  include ManageIQ::API::Common::ApplicationControllerMixins::RequestPath
end
