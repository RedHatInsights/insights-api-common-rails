class ApplicationController < ActionController::Base
  protect_from_forgery :with => :null_session

  include Insights::API::Common::ApplicationControllerMixins::ApiDoc
  include Insights::API::Common::ApplicationControllerMixins::Common
  include Insights::API::Common::ApplicationControllerMixins::ExceptionHandling
  include Insights::API::Common::ApplicationControllerMixins::Parameters
  include Insights::API::Common::ApplicationControllerMixins::RequestBodyValidation
  include Insights::API::Common::ApplicationControllerMixins::RequestParameterValidation
  include Insights::API::Common::ApplicationControllerMixins::RequestPath
end
