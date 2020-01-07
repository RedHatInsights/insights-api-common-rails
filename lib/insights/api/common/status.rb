module Insights
  module API
    module Common
      module Status
        module Api
          def health
            if PG::Connection.ping(ENV['DATABASE_URL']) == PG::Connection::PQPING_OK
              head :ok
            else
              head :internal_server_error
            end
          end
        end
      end
    end
  end
end
