drain:      bundle exec je bin/hub drain
hub:        bundle exec je bin/sidekiq-pgbouncer ${SIDEKIQ_CONCURRENCY:-5} ${SIDEKIQ_QUEUE:-hub}
sidekiq:    bundle exec je bin/sidekiq-pgbouncer ${SIDEKIQ_CONCURRENCY:-5} ${SIDEKIQ_QUEUE:-hub}
web:        bundle exec je bin/server

console:    bundle exec je bin/console
cleanup:    bundle exec je bin/cleanup
