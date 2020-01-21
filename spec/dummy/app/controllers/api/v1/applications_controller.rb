module Api
  module V1
    class ApplicationsController < ApplicationController
      include Api::V1::Mixins::IndexMixin
    end
  end
end
