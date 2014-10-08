#!/bin/bash
RAILS_ENV=test bundle exec rake ${RAKE_TASK:-spec}
export tresult=$?
find . -name hs_err_pid*.log -exec cat {} \;
exit $tresult
