module Insights
  module API
    module Common
      module OpenApi
        module Serializer
          include VersionFromPrefix

          def as_json(arg = {})
            previous = super(:except => excluded_attributes(arg))

            encrypted_columns_set = (self.class.try(:encrypted_columns) || []).to_set
            encryption_filtered = previous.except(*encrypted_columns_set)
            return encryption_filtered unless arg.key?(:prefixes)

            attrs = encryption_filtered.slice(*schema_properties(arg).keys)
            schema_properties(arg).keys.each do |name|
              next if attrs[name].nil?
              attrs[name] = attrs[name].iso8601 if attrs[name].kind_of?(Time)
              attrs[name] = attrs[name].to_s if name.ends_with?("_id") || name == "id"
            end
            attrs.compact
          end

          private

          def excluded_attributes(arg)
            return [] unless arg.key?(:prefixes)

            self.attributes.keys - schema_properties(arg).keys
          end

          def schema_properties(arg)
            @schema_properties ||= schema(arg)["properties"]
          end

          def schema(arg)
            version = api_version_from_prefix(arg[:prefixes].first)
            presentation_name = self.class.try(:presentation_name) || self.class.name
            ::Insights::API::Common::OpenApi::Docs.instance[version].definitions[presentation_name]
          end
        end
      end
    end
  end
end
