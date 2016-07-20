module Travis
  module Hub
    class UpdateCurrentBuild < Struct.new(:build)
      MSGS = {
        update: 'Setting current_build_id to %s on repo %s',
      }

      def update!
        logger.info MSGS[:update] % [build.id, repository.id]
        if is_current?
          repository.update_attributes!(current_build_id: build.id)
        end
      end

      private

        def is_current?
          states = ['started', 'passed', 'failed', 'errored', 'canceled']

          # the build is not current if there're any newer builds that
          # are being run or finshed already
          !repository.builds.where(["id > ?", build.id]).
                      where(state: states).exists?
        end

        def repository
          build.repository
        end

        def logger
          Travis::Hub.context.logger
        end
    end
  end
end

