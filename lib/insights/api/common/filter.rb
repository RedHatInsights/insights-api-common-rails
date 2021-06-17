module Insights
  module API
    module Common
      class Filter
        INTEGER_COMPARISON_KEYWORDS = ["eq", "not_eq", "gt", "gte", "lt", "lte", "nil", "not_nil"].freeze
        STRING_COMPARISON_KEYWORDS  = ["contains", "contains_i", "eq", "not_eq", "eq_i", "not_eq_i", "starts_with", "starts_with_i", "ends_with", "ends_with_i", "nil", "not_nil"].freeze
        ALL_COMPARISON_KEYWORDS     = (INTEGER_COMPARISON_KEYWORDS + STRING_COMPARISON_KEYWORDS).uniq.freeze

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
          @raw_filter                  = raw_filter
          @api_doc_definition          = api_doc_definition
          @arel_table                  = model.arel_table
          @extra_filterable_attributes = extra_filterable_attributes
          @model                       = model
        end

        def query
          @query ||= filter_associations.present? ? model.left_outer_joins(filter_associations) : model
        end
        attr_writer :query

        def apply
          return query if @raw_filter.blank?

          self.class.compact_filter(@raw_filter).each do |k, v|
            next unless (attribute = attribute_for_key(k))

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

        # Compact filters to support association filtering
        #
        #   Input:  {"source_type"=>{"name"=>{"eq"=>"rhev"}}}
        #   Output: {"source_type.name"=>{"eq"=>"rhev"}}
        #
        #   Input:  {"source_type"=>{"name"=>{"eq"=>["openstack", "openshift"]}}}
        #   Output: {"source_type.name"=>{"eq"=>["openstack", "openshift"]}}
        #
        def self.compact_filter(filter)
          result = {}
          return result if filter.blank?
          return filter unless filter.kind_of?(Hash) || filter.kind_of?(ActionController::Parameters)

          filter = Hash(filter.permit!) if filter.kind_of?(ActionController::Parameters)

          filter.each do |ak, av|
            if av.kind_of?(Hash)
              av.each do |atk, atv|
                if !ALL_COMPARISON_KEYWORDS.include?(atk)
                  result["#{ak}.#{atk}"] = atv
                else
                  result[ak] = av
                end
              end
            else
              result[ak] = av
            end
          end
          result
        end

        def self.association_attribute_properties(api_doc_definitions, raw_filter)
          return {} if raw_filter.blank?

          association_attributes = compact_filter(raw_filter).keys.select { |key| key.include?('.') }.compact.uniq
          return {} if association_attributes.blank?

          association_attributes.each_with_object({}) do |key, hash|
            association, attr = key.split('.')
            hash[key] = api_doc_definitions[association.singularize.classify].properties[attr.to_s]
          end
        end

        private

        delegate(:arel_attribute, :to => :model)

        class Error < ArgumentError; end

        def key_model_attribute(key)
          if key.include?('.')
            association, attr = key.split('.')
            [association.classify.constantize, attr]
          else
            [model, key]
          end
        end

        def model_arel_attribute(key)
          key_model, attr = key_model_attribute(key)
          key_model.arel_attribute(attr)
        end

        def model_arel_table(key)
          key_model, attr = key_model_attribute(key)
          key_model.arel_table
        end

        def filter_associations
          return nil if @raw_filter.blank?

          @filter_associations ||= begin
            self.class.compact_filter(@raw_filter).keys.collect do |key|
              next unless key.include?('.')

              key.split('.').first.to_sym
            end.compact.uniq
          end
        end

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
          if val.kind_of?(Hash)
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

        def self.build_filtered_scope(scope, api_version, klass_name, filter)
          return scope unless filter

          openapi_doc = ::Insights::API::Common::OpenApi::Docs.instance[api_version]
          openapi_schema_name, = ::Insights::API::Common::GraphQL::Generator.openapi_schema(openapi_doc, klass_name)

          action_parameters = ActionController::Parameters.new(filter)
          definitions = openapi_doc.definitions

          association_attribute_properties = association_attribute_properties(definitions, action_parameters)

          new(scope, action_parameters, definitions[openapi_schema_name], association_attribute_properties).apply
        end

        def timestamp(k, val)
          if val.kind_of?(Hash)
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
          if val.kind_of?(Hash)
            val.each do |comparator, value|
              add_filter(comparator, INTEGER_COMPARISON_KEYWORDS, k, value)
            end
          else
            add_filter("eq", INTEGER_COMPARISON_KEYWORDS, k, val)
          end
        end

        def arel_lower(key)
          Arel::Nodes::NamedFunction.new("LOWER", [model_arel_attribute(key)])
        end

        def comparator_contains(key, value)
          return value.each { |v| comparator_contains(key, v) } if value.kind_of?(Array)

          self.query = query.where(model_arel_attribute(key).matches("%#{query.sanitize_sql_like(value)}%", nil, true))
        end

        def comparator_contains_i(key, value)
          return value.each { |v| comparator_contains_i(key, v) } if value.kind_of?(Array)

          self.query = query.where(model_arel_table(key).grouping(arel_lower(key).matches("%#{query.sanitize_sql_like(value.downcase)}%", nil, true)))
        end

        def comparator_starts_with(key, value)
          self.query = query.where(model_arel_attribute(key).matches("#{query.sanitize_sql_like(value)}%", nil, true))
        end

        def comparator_starts_with_i(key, value)
          self.query = query.where(model_arel_table(key).grouping(arel_lower(key).matches("#{query.sanitize_sql_like(value.downcase)}%", nil, true)))
        end

        def comparator_ends_with(key, value)
          self.query = query.where(model_arel_attribute(key).matches("%#{query.sanitize_sql_like(value)}", nil, true))
        end

        def comparator_ends_with_i(key, value)
          self.query = query.where(model_arel_table(key).grouping(arel_lower(key).matches("%#{query.sanitize_sql_like(value.downcase)}", nil, true)))
        end

        def comparator_eq(key, value)
          self.query = query.where(model_arel_attribute(key).eq_any(Array(value)))
        end

        def comparator_not_eq(key, value)
          self.query = query.where.not(model_arel_attribute(key).eq_any(Array(value)))
        end

        def comparator_not_eq_i(key, value)
          values = Array(value).map { |v| query.sanitize_sql_like(v.downcase) }

          self.query = query.where.not(model_arel_table(key).grouping(arel_lower(key).matches_any(values)))
        end

        def comparator_eq_i(key, value)
          values = Array(value).map { |v| query.sanitize_sql_like(v.downcase) }

          self.query = query.where(model_arel_table(key).grouping(arel_lower(key).matches_any(values)))
        end

        def comparator_gt(key, value)
          self.query = query.where(model_arel_attribute(key).gt(value))
        end

        def comparator_gte(key, value)
          self.query = query.where(model_arel_attribute(key).gteq(value))
        end

        def comparator_lt(key, value)
          self.query = query.where(model_arel_attribute(key).lt(value))
        end

        def comparator_lte(key, value)
          self.query = query.where(model_arel_attribute(key).lteq(value))
        end

        def comparator_nil(key, _value = nil)
          self.query = query.where(model_arel_attribute(key).eq(nil))
        end

        def comparator_not_nil(key, _value = nil)
          self.query = query.where.not(model_arel_attribute(key).eq(nil))
        end
      end
    end
  end
end
