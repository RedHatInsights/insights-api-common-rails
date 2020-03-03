module Api
  module V2
    class ApplicationsController < ApplicationController
      include Api::V2::Mixins::IndexMixin
    end
  end
end
