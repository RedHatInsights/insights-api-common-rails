module Api
  module V1
    class SourcesController < ApplicationController
      include Api::V1::Mixins::IndexMixin
    end
  end
end
