module Api
  module V2
    class SourcesController < ApplicationController
      include Api::V2::Mixins::IndexMixin
    end
  end
end
