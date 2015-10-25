solo:       bin/hub solo       --count $DYNO_COUNT
dispatcher: bin/hub dispatcher --count $DYNO_COUNT
worker:     bin/hub worker     --count $DYNO_COUNT --number $DYNO

drain:      bin/hub drain
sidekiq:    bundle exec bin/sidekiq ${SIDEKIQ_CONCURRENCY:-5} hub

console:    bundle exec bin/console
