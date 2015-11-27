solo:       bundle exec bin/hub solo       --count $DYNO_COUNT
dispatcher: bundle exec bin/hub dispatcher --count $DYNO_COUNT
worker:     bundle exec bin/hub worker     --count $DYNO_COUNT --number $DYNO

drain:      bundle exec bin/hub drain
sidekiq:    bundle exec bin/sidekiq ${SIDEKIQ_CONCURRENCY:-5} hub

console:    bundle exec bin/console
