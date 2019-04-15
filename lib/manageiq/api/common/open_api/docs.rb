require "manageiq/api/common/open_api/docs/component_collection"
require "manageiq/api/common/open_api/docs/object_definition"
require "manageiq/api/common/open_api/docs/doc_v3"

module ManageIQ
  module API
    module Common
      module OpenApi
        class Docs
          def initialize(glob)
            @cache = {}
            glob.each { |f| load_file(f) }
          end

          def load_file(file)
            openapi_spec = JSON.parse(File.read(file))
            store_doc(DocV3.new(openapi_spec))
          end

          def store_doc(doc)
            update_doc_for_version(doc, doc.version.segments[0..1].join("."))
            update_doc_for_version(doc, doc.version.segments.first.to_s)
          end

          def update_doc_for_version(doc, version)
            if @cache[version].nil?
              @cache[version] = doc
            else
              existing_version = @cache[version].version
              @cache[version] = doc if doc.version > existing_version
            end
          end

          def [](version)
            @cache[version]
          end

          def routes
            @routes ||= begin
              @cache.each_with_object([]) do |(version, doc), routes|
                next unless /\d+\.\d+/ =~ version # Skip unless major.minor
                routes.concat(doc.routes)
              end
            end
          end
        end
      end
    end
  end
end
