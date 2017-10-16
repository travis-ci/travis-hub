#!/bin/bash

# Give other services a few seconds to come up
# FIXME: a retry strategy would be better
sleep 3
bundle exec je bin/sidekiq-pgbouncer 5 hub
