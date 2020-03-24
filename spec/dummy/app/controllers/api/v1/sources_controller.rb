module Api
  module V1
    class SourcesController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def extra_attributes_for_filtering
        {"undocumented" => {"type" => "string"}}
      end
    end
  end
end
