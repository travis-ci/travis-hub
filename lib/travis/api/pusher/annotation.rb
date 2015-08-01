module Travis
  module Api
    module Pusher
      class Annotation
        require 'travis/api/pusher/annotation/created'
        require 'travis/api/pusher/annotation/updated'

        include Formats

        attr_reader :annotation

        def initialize(annotation, options = {})
          @annotation = annotation
        end

        def data
          {
            "annotation" => {
              "id" => annotation.id,
              "job_id" => annotation.job_id,
              "description" => annotation.description,
              "url" => annotation.url,
              "status" => annotation.status,
              "provider_name" => annotation.annotation_provider.name,
            }
          }
        end
      end
    end
  end
end
