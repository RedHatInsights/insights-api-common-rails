module Insights
  module API
    module Common
      class Filter
        INTEGER_COMPARISON_KEYWORDS = ["eq", "gt", "gte", "lt", "lte", "nil", "not_nil"].freeze
        STRING_COMPARISON_KEYWORDS  = ["contains", "contains_i", "eq", "eq_i", "starts_with", "starts_with_i", "ends_with", "ends_with_i", "nil", "not_nil"].freeze

        attr_reader :apply, :arel_table, :api_doc_definition, :extra_filterable_attributes, :model

        # Instantiates a new Filter object
        #
        # == Parameters:
        # model::
        #   An AR model that acts as the base collection to be filtered
        # raw_filter::
        #   The filter from the request query string
        # api_doc_definition::
        #   The documented object definition from the OpenAPI doc
        # extra_filterable_attributes::
        #   Attributes that can be used for filtering but are not documented in the OpenAPI doc.  Something like `{"undocumented_column" => {"type" => "string"}}`
        #
        # == Returns:
        # A new Filter object, call #apply to get the filtered set of results.
        #
        def initialize(model, raw_filter, api_doc_definition, extra_filterable_attributes = {})
          self.query                   = model
          @api_doc_definition          = api_doc_definition
          @arel_table                  = model.arel_table
          @extra_filterable_attributes = extra_filterable_attributes
          @model                       = model
          @raw_filter                  = raw_filter
        end

        def apply
          return query if @raw_filter.blank?
          @raw_filter.each do |k, v|
            next unless attribute = attribute_for_key(k)

            if attribute["type"] == "string"
              type = determine_string_attribute_type(attribute)
              send(type, k, v)
            else
              errors << "unsupported attribute type for: #{k}"
            end
          end

          raise(Insights::API::Common::Filter::Error, errors.join(", ")) unless errors.blank?
          query
        end

        private

        attr_accessor :query
        delegate(:arel_attribute, :to => :model)

        class Error < ArgumentError; end

        def attribute_for_key(key)
          attribute = api_doc_definition.properties[key.to_s]
          attribute ||= extra_filterable_attributes[key.to_s]
          return attribute if attribute
          errors << "found unpermitted parameter: #{key}"
          nil
        end

        def determine_string_attribute_type(attribute)
          return :timestamp if attribute["format"] == "date-time"
          return :integer if attribute["pattern"] == /^\d+$/
          :string
        end

        def errors
          @errors ||= []
        end

        def string(k, val)
          if val.kind_of?(ActionController::Parameters)
            val.each do |comparator, value|
              add_filter(comparator, STRING_COMPARISON_KEYWORDS, k, value)
            end
          else
            add_filter("eq", STRING_COMPARISON_KEYWORDS, k, val)
          end
        end

        def add_filter(requested_comparator, allowed_comparators, key, value)
          return unless attribute = attribute_for_key(key)
          type = determine_string_attribute_type(attribute)

          if requested_comparator.in?(["nil", "not_nil"])
            send("comparator_#{requested_comparator}", key, value)
          elsif requested_comparator.in?(allowed_comparators)
            value = parse_datetime(value) if type == :datetime
            return if value.nil?
            send("comparator_#{requested_comparator}", key, value)
          else
            errors << "unsupported #{type} comparator: #{requested_comparator}"
          end
        end

        def timestamp(k, val)
          if val.kind_of?(ActionController::Parameters)
            val.each do |comparator, value|
              add_filter(comparator, INTEGER_COMPARISON_KEYWORDS, k, value)
            end
          else
            add_filter("eq", INTEGER_COMPARISON_KEYWORDS, k, val)
          end
        end

        def parse_datetime(value)
          return value.collect { |i| parse_datetime(i, ) } if value.kind_of?(Array)

          DateTime.parse(value)
        rescue ArgumentError
          errors << "invalid timestamp: #{value}"
          return nil
        end

        def integer(k, val)
          if val.kind_of?(ActionController::Parameters)
            val.each do |comparator, value|
              add_filter(comparator, INTEGER_COMPARISON_KEYWORDS, k, value)
            end
          else
            add_filter("eq", INTEGER_COMPARISON_KEYWORDS, k, val)
          end
        end

        def arel_lower(key)
          Arel::Nodes::NamedFunction.new("LOWER", [arel_attribute(key)])
        end

        def comparator_contains(key, value)
          return value.each { |v| comparator_contains(key, v) } if value.kind_of?(Array)

          self.query = query.where(arel_attribute(key).matches("%#{query.sanitize_sql_like(value)}%", nil, true))
        end

        def comparator_contains_i(key, value)
          return value.each { |v| comparator_contains_i(key, v) } if value.kind_of?(Array)

          self.query = query.where(arel_table.grouping(arel_lower(key).matches("%#{query.sanitize_sql_like(value.downcase)}%", nil, true)))
        end

        def comparator_starts_with(key, value)
          self.query = query.where(arel_attribute(key).matches("#{query.sanitize_sql_like(value)}%", nil, true))
        end

        def comparator_starts_with_i(key, value)
          self.query = query.where(arel_table.grouping(arel_lower(key).matches("#{query.sanitize_sql_like(value.downcase)}%", nil, true)))
        end

        def comparator_ends_with(key, value)
          self.query = query.where(arel_attribute(key).matches("%#{query.sanitize_sql_like(value)}", nil, true))
        end

        def comparator_ends_with_i(key, value)
          self.query = query.where(arel_table.grouping(arel_lower(key).matches("%#{query.sanitize_sql_like(value.downcase)}", nil, true)))
        end

        def comparator_eq(key, value)
          self.query = query.where(arel_attribute(key).eq_any(Array(value)))
        end

        def comparator_eq_i(key, value)
          values = Array(value).map { |v| query.sanitize_sql_like(v.downcase) }

          self.query = query.where(arel_table.grouping(arel_lower(key).matches_any(values)))
        end

        def comparator_gt(key, value)
          self.query = query.where(arel_attribute(key).gt(value))
        end

        def comparator_gte(key, value)
          self.query = query.where(arel_attribute(key).gteq(value))
        end

        def comparator_lt(key, value)
          self.query = query.where(arel_attribute(key).lt(value))
        end

        def comparator_lte(key, value)
          self.query = query.where(arel_attribute(key).lteq(value))
        end

        def comparator_nil(key, _value = nil)
          self.query = query.where(arel_attribute(key).eq(nil))
        end

        def comparator_not_nil(key, _value = nil)
          self.query = query.where.not(arel_attribute(key).eq(nil))
        end
      end
    end
  end
end
