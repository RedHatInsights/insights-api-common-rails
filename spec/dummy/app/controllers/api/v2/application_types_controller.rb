module Api
  module V2
    class ApplicationTypesController < ApplicationController
      include Api::V2::Mixins::IndexMixin
    end
  end
end
