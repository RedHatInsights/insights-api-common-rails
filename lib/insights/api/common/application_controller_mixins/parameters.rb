module Insights
  module API
    module Common
      module ApplicationControllerMixins
        module Parameters
          def self.included(other)
            other.include(OpenapiEnabled)
          end

          def params_for_create
            check_if_openapi_enabled
            # We already validate this with OpenAPI validator, that validates every request, so we shouldn't do it again here.
            body_params.permit!
          end

          def safe_params_for_list
            check_if_openapi_enabled
            # :limit & :offset can be passed in for pagination purposes, but shouldn't show up as params for filtering purposes
            @safe_params_for_list ||= begin
              sort_by_default = (params[:sort_by].kind_of?(String) || params[:sort_by].kind_of?(Array)) ? [] : {}
              params.merge(params_for_polymorphic_subcollection).permit(*permitted_params, :filter => {}, :sort_by => sort_by_default)
            end
          end

          def permitted_params
            check_if_openapi_enabled
            api_doc_definition.all_attributes + [:limit, :offset, :sort_by] + [subcollection_foreign_key]
          end

          def subcollection_foreign_key
            "#{request_path_parts["primary_collection_name"].singularize}_id"
          end

          def params_for_polymorphic_subcollection
            return {} unless subcollection?
            return {} unless reflection = primary_collection_model&.reflect_on_association(request_path_parts["subcollection_name"])
            return {} unless as = reflection.options[:as]

            {"#{as}_type" => primary_collection_model.name, "#{as}_id" => request_path_parts["primary_collection_id"]}
          end

          def primary_collection_model
            @primary_collection_model ||= request_path_parts["primary_collection_name"].singularize.classify.safe_constantize
          end

          def params_for_list
            check_if_openapi_enabled
            safe_params = safe_params_for_list.slice(*all_attributes_for_index)
            if safe_params[subcollection_foreign_key_using_through_relation]
              # If this is a through relation, we need to replace the :foreign_key by the foreign key with right table
              # information. So e.g. :container_images with :tags subcollection will have {:container_image_id => ID} and we need
              # to replace it with {:container_images_tags => {:container_image_id => ID}}, where :container_images_tags is the
              # name of the mapping table.
              safe_params[through_relation_klass.table_name.to_sym] = {
                subcollection_foreign_key_using_through_relation => safe_params.delete(subcollection_foreign_key_using_through_relation)
              }
            end

            safe_params
          end

          def through_relation_klass
            check_if_openapi_enabled
            return unless subcollection?
            return unless reflection = primary_collection_model&.reflect_on_association(request_path_parts["subcollection_name"])
            return unless through = reflection.options[:through]

            primary_collection_model&.reflect_on_association(through).klass
          end

          def through_relation_name
            check_if_openapi_enabled
            # Through relation name taken from the subcollection model side, so we can use this for table join.
            return unless through_relation_klass
            return unless through_relation_association = model.reflect_on_all_associations.detect { |x| !x.polymorphic? && x.klass == through_relation_klass }

            through_relation_association.name
          end

          def subcollection_foreign_key_using_through_relation
            return unless through_relation_klass

            subcollection_foreign_key
          end

          def all_attributes_for_index
            check_if_openapi_enabled
            api_doc_definition.all_attributes + [subcollection_foreign_key_using_through_relation]
          end

          def filtered
            check_if_openapi_enabled
            association_attribute_properties =
              Insights::API::Common::Filter.association_attribute_properties(api_doc_definitions, safe_params_for_list[:filter])
            extra_attribute_properties = extra_attributes_for_filtering.merge(association_attribute_properties)

            Insights::API::Common::Filter.new(model, safe_params_for_list[:filter], api_doc_definition, extra_attribute_properties).apply
          end

          def extra_attributes_for_filtering
            {}
          end

          def pagination_limit
            safe_params_for_list[:limit]
          end

          def pagination_offset
            safe_params_for_list[:offset]
          end

          def query_sort_by
            safe_params_for_list[:sort_by]
          end

          def params_for_update
            check_if_openapi_enabled
            # We already validate this with OpenAPI validator, here only to satisfy the strong parameters check
            attr_list = *api_doc_definition.all_attributes - api_doc_definition.read_only_attributes
            strong_params_hash = sanctified_permit_param(api_doc_definition, attr_list)
            body_params.permit(strong_params_hash)
          end

          def sanctified_permit_param(api_doc_definition, attributes)
            api_doc_definition['properties'].each_with_object([]) do |(k, v), memo|
              next unless attributes.each { |attr| attr.include?(k) }

              memo << if v['type'] == 'array'
                        { k => [] }
                      elsif v['type'] == 'object'
                        { k => {} }
                      else
                        k
                      end
            end
          end

          def check_if_openapi_enabled
            raise ArgumentError, "Openapi not enabled" unless self.class.openapi_enabled
          end
        end
      end
    end
  end
end
