# GITHUB_PAYLOADS = {
#   'gem-release' => %({
#     "repository": {
#       "url": "http://github.com/svenfuchs/gem-release",
#       "name": "gem-release",
#       "description": "Release your gems with ease",
#       "owner": {
#         "email": "svenfuchs@artweb-design.de",
#         "name": "svenfuchs"
#       }
#     },
#     "commits": [{
#       "id":        "9854592",
#       "message":   "Bump to 0.0.15",
#       "timestamp": "2010-10-27 04:32:37",
#       "committer": {
#         "name":  "Sven Fuchs",
#         "email": "svenfuchs@artweb-design.de"
#       },
#       "author": {
#         "name":  "Christopher Floess",
#         "email": "chris@flooose.de"
#       }
#     }],
#     "ref": "refs/heads/master",
#     "compare": "https://github.com/svenfuchs/gem-release/compare/af674bd...9854592"
#   })
# }

WORKER_PAYLOADS = {
  'job:test:receive' => { 'id' => 1, 'state' => 'received',  'received_at'  => '2011-01-01 00:02:00 +0200', 'worker' => 'ruby3.worker.travis-ci.org:travis-ruby-4' },
  'job:test:start'   => { 'id' => 1, 'state' => 'started',  'started_at'  => '2011-01-01 00:02:00 +0200', 'worker' => 'ruby3.worker.travis-ci.org:travis-ruby-4' },
  'job:test:log'     => { 'id' => 1, 'log' => '... appended' },
  'job:test:log:1'   => { 'id' => 1, 'log' => 'the '  },
  'job:test:log:2'   => { 'id' => 1, 'log' => 'full ' },
  'job:test:log:3'   => { 'id' => 1, 'log' => 'log'   },
  'job:test:finish'  => { 'id' => 1, 'state' => 'passed', 'finished_at' => '2011-01-01 00:03:00 +0200', 'log' => 'the full log' },
  'job:test:reset'   => { 'id' => 1 }
}

