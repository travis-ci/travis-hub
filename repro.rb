#!/usr/bin/env ruby

$stdout.sync = true

$LOAD_PATH << 'lib'

require 'travis/hub'

class Foo
  extend Travis::Instrumentation

  def run
    sleep 0.1
  end
  instrument :run
end

foo = Foo.new
foo.run
