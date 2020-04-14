ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  "ActionCable::Connection::Authorization::UnauthorizedError" => :forbidden
)
