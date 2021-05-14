module Api
  module V2
    class TasksController < ApplicationController
      include Api::V2::Mixins::IndexMixin

      def show
        render :json => Task.find(params[:id]).to_json
      end
    end
  end
end
