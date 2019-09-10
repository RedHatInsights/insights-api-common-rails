module ManageIQ
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

            def api_doc_for_version(version)
              api_version(version)
              api_doc
            end

            def api_doc
              @api_doc ||= ::ManageIQ::API::Common::OpenApi::Docs.instance[api_version[1..-1].sub(/x/, ".")]
            end

            def api_doc_definition
              @api_doc_definition ||= api_doc.definitions[model.name]
            end

            def api_version(version = nil)
              @api_version ||= (version || name.split("::")[1]).downcase
            end
          end
        end
      end
    end
  end
end
