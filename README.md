# Travis Hub [![Build Status](https://travis-ci.org/travis-ci/travis-hub.svg?branch=master)](https://travis-ci.org/travis-ci/travis-hub)

*Keeper of the statuses*

Travis Hub is the application that, in the life-cycle of accepting,
evaluating, and executing a build request, sits in the fifth position,
next to [Travis Logs](http://github.com/travis-ci/travis-logs).

In short Hub deals with updates to the job and build status coming in from
the workers, while Logs deals with collecting build log output from them.

Once a build request has been:

* accepted by [Listener](https://github.com/travis-ci/travis-listener),
* approved and configured by [Gatekeeper](https://github.com/travis-ci/travis-gatekeeper),
* and its jobs have been scheduled by [Scheduler](https://github.com/travis-ci/travis-scheduler),

they will be picked by a [Worker](https://github.com/travis-ci/worker)
which will execute the build Bash script as generated by the
[build script compiler](http://github.com/travis-ci/travis-build)).

The worker goes through a series of stages while acquiring and preparing a VM,
and running the build script. Each time the state of the job changes the worker
will send a message that will be processed by Hub. These messages are:

* `job:receive` signals that the worker has picked up a job and is going
  to boot a VM for it. (This state is displayed as "booting" in the UI.)
* `job:start` signals that the worker has started executing the build script.
* `job:finish` signals that the worker has finished executing the build script.
* `job:restart` occurs when the worker has troubles booting a VM, or looses
  connection to it while running the build script. (In this case the job's
  state will be reset to `:created` so that Scheduler will queue it again,
  and Worker will try again.

Processing these messages Hub will change the job's `state` in the database,
set attributes such as `received_at`, potentially change the respective build's
state as well. It will then emit events such as `job:started` or
`build:finished` which will send out notifications to other parties (such as
the web UI via Pusher, GitHub commit status updates, email, IRC, webhook
notifications etc).

## History

Travis Hub was the first service that we extracted from our Rails application
apart from Travis Listener. It was huge, and did all the things that now
are being split up into 6 applications (Gatekeeper, Scheduler, Hub, Logs,
Sync, Tasks). Nowadays it is one of the smallest service that deals with
our core models directly.

## Contributing

See the CONTRIBUTING.md file for information on how to contribute to travis-hub.
Note that we're using a [central issue tracker]
(https://github.com/travis-ci/travis-ci/issues) for all the Travis projects.

## License & copyright

See [MIT-LICENSE](MIT-LICENSE.md).

test
