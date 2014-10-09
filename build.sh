#!/bin/bash
RAILS_ENV=test bundle exec rake ${1:-spec}
export tresult=$?
find . -name hs_err_pid*.log -exec cat {} \;
exit $tresult
