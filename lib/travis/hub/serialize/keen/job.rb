# This is what Gatekeeper sends:
#
#   {
#     requests: [
#       {
#         event_type: 'push',
#         matrix_size: 2,
#         repository_id: 123,
#         owner_id: 234,
#         owner_type: 'User',
#         owner: ['User', 234],
#         language: 'default',
#         language_version: {
#           ruby: ['2.1.2', '2.2.2']
#         github_language: nil,
#         uses_sudo: false,
#         uses_apt_get: false,
#         dist_name: 'default',
#         group_name: 'default'
#       }
#     ],
#     deployments: [
#       {
#         provider: 's3',
#         repository_id: 123
#       }
#     ],
#     notifications: []
#   }
require 'date'

module Travis
  module Hub
    module Serialize
      module Keen
        class Job < Struct.new(:job)
          def data
            {
              jobs: [
                {
                  id:                  job.id,
                  repository_id:       repo.id,
                  repository_slug:     repo.slug,
                  repository_private:  repo.private,
                  owner_type:          job.owner_type,
                  owner_id:            job.owner_id,
                  owner_login:         job.owner.login,
                  duration:            job.duration,
                  number:              job.number,
                  state:               job.state,
                  queue:               job.queue,
                  created_at:          job.created_at,
                  received_at:         job.received_at,
                  started_at:          job.started_at,
                  queued_at:           job.queued_at,
                  canceled_at:         job.canceled_at,
                  finished_at:         job.finished_at,
                  account_info:        account_info
                }
              ]
            }
          end

          private

          # TODO
          #
          # I assume the intention of this is being able to query how many
          # paid, educational, and trial builds we are running, right?
          #
          # We'd need to duplicate a lot of knowledge here in Hub just for
          # publishing this information. E.g. a job could be authorized by
          # delegating to another account in Scheduler. Trial builds are
          # evaluated in Gatekeeper.
          #
          # Is Keen.io able to correlate information from several events? E.g.
          # could we store trial information in Gatekeeper, job authorization
          # info in Scheduler, job state information in Hub, and then have
          # Keen.io correlate these bits into one?
          #
          # Or should this be stored in a column `account_info` on the builds
          # or job table?
            def account_info
              # subscription, education user, educational org, trial account
            end

            def repo
              job.repository
            end
        end
      end
    end
  end
end
