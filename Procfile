solo:       bundle exec je bin/hub solo       --count $DYNO_COUNT
dispatcher: bundle exec je bin/hub dispatcher --count $DYNO_COUNT
worker:     bundle exec je bin/hub worker     --count $DYNO_COUNT --number $DYNO

drain:      bundle exec je bin/hub drain
sidekiq:    bundle exec je bin/sidekiq ${SIDEKIQ_CONCURRENCY:-5} ${SIDEKIQ_QUEUE:-hub}

console:    bundle exec je bin/console

cleanup:    bundle exec je bin/cleanup
