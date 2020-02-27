module Insights
  module API
    module Common
      class PaginatedResponseV2 <	PaginatedResponse
        attr_reader :limit, :offset, :sort_by

        private

        def sort_by_options(model)
          @sort_by_options ||= begin
            sort_options = []
            return sort_options if sort_by.blank?

            sort_by.each do |sort_attr, sort_order|
              sort_order = "asc" if sort_order.blank?
              arel = model.arel_attribute(sort_attr)
              arel = arel.asc  if sort_order == "asc"
              arel = arel.desc if sort_order == "desc"
              sort_options << arel
            end
            sort_options
          end
        end

        def validate_sort_by
          return if sort_by.blank?

          raise ArgumentError, "Invalid sort_by parameter specified \"#{sort_by}\"" unless sort_by.kind_of?(ActionController::Parameters) || sort_by.kind_of?(Hash)

          sort_by.each { |sort_attr, sort_order| validate_sort_by_directive(sort_attr, sort_order) }
        end

        def validate_sort_by_directive(sort_attr, sort_order)
          key = "#{sort_attr}:#{sort_order.blank? ? 'asc' : sort_order}"
          raise ArgumentError, "Invalid sort_by directive specified \"#{sort_attr}=#{sort_order}\"" unless key.match?(/^[a-z\\-_]+(:asc|:desc)?$/)
        end
      end
    end
  end
end
