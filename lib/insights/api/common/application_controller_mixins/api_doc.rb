module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module ApiDoc
          def self.included(other)
            other.extend(self::ClassMethods)
          end

          private

          def api_doc
            self.class.send(:api_doc)
          end

          def api_doc_definition
            self.class.send(:api_doc_definition)
          end

          module ClassMethods
            private

            def api_doc
              @api_doc ||= ::Insights::API::Common::OpenApi::Docs.instance[api_version[1..-1].sub(/x/, ".")]
            end

            def api_doc_definition
              @api_doc_definition ||= api_doc.definitions[name.split("::").last[0..-11].singularize]
            end

            def api_version
              @api_version ||= name.split("::")[1].downcase
            end
          end
        end
      end
    end
  end
end
