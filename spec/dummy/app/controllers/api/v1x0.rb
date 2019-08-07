module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => {:things => "stuff"}.to_json
      end
    end

    class VmsController < ApplicationController
      def index
        render :json => {:things => "stuff"}.to_json
      end
    end
  end
end
