module Insights
  module API
    module Common
      class PaginatedResponseV2 < PaginatedResponse

        # GraphQL name regex: /[_A-Za-z][_0-9A-Za-z]*/
        ASSOCIATION_COUNT_ATTR = "__count".freeze

        attr_reader :limit, :offset, :sort_by

        def records
          @records ||= begin
            res = @base_query.order(:id).limit(limit).offset(offset)

            select_for_associations, group_by_associations = sort_by_associations_query_parameters
            res = res.select(*select_for_associations)          if select_for_associations.present?
            res = res.left_outer_joins(*sort_by_associations)   if sort_by_associations.present?
            res = res.group(group_by_associations)              if group_by_associations.present?

            order_options = sort_by_options(res.klass)
            res = res.reorder(order_options) if order_options.present?
            res
          end
        end

        # Condenses parameter values for handling multi-level associations
        # and returns an array of key, value pairs.
        #
        # Input:  { "association" => { "attribute" => "value" }, "direct_attribute" = "value2" }
        # Output: { "association.attribute" => "value", "direct_attribute" => "value2" }
        #
        # Input:  { "association" => { "attribute" => "value" }, "association2" => "attribute2" = "value2" }
        # Output: { "association.attribute" => "value", "association2.attribute2" => "value2" }
        #
        def compact_parameter(param)
          result = []
          return result if param.blank?

          param.each do |k, v|
            result << if v.kind_of?(Hash) || v.kind_of?(ActionController::Parameters)
                        secondary_key   = v.keys.first
                        secondary_value = v[secondary_key]
                        ["#{k}.#{secondary_key}", secondary_value]
                      else
                        [k, v]
                      end
          end
          result
        end

        private

        def sort_by_options(model)
          @sort_by_options ||= begin
            compact_parameter(sort_by).collect do |sort_attr, sort_order|
              sort_order = "asc" if sort_order.blank?
              arel = if sort_attr.include?('.')
                       association, sort_attr = sort_attr.split('.')
                       association_class = association.classify.constantize
                       if sort_attr == ASSOCIATION_COUNT_ATTR
                         Arel.sql("COUNT (#{association_class.table_name}.id)")
                       else
                         association_class.arel_attribute(sort_attr)
                       end
                     else
                       model.arel_attribute(sort_attr)
                     end
              (sort_order == "desc") ? arel.desc : arel.asc
            end
          end
        end

        def sort_by_associations
          @sort_by_associations ||= begin
            compact_parameter(sort_by).collect do |sort_attr, sort_order|
              next unless sort_attr.include?('.')

              sort_attr.split('.').first.to_sym
            end.compact.uniq
          end
        end

        def sort_by_associations_query_parameters
          select_for_associations = []
          group_by_associations   = []
          count_selects           = []

          compact_parameter(sort_by).each do |sort_attr, _sort_order|
            next unless sort_attr.include?('.')

            association, attr = sort_attr.split('.')

            base_id  = "#{@base_query.table_name}.id"
            base_all = "#{@base_query.table_name}.*"
            select_for_associations << base_id << base_all if select_for_associations.empty?
            group_by_associations   << base_id << base_all if group_by_associations.empty?

            if attr == ASSOCIATION_COUNT_ATTR
              count_selects << Arel.sql("COUNT (#{association.classify.constantize.table_name}.id)")
            else
              arel_attr = association.classify.constantize.arel_attribute(attr)
              select_for_associations << arel_attr
              group_by_associations << arel_attr
            end
          end
          select_for_associations.append(*count_selects) unless count_selects.empty?

          [select_for_associations.compact.uniq, group_by_associations.compact.uniq]
        end

        def validate_sort_by
          return unless sort_by.present?
          raise ArgumentError, "Invalid sort_by parameter specified \"#{sort_by}\"" unless sort_by.kind_of?(ActionController::Parameters) || sort_by.kind_of?(Hash)

          compact_parameter(sort_by).each { |sort_attr, sort_order| validate_sort_by_directive(sort_attr, sort_order) }
        end

        def validate_sort_by_directive(sort_attr, sort_order)
          order = sort_order.blank? ? "asc" : sort_order
          raise ArgumentError, "Invalid sort_by directive specified \"#{sort_attr}=#{sort_order}\"" unless sort_attr.match?(/^[a-z\-_\.]+$/) && order.match?(/^(asc|desc)$/)
        end
      end
    end
  end
end
