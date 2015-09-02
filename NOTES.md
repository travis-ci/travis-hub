# WHAT HUB DOES

* Accept job state updates
* Enqueue tasks
* Enqueue live messages
* Update the states cache

# REFACTOR

* Dispatch events to subscribed apps, remove addons
* Allow passing attributes to simple_state event methods

# EXTRACT OR MOVE TO SUPPORT

* SecureConfig (travis-yaml?)
* ~~Event~~ (travis-event)
* ~~EncryptedColumn~~ (travis-encrypt)
* ~~Notification~~ (travis-support)
* ~~StatesCache~~ (travis-support)
* ~~Features~~ (not used for now)
* ~~RedisPool~~ (not used)

# CAN WE REMOVE THESE FROM HUB?

* Branch: does every event need to update the branch? are branches being sync'ed now?
  See /lib/travis/hub/model/build/denormalize.rb#24
* Repository: does the UI still use denormalized last\_build\* attributes?
* data[:state] in Service::UpdateJob: does the worker send the state key?
* Log (ported, but it would be nice to remove this dependency)
* Annotations (not ported at all)

# CLEANUP

* rename github_commit_status to github_status in pro-keychain

# UNIFY

* [Campfire|Flowdock], Hipchat, and Slack all behave different wrt pull requests

# QUESTIONS

* How come states_cache is disabled on com? If that's intentional we need turn
  it off via config, since Features is not available atm
* :reset is processed in hub (coming in from the worker, for requeues?) and in
  api. can this be unified?
* Rename :reset to :restart?
* What's required to start using travis-yaml? Would gatekeeper need to use it first?

# DETAILS NEEDED BY ADDONS

* Broadcasts by Repository
* Known email addresses: commit.author_email, commit.committer_email
* Github OAuth Tokens for setting commit status. Ordered: committer, admins, users with push access
* build.previous_state (state of the previous build on the same branch)

