module OpenApi
  module Serializer
    def as_json(arg = {})
      previous = super
      encrypted_columns_set = (self.class.try(:encrypted_columns) || []).to_set
      encryption_filtered = previous.except(*encrypted_columns_set)
      return encryption_filtered unless arg.key?(:prefixes)
      /\/v(?<major>\d+)[x\.]?(?<minor>\d+)?\// =~ arg[:prefixes].first
      version = [major, minor].compact.join(".")
      schema  = Api::Docs[version].definitions[self.class.name]
      attrs   = encryption_filtered.slice(*schema["properties"].keys)

      schema["properties"].keys.each do |name|
        attrs[name] = attrs[name].iso8601 if attrs[name].kind_of?(Time)
        attrs[name] = attrs[name].to_s if name.ends_with?("_id") || name == "id"
        attrs[name] = self.public_send(name) if !attrs.key?(name) && !encrypted_columns_set.include?(name)
      end
      attrs.compact
    end
  end
end
