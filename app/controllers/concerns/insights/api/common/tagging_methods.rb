module Insights
  module API
    module Common
      module TaggingMethods
        def tag
          primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])

          applied_tags = parsed_body.collect do |i|
            begin
              tag = Tag.find_or_create_by!(Tag.parse(i["tag"]))
              primary_instance.tags << tag
              i
            rescue ActiveRecord::RecordNotUnique
            end
          end.compact

          # HTTP Not Modified
          return head(304, :location => "#{instance_link(primary_instance)}/tags") if applied_tags.empty?

          # HTTP Created
          render :json => parsed_body, :status => 201, :location => "#{instance_link(primary_instance)}/tags"
        end

        def untag
          primary_instance = primary_collection_model.find(request_path_parts["primary_collection_id"])

          parsed_body.each do |i|
            tag = Tag.find_by(Tag.parse(i["tag"]))
            primary_instance.tags.destroy(tag) if tag
          end

          # HTTP No Content
          head 204, :location => "#{instance_link(primary_instance)}/tags"
        end
      end
    end
  end
end
