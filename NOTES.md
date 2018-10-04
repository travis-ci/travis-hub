# WHAT HUB DOES

* Accept job state updates
* Enqueue tasks
* Enqueue live messages
* Update the states cache
* Collect metrics about job queue and run times

# BUGS

* We have an event cancel, but workers send job:finish with state=cancel. Also notifications don't respond to cancel.
* ~~For a cancelled build, does restarting it send out notifications?~~

# IMPROVE

* Make sure we set up `application_name` in a consistent way on PG connections on all apps

# REFACTOR

* Dispatch events to subscribed apps, remove addons
* ~~Allow passing attributes to simple_state event methods (automatically set :started_at etc)~~

# EXTRACT OR MOVE TO SUPPORT

* SecureConfig (travis-yaml?)
* ~~Event~~ (travis-event)
* ~~EncryptedColumn~~ (travis-encrypt)
* ~~Notification~~ (travis-support)
* ~~StatesCache~~ (travis-support)
* Features
* ~~RedisPool~~ (not used)

# CAN WE REMOVE THESE FROM HUB?

* Repository: does the UI still use denormalized last\_build\* attributes?
* Log (ported, but it would be nice to remove this dependency)
* ~~Annotations (not ported at all)~~
* ~~Branch: does every event need to update the branch? are branches being sync'ed now?~~
  ~~See /lib/travis/hub/model/build/denormalize.rb#24~~
  ~~Removed all this for now. Branches were set to the last build created over and over~~
* ~~data[:state] in Service::UpdateJob: does the worker send the state key?~~

# CLEANUP

* rename github_commit_status to github_status in pro-keychain

# UNIFY

* [Campfire|Flowdock], Hipchat, and Slack all behave different wrt pull requests

# QUESTIONS

* How come states_cache is disabled on com? If that's intentional we need turn
  it off via config, since Features is not available atm
* :reset is processed in hub (coming in from the worker, for requeues?) and in
  api. can this be unified?
* What's required to start using travis-yaml? Would gatekeeper need to use it first?
* ~~Rename :reset to :restart?~~

# DETAILS NEEDED BY ADDONS

* Broadcasts by Repository
* Known email addresses: commit.author_email, commit.committer_email
* Github OAuth Tokens for setting commit status. Ordered: committer, admins, users with push access
* build.previous_state (state of the previous build on the same branch)

