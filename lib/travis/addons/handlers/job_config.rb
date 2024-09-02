require 'travis/addons/handlers/base'

module Travis
  module Addons
    module Handlers
      class JobConfig < Base
        EVENTS = ['job:started'].freeze
        KEY = :job_config

        def handle?
          true
        end

        def handle
          job = Job.find(object.id)
          return unless job and instance_size

          job.update(vm_size: instance_size)
        end

        private

        def instance_size
          @instance_size ||= meta(:vm_size)
        end

        def meta(value)
          params[:worker_meta][0][value] if params.has_key?(:worker_meta) && params[:worker_meta].is_a?(Array) && params[:worker_meta].first.respond_to?(:keys)
        end

      end
    end
  end
end
